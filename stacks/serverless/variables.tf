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
  type        = string
  description = "Short name for this serverless workload."
}

variable "lambda_runtime" {
  type    = string
  default = "python3.12"
}

variable "lambda_handler" {
  type    = string
  default = "handler.main"
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
  default = 60
}

variable "lambda_environment_variables" {
  type    = map(string)
  default = {}
}

variable "dynamodb_table_name" {
  type    = string
  default = null
}

variable "dynamodb_hash_key" {
  type    = string
  default = "id"
}

variable "schedule_expressions" {
  type    = list(string)
  default = []
}

variable "kms_key_arn" {
  type    = string
  default = null
}

variable "vpc_config" {
  type = object({
    subnet_ids         = list(string)
    security_group_ids = list(string)
  })
  default = null
}

variable "tags" {
  type    = map(string)
  default = {}
}
