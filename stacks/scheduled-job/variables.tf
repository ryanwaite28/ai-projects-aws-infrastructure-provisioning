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

variable "target_type" {
  type        = string
  default     = "lambda"
  description = "lambda or ecs."
}

variable "schedules" {
  type = list(object({
    expression  = string
    description = optional(string, "")
  }))
  description = "List of schedule expressions (rate() or cron())."
}

variable "lambda_runtime" {
  type    = string
  default = "python3.12"
}

variable "lambda_handler" {
  type    = string
  default = "job.run"
}

variable "lambda_s3_bucket" {
  type    = string
  default = null
}

variable "lambda_s3_key" {
  type    = string
  default = null
}

variable "lambda_memory_size" {
  type    = number
  default = 512
}

variable "lambda_timeout" {
  type    = number
  default = 300
}

variable "environment_variables" {
  type    = map(string)
  default = {}
}

variable "vpc_config" {
  type = object({
    subnet_ids         = list(string)
    security_group_ids = list(string)
  })
  default = null
}

variable "ecs_cluster_arn" {
  type    = string
  default = null
}

variable "ecs_task_definition_arn" {
  type    = string
  default = null
}

variable "ecs_subnet_ids" {
  type    = list(string)
  default = []
}

variable "ecs_security_group_ids" {
  type    = list(string)
  default = []
}

variable "tags" {
  type    = map(string)
  default = {}
}
