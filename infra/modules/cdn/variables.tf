variable "domain" {
  type        = string
  description = "Primary domain for CloudFront aliases (e.g., murl.pw)"
}

variable "alb_domain_name" {
  type        = string
  description = "ALB DNS name to use as CloudFront custom origin"
}

variable "lambda_source_file" {
  type        = string
  description = "Path to the Lambda@Edge source file (index.js)"
}

variable "s3_bucket_name" {
  type        = string
  description = "Name of the S3 bucket for the frontend (defaults to <domain>-frontend)"
  default     = null
}

