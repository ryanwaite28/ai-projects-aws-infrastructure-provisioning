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

variable "stream_name" {
  description = "Short name. Full: {project}-{environment}-{region_short}-kinesis-{stream_name}."
  type        = string
}

variable "on_demand" {
  description = "Use on-demand capacity mode. If false, shard_count is required."
  type        = bool
  default     = true
}

variable "shard_count" {
  description = "Number of shards (PROVISIONED mode only)."
  type        = number
  default     = 1
}

variable "retention_period_hours" {
  description = "Retention period in hours (24–8760)."
  type        = number
  default     = 24
}

variable "kms_key_arn" {
  description = "KMS key ARN for server-side encryption."
  type        = string
  default     = null
}

variable "enhanced_fan_out_consumers" {
  description = "List of consumer names to register for enhanced fan-out (dedicated read throughput)."
  type        = list(string)
  default     = []
}

variable "shard_level_metrics" {
  description = "List of shard-level CloudWatch metrics to enable."
  type        = list(string)
  default     = ["IncomingBytes", "IncomingRecords", "OutgoingBytes", "OutgoingRecords", "ReadProvisionedThroughputExceeded", "WriteProvisionedThroughputExceeded", "IteratorAgeMilliseconds"]
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags."
}
