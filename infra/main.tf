
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

module "network" {
  source     = "./modules/network"
  cidr_block = var.vpc_cidr
}

module "alb" {
  source            = "./modules/alb"
  vpc_id            = module.network.vpc_id
  public_subnets    = module.network.public_subnets
  security_group_id = module.security_group.alb.id
}
