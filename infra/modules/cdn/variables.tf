variable "domain" {
  type        = string
  description = "Primary domain for CloudFront aliases (e.g., murl.pw)"
}

variable "alb_domain_name" {
  type        = string
  description = "ALB DNS name to use as CloudFront custom origin"
}

variable "s3_bucket_name" {
  type        = string
  description = "Name of the S3 bucket for the frontend (defaults to <domain>-frontend)"
  default     = null
}

variable "s3_bucket_region" {
  type        = string
  description = "AWS region for the S3 bucket (defaults to the provider region)"
}

variable "cf_router" {
  type = object({
    output_path : string
    output_base64sha256 : string
  })
  description = "Archive file details for the CloudFront Lambda@Edge function"
}

variable "acm_certificate_arn" {
  type        = string
  description = "ARN of the ACM certificate in us-east-1 for CloudFront"
  default     = null
}
