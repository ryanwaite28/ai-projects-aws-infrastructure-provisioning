variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "region" {
  type = string
}

variable "topic_name" {
  type = string
}

variable "allowed_publisher_arns" {
  type    = list(string)
  default = []
}

variable "sqs_subscribers" {
  type        = map(any)
  default     = {}
  description = "Map of subscriber name to config. Creates one SQS queue per entry."
}

variable "lambda_subscriber_arns" {
  type    = list(string)
  default = []
}

variable "email_subscribers" {
  type    = list(string)
  default = []
}

variable "kms_key_arn" {
  type    = string
  default = null
}

variable "tags" {
  type    = map(string)
  default = {}
}
