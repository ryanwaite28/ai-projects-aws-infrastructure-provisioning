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

variable "kinesis_on_demand" {
  type    = bool
  default = true
}

variable "kinesis_shard_count" {
  type    = number
  default = 1
}

variable "kinesis_retention_hours" {
  type    = number
  default = 24
}

variable "dynamic_partitioning" {
  type    = bool
  default = true
}

variable "buffering_size_mb" {
  type    = number
  default = 64
}

variable "buffering_interval_seconds" {
  type    = number
  default = 300
}

variable "enable_transformation" {
  type    = bool
  default = false
}

variable "lambda_runtime" {
  type    = string
  default = "python3.12"
}

variable "lambda_handler" {
  type    = string
  default = "transformer.handler"
}

variable "lambda_s3_bucket" {
  type    = string
  default = null
}

variable "lambda_s3_key" {
  type    = string
  default = null
}

variable "kms_key_arn" {
  type    = string
  default = null
}

variable "tags" {
  type    = map(string)
  default = {}
}
