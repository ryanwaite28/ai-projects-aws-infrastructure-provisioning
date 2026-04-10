variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "region" {
  type = string
}

variable "vpc_id" {
  type        = string
  description = "VPC ID from base-network."
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "Public subnet IDs for the public ALB."
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs for the private ALB and ECS tasks."
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR for security group rules."
}

variable "domain" {
  type        = string
  description = "Apex domain for ACM wildcard certificate (e.g. example.com)."
}

variable "zone_id" {
  type        = string
  description = "Route 53 hosted zone ID for ACM DNS validation."
}

variable "waf_rate_limit" {
  type        = number
  default     = 2000
  description = "Requests per 5-minute window per IP before rate limiting."
}

variable "alb_log_retention_days" {
  type    = number
  default = 30
}

variable "alb_access_log_bucket" {
  type        = string
  default     = null
  description = "S3 bucket for ALB access logs."
}

variable "cluster_name" {
  type    = string
  default = "main"
}

variable "container_insights_enabled" {
  type    = bool
  default = true
}

variable "execute_command_enabled" {
  type    = bool
  default = true
}

variable "tags" {
  type    = map(string)
  default = {}
}
