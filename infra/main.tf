
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

# IAM Role for Amplify
resource "aws_iam_role" "amplify_service" {
  name = "amplifyServiceRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "amplify.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "amplify_service_policy" {
  role       = aws_iam_role.amplify_service.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess-Amplify"
}

# Frontend (Amplify)
resource "aws_amplify_app" "frontend" {
  name                 = "micro-url-frontend"
  repository           = var.repository_url
  platform             = "WEB"
  oauth_token          = var.github_token
  iam_service_role_arn = aws_iam_role.amplify_service.arn
  build_spec           = <<EOT
version: 1
applications:
  - frontend:
      phases:
        preBuild:
          commands:
            - cd packages/frontend
            - npm install
        build:
          commands:
            - npm run build
      artifacts:
        baseDirectory: packages/frontend/dist
        files:
          - '**/*'
      cache:
        paths:
          - node_modules/**/*
EOT
}

resource "aws_amplify_branch" "main" {
  app_id            = aws_amplify_app.frontend.id
  branch_name       = "main"
  enable_auto_build = true
}



# CloudFront Distribution (for Amplify + ALB Routing + SSL)
resource "aws_cloudfront_distribution" "this" {
  enabled             = true
  default_root_object = "index.html"

  aliases = [var.domain] # murl.pw

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  origin {
    domain_name = aws_amplify_app.frontend.default_domain
    origin_id   = "amplify-origin"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
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
    target_origin_id       = "amplify-origin"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["HEAD", "GET", "OPTIONS"]
    cached_methods  = ["HEAD", "GET"]
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  ordered_cache_behavior {
    path_pattern           = "/shorten*"
    target_origin_id       = "alb-origin"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["HEAD", "DELETE", "POST", "GET", "OPTIONS", "PUT", "PATCH"]
    cached_methods  = ["HEAD", "GET", ]
    forwarded_values {
      query_string = true
      cookies {
        forward = "all"
      }
    }
  }

  ordered_cache_behavior {
    path_pattern           = "/*"
    target_origin_id       = "alb-origin"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["HEAD", "GET"]
    cached_methods  = ["HEAD", "GET"]
    forwarded_values {
      query_string = true
      cookies {
        forward = "none"
      }
    }
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

