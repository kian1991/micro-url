output "alb_dns_name" {
  value = module.alb.alb_dns_name
}

output "s3_bucket_domain_name" {
  value = module.cdn.s3_bucket_domain_name
}

output "cloudfront_domain_name" {
  value = module.cdn.distribution_domain_name

}
