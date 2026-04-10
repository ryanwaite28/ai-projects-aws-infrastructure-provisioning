##
## Module: elasticache
## Creates an ElastiCache Redis replication group with Multi-AZ,
## subnet group, and optional log delivery.
##

locals {
  region_short = {
    "us-east-1" = "use1", "us-east-2" = "use2", "us-west-1" = "usw1", "us-west-2" = "usw2",
    "eu-west-1" = "euw1", "eu-west-2" = "euw2", "eu-central-1" = "euc1",
    "ap-southeast-1" = "apse1", "ap-southeast-2" = "apse2", "ap-northeast-1" = "apne1"
  }
  rs         = lookup(local.region_short, var.region, replace(var.region, "-", ""))
  name_base  = "${var.project}-${var.environment}-${local.rs}-redis-${var.cluster_id}"

  default_tags = merge({
    Project = var.project, Environment = var.environment, Region = var.region, ManagedBy = "terraform"
  }, var.tags)
}

data "aws_secretsmanager_secret_version" "auth" {
  count     = var.auth_token_secret_arn != null ? 1 : 0
  secret_id = var.auth_token_secret_arn
}

resource "aws_elasticache_subnet_group" "this" {
  name       = "${local.name_base}-subnet-group"
  subnet_ids = var.subnet_ids
  tags       = merge(local.default_tags, { Name = "${local.name_base}-subnet-group" })
}

resource "aws_elasticache_replication_group" "this" {
  replication_group_id        = local.name_base
  description                 = "${var.project} ${var.environment} Redis cluster"
  node_type                   = var.node_type
  engine_version              = var.engine_version
  num_cache_clusters          = var.num_cache_clusters
  automatic_failover_enabled  = var.automatic_failover_enabled
  multi_az_enabled            = var.multi_az_enabled
  subnet_group_name           = aws_elasticache_subnet_group.this.name
  security_group_ids          = var.security_group_ids
  port                        = var.port
  at_rest_encryption_enabled  = var.at_rest_encryption_enabled
  transit_encryption_enabled  = var.transit_encryption_enabled
  kms_key_id                  = var.kms_key_arn
  auth_token                  = var.auth_token_secret_arn != null ? data.aws_secretsmanager_secret_version.auth[0].secret_string : null
  snapshot_retention_limit    = var.snapshot_retention_limit
  snapshot_window             = var.snapshot_window
  maintenance_window          = var.maintenance_window

  dynamic "log_delivery_configuration" {
    for_each = var.log_delivery_configurations
    content {
      log_type         = log_delivery_configuration.value.log_type
      destination      = log_delivery_configuration.value.destination
      destination_type = log_delivery_configuration.value.destination_type
      log_format       = log_delivery_configuration.value.log_format
    }
  }

  tags = merge(local.default_tags, { Name = local.name_base })
}
