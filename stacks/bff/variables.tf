variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "region" {
  type = string
}

variable "service_name" {
  type        = string
  description = "Short name for this BFF service (e.g. 'web-bff')."
}

variable "container_image" {
  type        = string
  description = "Full ECR image URI including tag."
}

variable "container_port" {
  type    = number
  default = 8080
}

variable "task_cpu" {
  type    = number
  default = 512
}

variable "task_memory" {
  type    = number
  default = 1024
}

variable "desired_count" {
  type    = number
  default = 2
}

variable "autoscaling_min" {
  type    = number
  default = 1
}

variable "autoscaling_max" {
  type    = number
  default = 10
}

variable "path_pattern" {
  type        = string
  description = "ALB path pattern for this service (e.g. '/api/*')."
}

variable "listener_priority" {
  type        = number
  description = "Listener rule priority (lower = higher priority). Must be unique across all services."
}

variable "health_check_path" {
  type    = string
  default = "/health"
}

variable "environment_variables" {
  type    = map(string)
  default = {}
}

variable "secret_arns" {
  type        = list(string)
  default     = []
  description = "Secrets Manager ARNs injected as env vars."
}

# Read from SSM (populated by platform stack) or pass directly
variable "ssm_prefix" {
  type        = string
  default     = null
  description = "Platform SSM prefix. When set, all vpc_id/subnet/cluster vars are read from SSM."
}

variable "vpc_id" {
  type    = string
  default = null
}

variable "private_subnet_ids" {
  type    = list(string)
  default = null
}

variable "ecs_cluster_arn" {
  type    = string
  default = null
}

variable "public_alb_listener_arn" {
  type    = string
  default = null
}

variable "sg_ecs_tasks_id" {
  type    = string
  default = null
}

variable "task_execution_role_arn" {
  type    = string
  default = null
}

variable "tags" {
  type    = map(string)
  default = {}
}
