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

variable "cluster_identifier" {
  description = "Short identifier for the cluster. Full: {project}-{environment}-{region_short}-{cluster_identifier}."
  type        = string
}

variable "engine" {
  description = "Database engine: aurora-postgresql | aurora-mysql | postgres | mysql."
  type        = string
  default     = "aurora-postgresql"
}

variable "engine_version" {
  description = "Engine version string (e.g. '15.4' for Aurora PostgreSQL)."
  type        = string
  default     = "15.4"
}

variable "instance_class" {
  description = "DB instance class (e.g. db.r8g.large, db.serverless for Aurora Serverless v2)."
  type        = string
  default     = "db.r8g.large"
}

variable "serverless_v2" {
  description = "Use Aurora Serverless v2 scaling instead of fixed instance class."
  type        = bool
  default     = false
}

variable "serverless_min_acu" {
  description = "Minimum Aurora Capacity Units for Serverless v2."
  type        = number
  default     = 0.5
}

variable "serverless_max_acu" {
  description = "Maximum Aurora Capacity Units for Serverless v2."
  type        = number
  default     = 16
}

variable "instance_count" {
  description = "Number of DB instances in the cluster (1 = writer only, 2+ = writer + readers)."
  type        = number
  default     = 2
}

variable "database_name" {
  description = "Name of the initial database created in the cluster."
  type        = string
}

variable "master_username" {
  description = "Master username for the database."
  type        = string
  default     = "dbadmin"
}

variable "master_password_secret_arn" {
  description = "Secrets Manager secret ARN containing the master password. If null, RDS manages the password."
  type        = string
  default     = null
}

variable "subnet_ids" {
  description = "Subnet IDs for the DB subnet group (use isolated/DB subnets)."
  type        = list(string)
}

variable "vpc_security_group_ids" {
  description = "Security group IDs for the cluster."
  type        = list(string)
}

variable "backup_retention_period" {
  description = "Number of days to retain automated backups."
  type        = number
  default     = 7
}

variable "preferred_backup_window" {
  description = "Daily time range for automated backups (UTC). E.g. '02:00-03:00'."
  type        = string
  default     = "02:00-03:00"
}

variable "preferred_maintenance_window" {
  description = "Weekly time range for cluster maintenance. E.g. 'sun:04:00-sun:05:00'."
  type        = string
  default     = "sun:04:00-sun:05:00"
}

variable "deletion_protection" {
  description = "Prevent accidental cluster deletion."
  type        = bool
  default     = true
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot on cluster deletion. Set false in prod."
  type        = bool
  default     = false
}

variable "kms_key_arn" {
  description = "KMS key ARN for storage encryption."
  type        = string
  default     = null
}

variable "performance_insights_enabled" {
  description = "Enable Performance Insights."
  type        = bool
  default     = true
}

variable "monitoring_interval" {
  description = "Enhanced Monitoring interval in seconds (0 = disabled, 1 | 5 | 10 | 15 | 30 | 60)."
  type        = number
  default     = 60
}

variable "apply_immediately" {
  description = "Apply changes immediately instead of during the maintenance window."
  type        = bool
  default     = false
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags."
}
