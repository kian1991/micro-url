output "alb_dns_name" {
  value = aws_lb.this.dns_name
}

output "load_balancer_arn" {
  value = aws_lb.this.arn
}

output "security_group_id" {
  value = aws_security_group.public-http-alb.id
}


