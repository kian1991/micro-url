output "alb_dns_name" {
  value = module.alb.alb_dns_name
}

output "s3_bucket_domain_name" {
  value = aws_s3_bucket.frontend.bucket_domain_name

}
