
terraform {
  required_version = ">= 1.12.2"

  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  backend "local" {}
}

provider "aws" {
  region = var.aws_region
}

provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}

# -------------------------------------------------------------------
# Global resources
# -------------------------------------------------------------------
locals {
  base_url = "https://${var.domain}"
  port     = 3000
}

data "aws_acm_certificate" "cf_cert" {
  provider    = aws.us-east-1
  domain      = var.domain
  statuses    = ["ISSUED"]
  most_recent = true
}

data "archive_file" "cf_router" {
  type        = "zip"
  source_file = "${path.module}/lambda/index.js"
  output_path = "${path.module}/lambda/cf-router.zip"
}

resource "aws_ecs_cluster" "this" {
  name = "micro-url-cluster"

  # for logs
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# IAM Role
resource "aws_iam_role" "ecs_execution" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_policy" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# -------------------------------------------------------------------
# Modules
# -------------------------------------------------------------------

# Networking (VPC, subnets, gateways)
module "network" {
  source     = "./modules/network"
  cidr_block = var.vpc_cidr
}
# Application Load Balancer (in Production we should use Multi-AZ replicas)
module "alb" {
  source         = "./modules/alb"
  vpc_id         = module.network.vpc_id
  public_subnets = module.network.public_subnets
}


# S3 Bucket for Frontend
resource "aws_s3_bucket" "frontend" {
  bucket = "${var.domain}-frontend"
}

resource "aws_s3_bucket_ownership_controls" "frontend" {
  bucket = aws_s3_bucket.frontend.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_cloudfront_origin_access_control" "frontend_oac" {
  name                              = "frontend-oac"
  description                       = "OAC for CloudFront to access S3 frontend bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_s3_bucket_policy" "frontend" {
  bucket = aws_s3_bucket.frontend.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "cloudfront.amazonaws.com"
        },
        Action   = "s3:GetObject",
        Resource = "${aws_s3_bucket.frontend.arn}/*",
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.this.arn
          }
        }
      }
    ]
  })
}


# CloudFront Distribution (for S3 + ALB Routing + SSL)
resource "aws_iam_role" "lambda_edge" {
  name = "lambda-edge-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
      },
      {
        "Effect" : "Allow",
        "Principal" : { "Service" : "edgelambda.amazonaws.com" },
        "Action" : "sts:AssumeRole"
    }]
  })
}
resource "aws_lambda_function" "cf_router" {
  function_name    = "cf-router"
  provider         = aws.us-east-1
  role             = aws_iam_role.lambda_edge.arn
  handler          = "index.handler"
  runtime          = "nodejs16.x"
  publish          = true
  filename         = data.archive_file.cf_router.output_path
  source_code_hash = data.archive_file.cf_router.output_base64sha256
}



resource "aws_iam_role_policy_attachment" "lambda_edge_basic" {
  role       = aws_iam_role.lambda_edge.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_cloudfront_distribution" "this" {
  enabled             = true
  default_root_object = "index.html"
  depends_on          = [aws_lambda_function.cf_router, aws_cloudfront_origin_access_control.frontend_oac]

  aliases = [var.domain] # murl.pw

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  origin {
    domain_name              = aws_s3_bucket.frontend.bucket_regional_domain_name
    origin_id                = "s3-frontend"
    origin_access_control_id = aws_cloudfront_origin_access_control.frontend_oac.id
  }

  origin {
    domain_name = module.alb.alb_dns_name
    origin_id   = "alb-origin"

    custom_origin_config {
      http_port              = 80
      https_port             = 80
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    target_origin_id       = "s3-frontend"
    viewer_protocol_policy = "redirect-to-https"

    lambda_function_association {
      event_type = "origin-request"
      lambda_arn = aws_lambda_function.cf_router.qualified_arn
    }

    forwarded_values {
      query_string = true
      cookies { forward = "all" }
    }

    allowed_methods = ["GET", "HEAD", "OPTIONS", "PUT", "PATCH", "POST", "DELETE"]
    cached_methods  = ["GET", "HEAD"]
  }


  price_class = "PriceClass_100"

  viewer_certificate {
    acm_certificate_arn      = data.aws_acm_certificate.cf_cert.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}

# ECR Repositories
module "ecr_shortening" {
  source    = "./modules/ecr"
  repo_name = "shortening"
}

module "ecr_forwarding" {
  source    = "./modules/ecr"
  repo_name = "forwarding"
}

# ECS Services (Shortening, Forwarding)
module "ecs_shortening_service" {
  source                 = "./modules/ecs-services"
  container_port         = local.port
  image                  = "${module.ecr_shortening.repository_url}:latest"
  region                 = var.aws_region
  ecs_cluster_id         = aws_ecs_cluster.this.id
  service_name           = "shortening"
  subnets                = module.network.private_subnets
  vpc_id                 = module.network.vpc_id
  security_group_ids     = [module.alb.security_group_id]
  ecs_execution_role_arn = aws_iam_role.ecs_execution.arn
  environment = {
    REDIS_URL = "redis://${module.redis.redis_endpoint}"
    BASE_URL  = local.base_url
    PORT      = tostring(local.port)
  }
}

module "ecs_forwarding_service" {
  source                 = "./modules/ecs-services"
  container_port         = local.port
  image                  = "${module.ecr_forwarding.repository_url}:latest"
  region                 = var.aws_region
  ecs_cluster_id         = aws_ecs_cluster.this.id
  service_name           = "forwarding"
  subnets                = module.network.private_subnets
  vpc_id                 = module.network.vpc_id
  security_group_ids     = [module.alb.security_group_id]
  ecs_execution_role_arn = aws_iam_role.ecs_execution.arn
  environment = {
    REDIS_URL = "redis://${module.redis.redis_endpoint}"
    BASE_URL  = local.base_url
    PORT      = tostring(local.port)
  }
}

# Redis (ElastiCache)
module "redis" {
  source          = "./modules/redis"
  private_subnets = module.network.private_subnets
  vpc_id          = module.network.vpc_id
  ecs_task_sg_ids = [module.ecs_forwarding_service.security_group_id, module.ecs_shortening_service.security_group_id]

  # optional overrides
  node_type       = "cache.t3.micro"
  num_cache_nodes = 1
}

# ALB Listener & Listener Rules

# Use the forward service as match-all route as default (will resolve /[slug] later)
resource "aws_lb_listener" "http" {
  load_balancer_arn = module.alb.load_balancer_arn
  port              = 80
  protocol          = "HTTP"

  # Default: Slugs (ie /abc123) -> Forwarding Service
  default_action {
    type             = "forward"
    target_group_arn = module.ecs_forwarding_service.target_group_arn
  }
}

# Rule: Shortening API unter murl.pw/shorten -> Shortening Service
resource "aws_lb_listener_rule" "shortening_root" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 30

  action {
    type             = "forward"
    target_group_arn = module.ecs_shortening_service.target_group_arn
  }

  condition {
    path_pattern {
      values = ["/shorten*"]
    }
  }
}




##! If you add more endpoints in the future e.g. /analytics etc. they should be here

