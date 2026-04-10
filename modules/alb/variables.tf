variable "project" {
  description = "Project name used as a prefix in resource names and tags."
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, qa, prod)."
  type        = string
}

variable "region" {
  description = "AWS region for this module's resources."
  type        = string
}

variable "name" {
  description = "Short name for the ALB. Full name: {project}-{environment}-{region_short}-alb-{name}."
  type        = string
}

variable "internal" {
  description = "True for internal (private) ALB; false for internet-facing (public) ALB."
  type        = bool
  default     = false
}

variable "vpc_id" {
  description = "VPC ID where the ALB is deployed."
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for the ALB. Public ALB → public subnets; internal ALB → private subnets."
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security group IDs to attach to the ALB."
  type        = list(string)
  default     = []
}

variable "certificate_arn" {
  description = "ACM certificate ARN for the HTTPS listener."
  type        = string
  default     = null
}

variable "additional_certificate_arns" {
  description = "Additional ACM certificate ARNs to attach to the HTTPS listener (SNI)."
  type        = list(string)
  default     = []
}

variable "ssl_policy" {
  description = "SSL negotiation policy for the HTTPS listener."
  type        = string
  default     = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}

variable "enable_http_to_https_redirect" {
  description = "Create an HTTP:80 listener that redirects to HTTPS:443."
  type        = bool
  default     = true
}

variable "idle_timeout" {
  description = "Connection idle timeout in seconds."
  type        = number
  default     = 60
}

variable "enable_deletion_protection" {
  description = "Prevent accidental ALB deletion via the AWS console."
  type        = bool
  default     = false
}

variable "enable_access_logs" {
  description = "Enable ALB access logging to S3."
  type        = bool
  default     = false
}

variable "access_logs_bucket" {
  description = "S3 bucket name for ALB access logs. Required when enable_access_logs = true."
  type        = string
  default     = null
}

variable "access_logs_prefix" {
  description = "S3 key prefix for ALB access logs."
  type        = string
  default     = "alb-access-logs"
}

variable "waf_acl_arn" {
  description = "ARN of a WAFv2 Web ACL to associate with this ALB."
  type        = string
  default     = null
}

variable "target_groups" {
  description = "Map of target group configurations to create. Key becomes part of the target group name."
  type = map(object({
    port              = number
    protocol          = optional(string, "HTTP")
    target_type       = optional(string, "ip")
    deregistration_delay = optional(number, 30)
    health_check = optional(object({
      path                = optional(string, "/health")
      healthy_threshold   = optional(number, 2)
      unhealthy_threshold = optional(number, 3)
      interval            = optional(number, 30)
      timeout             = optional(number, 5)
      matcher             = optional(string, "200")
    }), {})
  }))
  default = {}
}

variable "listener_rules" {
  description = "List of listener rules to create on the HTTPS listener. Evaluated in priority order."
  type = list(object({
    priority = number
    target_group_key = string
    conditions = list(object({
      type   = string # path_pattern | host_header | http_header | source_ip
      values = list(string)
    }))
  }))
  default = []
}

variable "tags" {
  description = "Additional tags merged into the default tag set."
  type        = map(string)
  default     = {}
}
