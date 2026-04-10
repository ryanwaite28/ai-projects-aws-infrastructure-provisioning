variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "region" {
  type = string
}

variable "name" {
  type = string
}

variable "container_image" {
  type = string
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
  default = 1
}

variable "autoscaling_min" {
  type    = number
  default = 0
}

variable "autoscaling_max" {
  type    = number
  default = 20
}

variable "target_messages_per_task" {
  type    = number
  default = 10
}

variable "visibility_timeout_seconds" {
  type    = number
  default = 120
}

variable "environment_variables" {
  type    = map(string)
  default = {}
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "security_group_ids" {
  type    = list(string)
  default = []
}

variable "ecs_cluster_arn" {
  type = string
}

variable "task_execution_role_arn" {
  type = string
}

variable "kms_key_arn" {
  type    = string
  default = null
}

variable "tags" {
  type    = map(string)
  default = {}
}
