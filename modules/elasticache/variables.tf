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

variable "cluster_id" {
  description = "Short identifier. Full: {project}-{environment}-{region_short}-redis-{cluster_id}."
  type        = string
}

variable "node_type" {
  description = "ElastiCache node type (e.g. cache.r7g.large)."
  type        = string
  default     = "cache.r7g.large"
}

variable "engine_version" {
  description = "Redis engine version (e.g. '7.1')."
  type        = string
  default     = "7.1"
}

variable "num_cache_clusters" {
  description = "Number of cache clusters (nodes). 1 = no replication, 2+ = primary + replicas."
  type        = number
  default     = 2
}

variable "automatic_failover_enabled" {
  description = "Enable automatic failover (requires num_cache_clusters >= 2)."
  type        = bool
  default     = true
}

variable "multi_az_enabled" {
  description = "Enable Multi-AZ (requires automatic_failover_enabled = true)."
  type        = bool
  default     = true
}

variable "subnet_ids" {
  description = "Subnet IDs for the ElastiCache subnet group (DB/isolated subnets recommended)."
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security group IDs for the cluster."
  type        = list(string)
}

variable "port" {
  description = "Redis port."
  type        = number
  default     = 6379
}

variable "at_rest_encryption_enabled" {
  description = "Enable encryption at rest."
  type        = bool
  default     = true
}

variable "transit_encryption_enabled" {
  description = "Enable TLS in-transit encryption."
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "KMS key ARN for at-rest encryption. Null uses AWS-managed key."
  type        = string
  default     = null
}

variable "auth_token_secret_arn" {
  description = "Secrets Manager ARN containing the Redis AUTH token (required with transit_encryption_enabled)."
  type        = string
  default     = null
}

variable "snapshot_retention_limit" {
  description = "Number of days for automatic snapshot retention (0 = disabled)."
  type        = number
  default     = 7
}

variable "snapshot_window" {
  description = "Daily time range for snapshots (UTC). E.g. '03:00-04:00'."
  type        = string
  default     = "03:00-04:00"
}

variable "maintenance_window" {
  description = "Weekly maintenance window. E.g. 'sun:05:00-sun:06:00'."
  type        = string
  default     = "sun:05:00-sun:06:00"
}

variable "log_delivery_configurations" {
  description = "List of log delivery configurations (slow-log, engine-log)."
  type = list(object({
    log_type        = string # slow-log | engine-log
    destination     = string # CloudWatch log group name or Kinesis Firehose ARN
    destination_type = string # cloudwatch-logs | kinesis-firehose
    log_format      = string # text | json
  }))
  default = []
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags."
}
