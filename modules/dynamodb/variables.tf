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

variable "table_name" {
  description = "Short name. Full name: {project}-{environment}-{region_short}-{table_name}."
  type        = string
}

variable "hash_key" {
  description = "Partition key attribute name."
  type        = string
}

variable "hash_key_type" {
  description = "Type of the partition key: S (String), N (Number), or B (Binary)."
  type        = string
  default     = "S"
}

variable "range_key" {
  description = "Sort key attribute name. Omit for partition-key-only tables."
  type        = string
  default     = null
}

variable "range_key_type" {
  description = "Type of the sort key: S, N, or B."
  type        = string
  default     = "S"
}

variable "billing_mode" {
  description = "PAY_PER_REQUEST (on-demand) or PROVISIONED."
  type        = string
  default     = "PAY_PER_REQUEST"
}

variable "read_capacity" {
  description = "Read capacity units (only used with PROVISIONED billing)."
  type        = number
  default     = 5
}

variable "write_capacity" {
  description = "Write capacity units (only used with PROVISIONED billing)."
  type        = number
  default     = 5
}

variable "ttl_attribute" {
  description = "Attribute name to use for TTL. Set to null to disable TTL."
  type        = string
  default     = null
}

variable "point_in_time_recovery" {
  description = "Enable point-in-time recovery (PITR)."
  type        = bool
  default     = true
}

variable "deletion_protection" {
  description = "Prevent accidental table deletion."
  type        = bool
  default     = false
}

variable "kms_key_arn" {
  description = "KMS key ARN for server-side encryption. Null uses AWS-owned key."
  type        = string
  default     = null
}

variable "stream_enabled" {
  description = "Enable DynamoDB Streams."
  type        = bool
  default     = false
}

variable "stream_view_type" {
  description = "Stream view type: KEYS_ONLY | NEW_IMAGE | OLD_IMAGE | NEW_AND_OLD_IMAGES."
  type        = string
  default     = "NEW_AND_OLD_IMAGES"
}

variable "attributes" {
  description = "List of non-key attribute definitions required for GSIs/LSIs."
  type = list(object({
    name = string
    type = string # S | N | B
  }))
  default = []
}

variable "global_secondary_indexes" {
  description = "List of GSI configurations."
  type = list(object({
    name               = string
    hash_key           = string
    range_key          = optional(string, null)
    projection_type    = optional(string, "ALL")
    non_key_attributes = optional(list(string), [])
    read_capacity      = optional(number, 5)
    write_capacity     = optional(number, 5)
  }))
  default = []
}

variable "replica_regions" {
  description = "List of AWS regions to create Global Table replicas in."
  type        = list(string)
  default     = []
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags."
}
