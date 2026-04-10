##
## Module: rds
## Creates an Aurora cluster (PostgreSQL/MySQL) with optional Serverless v2,
## DB subnet group, parameter group, and Enhanced Monitoring role.
##

locals {
  region_short = {
    "us-east-1" = "use1", "us-east-2" = "use2", "us-west-1" = "usw1", "us-west-2" = "usw2",
    "eu-west-1" = "euw1", "eu-west-2" = "euw2", "eu-central-1" = "euc1",
    "ap-southeast-1" = "apse1", "ap-southeast-2" = "apse2", "ap-northeast-1" = "apne1"
  }
  rs          = lookup(local.region_short, var.region, replace(var.region, "-", ""))
  name_prefix = "${var.project}-${var.environment}-${local.rs}"
  cluster_id  = "${local.name_prefix}-${var.cluster_identifier}"
  port        = startswith(var.engine, "postgres") || startswith(var.engine, "aurora-postgres") ? 5432 : 3306

  manage_password = var.master_password_secret_arn == null

  default_tags = merge({
    Project = var.project, Environment = var.environment, Region = var.region, ManagedBy = "terraform"
  }, var.tags)
}

resource "aws_db_subnet_group" "this" {
  name       = "${local.cluster_id}-subnet-group"
  subnet_ids = var.subnet_ids
  tags       = merge(local.default_tags, { Name = "${local.cluster_id}-subnet-group" })
}

resource "aws_iam_role" "monitoring" {
  count = var.monitoring_interval > 0 ? 1 : 0
  name  = "${local.cluster_id}-rds-monitoring-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Effect = "Allow", Action = "sts:AssumeRole", Principal = { Service = "monitoring.rds.amazonaws.com" } }]
  })
  tags = local.default_tags
}

resource "aws_iam_role_policy_attachment" "monitoring" {
  count      = var.monitoring_interval > 0 ? 1 : 0
  role       = aws_iam_role.monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

resource "aws_rds_cluster" "this" {
  cluster_identifier              = local.cluster_id
  engine                          = var.engine
  engine_version                  = var.engine_version
  database_name                   = var.database_name
  master_username                 = var.master_username
  manage_master_user_password     = local.manage_password
  master_user_secret_kms_key_id   = local.manage_password ? var.kms_key_arn : null
  db_subnet_group_name            = aws_db_subnet_group.this.name
  vpc_security_group_ids          = var.vpc_security_group_ids
  backup_retention_period         = var.backup_retention_period
  preferred_backup_window         = var.preferred_backup_window
  preferred_maintenance_window    = var.preferred_maintenance_window
  deletion_protection             = var.deletion_protection
  skip_final_snapshot             = var.skip_final_snapshot
  final_snapshot_identifier       = var.skip_final_snapshot ? null : "${local.cluster_id}-final"
  storage_encrypted               = true
  kms_key_id                      = var.kms_key_arn
  apply_immediately               = var.apply_immediately
  port                            = local.port

  dynamic "serverlessv2_scaling_configuration" {
    for_each = var.serverless_v2 ? [1] : []
    content {
      min_capacity = var.serverless_min_acu
      max_capacity = var.serverless_max_acu
    }
  }

  tags = merge(local.default_tags, { Name = local.cluster_id })
}

resource "aws_rds_cluster_instance" "this" {
  count                        = var.instance_count
  identifier                   = "${local.cluster_id}-instance-${count.index + 1}"
  cluster_identifier           = aws_rds_cluster.this.id
  engine                       = aws_rds_cluster.this.engine
  engine_version               = aws_rds_cluster.this.engine_version
  instance_class               = var.serverless_v2 ? "db.serverless" : var.instance_class
  db_subnet_group_name         = aws_db_subnet_group.this.name
  performance_insights_enabled = var.performance_insights_enabled
  performance_insights_kms_key_id = var.performance_insights_enabled ? var.kms_key_arn : null
  monitoring_interval          = var.monitoring_interval
  monitoring_role_arn          = var.monitoring_interval > 0 ? aws_iam_role.monitoring[0].arn : null
  apply_immediately            = var.apply_immediately
  promotion_tier               = count.index == 0 ? 1 : 2

  tags = merge(local.default_tags, { Name = "${local.cluster_id}-instance-${count.index + 1}" })
}
