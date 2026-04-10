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

variable "role_name" {
  description = "Short name for the IAM role. Will be prefixed with project/environment."
  type        = string
}

variable "role_description" {
  description = "Human-readable description for the IAM role."
  type        = string
  default     = ""
}

variable "trusted_service_principals" {
  description = "List of AWS service principals that can assume this role (e.g. 'ecs-tasks.amazonaws.com', 'lambda.amazonaws.com')."
  type        = list(string)
  default     = []
}

variable "trusted_role_arns" {
  description = "List of IAM role ARNs that can assume this role via sts:AssumeRole (cross-account or same-account)."
  type        = list(string)
  default     = []
}

variable "trusted_oidc_provider_arn" {
  description = "ARN of an OIDC Identity Provider to include in the trust policy (e.g. GitHub Actions)."
  type        = string
  default     = null
}

variable "oidc_subject_conditions" {
  description = "Map of OIDC condition keys and values for the trust policy (used with trusted_oidc_provider_arn). E.g. { 'token.actions.githubusercontent.com:sub' = 'repo:org/repo:*' }."
  type        = map(string)
  default     = {}
}

variable "managed_policy_arns" {
  description = "List of AWS-managed or customer-managed IAM policy ARNs to attach."
  type        = list(string)
  default     = []
}

variable "inline_policies" {
  description = "Map of inline policy name → JSON policy document string."
  type        = map(string)
  default     = {}
}

variable "permission_boundary_arn" {
  description = "ARN of a permissions boundary policy to attach to the role."
  type        = string
  default     = null
}

variable "max_session_duration" {
  description = "Maximum session duration in seconds (3600–43200)."
  type        = number
  default     = 3600
}

variable "force_detach_policies" {
  description = "Force-detach policies before deleting the role."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags merged into the default tag set."
  type        = map(string)
  default     = {}
}
