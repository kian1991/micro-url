output "distribution_id" {
  value = aws_cloudfront_distribution.this.id
}

output "distribution_domain_name" {
  value = aws_cloudfront_distribution.this.domain_name
}

output "s3_bucket_name" {
  value = aws_s3_bucket.frontend.bucket
}

output "s3_bucket_domain_name" {
  value = aws_s3_bucket.frontend.bucket_domain_name
}

