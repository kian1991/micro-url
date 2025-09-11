terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

locals {
  bucket_name = coalesce(var.s3_bucket_name, "${var.domain}-frontend")
}

data "aws_acm_certificate" "cf_cert" {
  provider    = aws
  domain      = var.domain
  statuses    = ["ISSUED"]
  most_recent = true
}

data "archive_file" "cf_router" {
  type        = "zip"
  source_file = var.lambda_source_file
  output_path = "${path.module}/cf-router.zip"
}

resource "aws_s3_bucket" "frontend" {
  provider = aws
  bucket   = local.bucket_name
}

resource "aws_s3_bucket_ownership_controls" "frontend" {
  provider = aws
  bucket   = aws_s3_bucket.frontend.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "frontend" {
  provider = aws
  bucket   = aws_s3_bucket.frontend.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_cloudfront_origin_access_control" "frontend_oac" {
  provider                          = aws
  name                              = "frontend-oac"
  description                       = "OAC for CloudFront to access S3 frontend bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_iam_role" "lambda_edge" {
  name = "lambda-edge-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = { Service = "lambda.amazonaws.com" },
        Action    = "sts:AssumeRole"
      },
      {
        Effect    = "Allow",
        Principal = { Service = "edgelambda.amazonaws.com" },
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_edge_basic" {
  role       = aws_iam_role.lambda_edge.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "cf_router" {
  provider         = aws
  function_name    = "cf-router"
  role             = aws_iam_role.lambda_edge.arn
  handler          = "index.handler"
  runtime          = "nodejs22.x"
  publish          = true
  filename         = data.archive_file.cf_router.output_path
  source_code_hash = data.archive_file.cf_router.output_base64sha256
}

resource "aws_cloudfront_distribution" "this" {
  provider            = aws
  enabled             = true
  default_root_object = "index.html"
  depends_on          = [aws_lambda_function.cf_router, aws_cloudfront_origin_access_control.frontend_oac]

  aliases = [var.domain]

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
    domain_name = var.alb_domain_name
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

resource "aws_s3_bucket_policy" "frontend" {
  provider = aws
  bucket   = aws_s3_bucket.frontend.id
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
