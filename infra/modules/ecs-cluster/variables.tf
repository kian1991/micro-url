variable "cluster_name" {
  type        = string
  description = "Name of the ECS cluster"
}

variable "enable_container_insights" {
  type        = bool
  description = "Enable CloudWatch Container Insights"
  default     = true
}

variable "execution_role_name" {
  type        = string
  description = "IAM role name for ECS task execution"
  default     = "ecsTaskExecutionRole"
}

