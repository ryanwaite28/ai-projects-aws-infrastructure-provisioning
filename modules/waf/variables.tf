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

variable "name" {
  description = "Short name for the Web ACL."
  type        = string
}

variable "scope" {
  description = "REGIONAL (ALB, API Gateway) or CLOUDFRONT (must be created in us-east-1)."
  type        = string
  default     = "REGIONAL"
  validation {
    condition     = contains(["REGIONAL", "CLOUDFRONT"], var.scope)
    error_message = "scope must be REGIONAL or CLOUDFRONT."
  }
}

variable "managed_rule_groups" {
  description = "List of AWS managed rule groups to include."
  type = list(object({
    name            = string  # e.g. AWSManagedRulesCommonRuleSet
    vendor_name     = optional(string, "AWS")
    priority        = number
    override_action = optional(string, "none")  # none | count
    excluded_rules  = optional(list(string), [])
  }))
  default = [
    { name = "AWSManagedRulesCommonRuleSet",          priority = 10 },
    { name = "AWSManagedRulesKnownBadInputsRuleSet",  priority = 20 },
    { name = "AWSManagedRulesSQLiRuleSet",            priority = 30 },
  ]
}

variable "rate_limit_rules" {
  description = "List of rate-based rules."
  type = list(object({
    name               = string
    priority           = number
    limit              = number  # requests per 5-minute window per IP
    action             = optional(string, "block")  # block | count
    aggregate_key_type = optional(string, "IP")
  }))
  default = [{ name = "rate-limit-global", priority = 1, limit = 2000 }]
}

variable "ip_allow_list_cidrs" {
  description = "CIDR blocks to explicitly allow (bypasses all rules)."
  type        = list(string)
  default     = []
}

variable "ip_block_list_cidrs" {
  description = "CIDR blocks to explicitly block."
  type        = list(string)
  default     = []
}

variable "cloudwatch_metrics_enabled" {
  description = "Enable CloudWatch metrics for the Web ACL."
  type        = bool
  default     = true
}

variable "sampled_requests_enabled" {
  description = "Enable sampled requests in the AWS console."
  type        = bool
  default     = true
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags."
}
