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

variable "alias" {
  description = "KMS key alias (without the 'alias/' prefix). Will be prefixed with project/environment."
  type        = string
}

variable "description" {
  description = "Human-readable description for the KMS key."
  type        = string
  default     = "Customer managed key"
}

variable "deletion_window_in_days" {
  description = "Waiting period (7–30 days) before key deletion after destroy."
  type        = number
  default     = 30
}

variable "enable_key_rotation" {
  description = "Enable automatic annual key rotation."
  type        = bool
  default     = true
}

variable "multi_region" {
  description = "Create a multi-region primary key (can be replicated to other regions)."
  type        = bool
  default     = false
}

variable "admin_principal_arns" {
  description = "List of IAM principal ARNs that can administer (manage) this key. Typically the ops/devops role."
  type        = list(string)
  default     = []
}

variable "usage_principal_arns" {
  description = "List of IAM principal ARNs that can use this key for encrypt/decrypt operations."
  type        = list(string)
  default     = []
}

variable "service_principals" {
  description = "List of AWS service principals allowed to use this key (e.g. 'logs.amazonaws.com', 'sns.amazonaws.com')."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Additional tags merged into the default tag set."
  type        = map(string)
  default     = {}
}
