variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "region" {
  type = string
}

variable "db_subnet_ids" {
  type = list(string)
}

variable "rds_enabled" {
  type    = bool
  default = true
}

variable "rds_engine" {
  type    = string
  default = "aurora-postgresql"
}

variable "rds_engine_version" {
  type    = string
  default = "15.4"
}

variable "rds_instance_class" {
  type    = string
  default = "db.r8g.large"
}

variable "rds_serverless_v2" {
  type    = bool
  default = false
}

variable "rds_instance_count" {
  type    = number
  default = 2
}

variable "rds_database_name" {
  type    = string
  default = "appdb"
}

variable "rds_deletion_protection" {
  type    = bool
  default = true
}

variable "rds_skip_final_snapshot" {
  type    = bool
  default = false
}

variable "sg_rds_ids" {
  type    = list(string)
  default = []
}

variable "elasticache_enabled" {
  type    = bool
  default = true
}

variable "elasticache_node_type" {
  type    = string
  default = "cache.r7g.large"
}

variable "elasticache_cluster_count" {
  type    = number
  default = 2
}

variable "sg_elasticache_ids" {
  type    = list(string)
  default = []
}

variable "dynamodb_tables" {
  type = map(object({
    hash_key     = string
    range_key    = optional(string)
    billing_mode = optional(string)
  }))
  default = {}
}

variable "s3_buckets" {
  type        = map(object({ versioning = optional(bool, false) }))
  default     = {}
  description = "Map of bucket suffix to config."
}

variable "tags" {
  type    = map(string)
  default = {}
}
