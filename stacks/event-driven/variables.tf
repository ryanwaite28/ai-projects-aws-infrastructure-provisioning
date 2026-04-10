variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "region" {
  type = string
}

variable "bus_name" {
  type = string
}

variable "allowed_publisher_arns" {
  type    = list(string)
  default = []
}

variable "event_rules" {
  type    = any
  default = {}
}

variable "consumers" {
  type = map(object({
    runtime               = string
    handler               = string
    s3_bucket             = optional(string)
    s3_key                = optional(string)
    memory_size           = optional(number, 512)
    timeout               = optional(number, 60)
    environment_variables = optional(map(string), {})
    vpc_config = optional(object({
      subnet_ids         = list(string)
      security_group_ids = list(string)
    }))
  }))
  default = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}
