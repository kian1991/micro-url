
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

variable "cloudwatch_log_enabled" {
  description = "Enable CloudWatch logging"
  type        = bool
  default     = false
}





