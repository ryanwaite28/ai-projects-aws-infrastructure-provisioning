##
## Module: kinesis
## Creates a Kinesis Data Stream with optional enhanced fan-out consumers.
##

locals {
  region_short = {
    "us-east-1" = "use1", "us-east-2" = "use2", "us-west-1" = "usw1", "us-west-2" = "usw2",
    "eu-west-1" = "euw1", "eu-west-2" = "euw2", "eu-central-1" = "euc1",
    "ap-southeast-1" = "apse1", "ap-southeast-2" = "apse2", "ap-northeast-1" = "apne1"
  }
  rs          = lookup(local.region_short, var.region, replace(var.region, "-", ""))
  stream_name = "${var.project}-${var.environment}-${local.rs}-kinesis-${var.stream_name}"

  default_tags = merge({
    Project = var.project, Environment = var.environment, Region = var.region, ManagedBy = "terraform"
  }, var.tags)
}

resource "aws_kinesis_stream" "this" {
  name             = local.stream_name
  shard_count      = var.on_demand ? null : var.shard_count
  retention_period = var.retention_period_hours

  stream_mode_details {
    stream_mode = var.on_demand ? "ON_DEMAND" : "PROVISIONED"
  }

  dynamic "encryption_type" {
    for_each = var.kms_key_arn != null ? [1] : []
    content {}
  }

  encryption_type = var.kms_key_arn != null ? "KMS" : "NONE"
  kms_key_id      = var.kms_key_arn

  shard_level_metrics = var.shard_level_metrics

  tags = merge(local.default_tags, { Name = local.stream_name })
}

resource "aws_kinesis_stream_consumer" "this" {
  for_each   = toset(var.enhanced_fan_out_consumers)
  name       = "${local.stream_name}-consumer-${each.key}"
  stream_arn = aws_kinesis_stream.this.arn
}
