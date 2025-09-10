
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

# ECS cluster + execution role
module "ecs_cluster" {
  source                    = "./modules/ecs-cluster"
  cluster_name              = "micro-url-cluster"
  enable_container_insights = true
  execution_role_name       = "ecsTaskExecutionRole"
}

# CloudFront + S3 (OAC) + Lambda@Edge
module "cdn" {
  source = "./modules/cdn"

  providers = {
    aws           = aws.us-east-1
  }

  domain             = var.domain
  alb_domain_name    = module.alb.alb_dns_name
  lambda_source_file = "${path.module}/lambda/index.js"
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
  ecs_cluster_id         = module.ecs_cluster.cluster_id
  service_name           = "shortening"
  subnets                = module.network.private_subnets
  vpc_id                 = module.network.vpc_id
  security_group_ids     = [module.alb.security_group_id]
  ecs_execution_role_arn = module.ecs_cluster.execution_role_arn
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
  ecs_cluster_id         = module.ecs_cluster.cluster_id
  service_name           = "forwarding"
  subnets                = module.network.private_subnets
  vpc_id                 = module.network.vpc_id
  security_group_ids     = [module.alb.security_group_id]
  ecs_execution_role_arn = module.ecs_cluster.execution_role_arn
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

# Rule: Shortening API eg murl.pw/shorten -> Shortening Service
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
