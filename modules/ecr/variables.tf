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

variable "repository_name" {
  description = "Short name of the ECR repository. Full name: {project}/{environment}/{repository_name}."
  type        = string
}

variable "image_tag_mutability" {
  description = "Tag mutability setting: MUTABLE or IMMUTABLE. Use IMMUTABLE in prod to prevent tag overwrites."
  type        = string
  default     = "IMMUTABLE"

  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.image_tag_mutability)
    error_message = "image_tag_mutability must be MUTABLE or IMMUTABLE."
  }
}

variable "scan_on_push" {
  description = "Enable automated vulnerability scanning on each image push."
  type        = bool
  default     = true
}

variable "keep_image_count" {
  description = "Number of tagged images to retain per repository. Older images are expired by the lifecycle policy."
  type        = number
  default     = 10
}

variable "untagged_expiry_days" {
  description = "Number of days after which untagged images are deleted."
  type        = number
  default     = 7
}

variable "kms_key_arn" {
  description = "KMS key ARN for repository encryption. If null, uses AES-256 (AWS-managed)."
  type        = string
  default     = null
}

variable "cross_account_pull_arns" {
  description = "List of IAM principal ARNs (from other accounts) that are allowed to pull images. Used in ops→prod cross-account pull patterns."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Additional tags merged into the default tag set."
  type        = map(string)
  default     = {}
}
