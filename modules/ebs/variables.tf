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

variable "volume_name" {
  description = "Short name for the EBS volume."
  type        = string
}

variable "availability_zone" {
  description = "AZ where the EBS volume is created. Must match the AZ of the instance it attaches to."
  type        = string
}

variable "size_gb" {
  description = "Volume size in GiB."
  type        = number
  default     = 20
}

variable "volume_type" {
  description = "EBS volume type: gp3 | gp2 | io2 | io1 | st1 | sc1."
  type        = string
  default     = "gp3"
}

variable "iops" {
  description = "Provisioned IOPS. Required for io1/io2; optional for gp3 (default 3000)."
  type        = number
  default     = null
}

variable "throughput" {
  description = "Throughput in MiB/s for gp3 volumes (125–1000)."
  type        = number
  default     = null
}

variable "kms_key_arn" {
  description = "KMS key ARN for volume encryption. Null uses AWS-managed key."
  type        = string
  default     = null
}

variable "snapshot_id" {
  description = "Snapshot ID to restore the volume from."
  type        = string
  default     = null
}

variable "multi_attach_enabled" {
  description = "Enable multi-attach for io1/io2 volumes (allows attach to multiple instances simultaneously)."
  type        = bool
  default     = false
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags."
}
