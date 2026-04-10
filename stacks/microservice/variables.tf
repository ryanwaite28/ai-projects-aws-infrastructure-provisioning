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
  description = "Short name for this microservice (e.g. 'payments-svc')."
}

variable "container_image" {
  type = string
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
  description = "Private ALB path pattern (e.g. '/payments/*')."
}

variable "listener_priority" {
  type = number
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
  type    = list(string)
  default = []
}

variable "ssm_prefix" {
  type    = string
  default = null
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

variable "private_alb_listener_arn" {
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
