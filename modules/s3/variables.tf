variable "project" {
  description = "Project name used as a prefix in resource names and tags."
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, qa, prod)."
  type        = string
}

variable "region" {
  description = "AWS region where the bucket is created."
  type        = string
}

variable "bucket_suffix" {
  description = "Short suffix appended to the generated bucket name (e.g. 'assets', 'uploads', 'logs'). Full name: {project}-{environment}-{region_short}-{suffix}."
  type        = string
}

variable "versioning_enabled" {
  description = "Enable S3 versioning on the bucket."
  type        = bool
  default     = false
}

variable "force_destroy" {
  description = "Allow Terraform to delete the bucket even if it contains objects."
  type        = bool
  default     = false
}

variable "kms_key_arn" {
  description = "KMS key ARN for server-side encryption (SSE-KMS). If null, uses SSE-S3 (AES-256)."
  type        = string
  default     = null
}

variable "lifecycle_rules" {
  description = "List of lifecycle rule configurations."
  type = list(object({
    id                                 = string
    enabled                            = bool
    prefix                             = optional(string, "")
    transition_days                    = optional(number, null)
    transition_storage_class           = optional(string, "STANDARD_IA")
    glacier_transition_days            = optional(number, null)
    expiration_days                    = optional(number, null)
    noncurrent_version_expiration_days = optional(number, null)
  }))
  default = []
}

variable "replication_enabled" {
  description = "Enable cross-region replication to a destination bucket."
  type        = bool
  default     = false
}

variable "replication_destination_bucket_arn" {
  description = "ARN of the destination bucket for cross-region replication. Required when replication_enabled = true."
  type        = string
  default     = null
}

variable "replication_destination_kms_key_arn" {
  description = "KMS key ARN in the destination region for encrypting replicated objects."
  type        = string
  default     = null
}

variable "cors_rules" {
  description = "List of CORS rule configurations."
  type = list(object({
    allowed_headers = optional(list(string), ["*"])
    allowed_methods = list(string)
    allowed_origins = list(string)
    expose_headers  = optional(list(string), [])
    max_age_seconds = optional(number, 3000)
  }))
  default = []
}

variable "bucket_policy_json" {
  description = "Additional bucket policy JSON document to apply. Merged with the default block-public-access posture."
  type        = string
  default     = null
}

variable "object_lock_enabled" {
  description = "Enable S3 Object Lock (WORM). Cannot be disabled after bucket creation."
  type        = bool
  default     = false
}

variable "access_log_bucket_id" {
  description = "Bucket ID to receive S3 server access logs. If null, access logging is disabled."
  type        = string
  default     = null
}

variable "tags" {
  description = "Additional tags merged into the default tag set."
  type        = map(string)
  default     = {}
}
