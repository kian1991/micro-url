variable "private_subnets" {
  type = list(string)
}
variable "vpc_id" {
  type = string
}

variable "ecs_task_sg_ids" {
  type = list(string)
}

variable "node_type" {
  default = "cache.t3.micro"
  type    = string
}

variable "num_cache_nodes" {
  default = 1
  type    = number
}
