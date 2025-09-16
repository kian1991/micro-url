
variable "service_name" { type = string }
variable "subnets" { type = list(string) }
variable "security_group_ids" { type = list(string) }
variable "vpc_id" { type = string }
variable "image" { type = string }
variable "container_port" { type = number }
variable "cpu" {
  type    = number
  default = 256
}
variable "memory" {
  type    = number
  default = 512
}
variable "region" { type = string }
variable "ecs_cluster_id" { type = string }
variable "desired_container_count" {
  type    = number
  default = 1
}
variable "ecs_execution_role_arn" {
  type = string
}
# Env vars
variable "environment" {
  type    = map(string)
  default = {}
}

variable "cloudwatch_log_enabled" {
  description = "Enable CloudWatch logging for this service"
  type        = bool
  default     = false
}
