variable "project" {
  type        = string
  description = "Project name prefix."
}

variable "environment" {
  type        = string
  description = "Deployment environment."
}

variable "region" {
  type        = string
  description = "AWS region."
}

variable "api_name" {
  description = "Short name. Full: {project}-{environment}-{region_short}-apigw-{api_name}."
  type        = string
}

variable "api_type" {
  description = "API type: HTTP (v2) or REST (v1)."
  type        = string
  default     = "HTTP"
  validation {
    condition     = contains(["HTTP", "REST"], var.api_type)
    error_message = "api_type must be HTTP or REST."
  }
}

variable "description" {
  description = "Human-readable description of the API."
  type        = string
  default     = ""
}

variable "stage_name" {
  description = "Stage name (e.g. v1, $default)."
  type        = string
  default     = "$default"
}

variable "auto_deploy" {
  description = "Automatically deploy on change (HTTP API v2 only)."
  type        = bool
  default     = true
}

variable "cors_configuration" {
  description = "CORS configuration for HTTP APIs."
  type = object({
    allow_origins     = optional(list(string), ["*"])
    allow_methods     = optional(list(string), ["GET", "POST", "PUT", "DELETE", "OPTIONS"])
    allow_headers     = optional(list(string), ["Content-Type", "Authorization", "X-Amz-Date"])
    expose_headers    = optional(list(string), [])
    max_age           = optional(number, 300)
    allow_credentials = optional(bool, false)
  })
  default = null
}

variable "routes" {
  description = "Map of routes to create. Key is '{method} {path}' (e.g. 'POST /webhook')."
  type = map(object({
    integration_type  = optional(string, "AWS_PROXY")  # AWS_PROXY | HTTP_PROXY | MOCK
    integration_uri   = optional(string, null)          # Lambda invoke ARN | HTTP URL | ALB listener ARN
    integration_method = optional(string, "POST")
    authorizer_key    = optional(string, null)           # references an authorizer in var.authorizers
    authorization_type = optional(string, "NONE")       # NONE | JWT | AWS_IAM | CUSTOM
  }))
  default = {}
}

variable "authorizers" {
  description = "Map of JWT authorizers. Key is the authorizer name."
  type = map(object({
    authorizer_type  = optional(string, "JWT")
    identity_sources = optional(list(string), ["$request.header.Authorization"])
    jwt_configuration = optional(object({
      audience = list(string)
      issuer   = string
    }), null)
    lambda_authorizer_uri = optional(string, null)
    payload_format_version = optional(string, "2.0")
  }))
  default = {}
}

variable "vpc_link_subnet_ids" {
  description = "Subnet IDs for the VPC Link (private ALB integration)."
  type        = list(string)
  default     = []
}

variable "vpc_link_security_group_ids" {
  description = "Security group IDs for the VPC Link."
  type        = list(string)
  default     = []
}

variable "custom_domain_name" {
  description = "Custom domain name for the API (e.g. 'api.example.com')."
  type        = string
  default     = null
}

variable "custom_domain_certificate_arn" {
  description = "ACM certificate ARN for the custom domain."
  type        = string
  default     = null
}

variable "waf_acl_arn" {
  description = "WAFv2 Web ACL ARN to associate with the stage."
  type        = string
  default     = null
}

variable "log_retention_days" {
  description = "Access log retention days."
  type        = number
  default     = 30
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags."
}
