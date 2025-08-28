
variable "aws_region" {
  default     = "eu-central-1"
  type        = string
  description = "AWS Region"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "domain" {
  description = "Your domain for your URL shortener"
  type        = string
  default     = "murl.pw"
}

variable "repository_url" {
  type    = string
  default = "https://github.com/kian1991/micro-url"
}

variable "github_token" {
  type        = string
  sensitive   = true
  description = "GitHub PAT (minimal scopes) for Amplify connection"
}


