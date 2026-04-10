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
  description = "Short name for the EFS file system."
  type        = string
}

variable "performance_mode" {
  description = "EFS performance mode: generalPurpose | maxIO."
  type        = string
  default     = "generalPurpose"
}

variable "throughput_mode" {
  description = "EFS throughput mode: bursting | provisioned | elastic."
  type        = string
  default     = "elastic"
}

variable "provisioned_throughput_mibps" {
  description = "Throughput in MiB/s when throughput_mode = provisioned."
  type        = number
  default     = null
}

variable "kms_key_arn" {
  description = "KMS key ARN for encryption at rest."
  type        = string
  default     = null
}

variable "lifecycle_policy" {
  description = "Map of EFS lifecycle policies."
  type = object({
    transition_to_ia                    = optional(string, "AFTER_30_DAYS")
    transition_to_primary_storage_class = optional(string, "AFTER_1_ACCESS")
  })
  default = {}
}

variable "subnet_ids" {
  description = "Subnet IDs for mount targets (one per AZ)."
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC ID for the EFS mount target security group."
  type        = string
}

variable "allowed_security_group_ids" {
  description = "Security group IDs whose members are allowed NFS access (port 2049)."
  type        = list(string)
}

variable "access_points" {
  description = "Map of EFS access point configurations."
  type = map(object({
    root_directory_path        = optional(string, "/")
    root_directory_owner_gid   = optional(number, 1000)
    root_directory_owner_uid   = optional(number, 1000)
    root_directory_permissions = optional(string, "755")
    posix_user_gid             = optional(number, 1000)
    posix_user_uid             = optional(number, 1000)
  }))
  default = {}
}

variable "enable_backup" {
  description = "Enable AWS Backup for this file system."
  type        = bool
  default     = true
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags."
}
