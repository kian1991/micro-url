
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

# -------------------------------------------------------------------
# Global resources
# -------------------------------------------------------------------
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
  container_port         = 3000
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
    BASE_URL  = "http://${module.alb.alb_dns_name}"
    PORT      = "3000"
  }
}



module "ecs_forwarding_service" {
  source                 = "./modules/ecs-services"
  container_port         = 3000
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
    BASE_URL  = "http://${module.alb.alb_dns_name}"
    PORT      = "3000"
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
resource "aws_lb_listener" "this" {
  load_balancer_arn = module.alb.load_balancer_arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = module.ecs_forwarding_service.target_group_arn
  }
}


# the shortening endpoint
resource "aws_lb_listener_rule" "shortening" {
  listener_arn = aws_lb_listener.this.arn
  priority     = 100

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

