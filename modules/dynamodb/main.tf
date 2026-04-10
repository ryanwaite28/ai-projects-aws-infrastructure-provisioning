##
## Module: dynamodb
## Creates a DynamoDB table with optional GSIs, TTL, PITR, streams,
## and Global Table replicas.
##

locals {
  region_short = {
    "us-east-1" = "use1", "us-east-2" = "use2", "us-west-1" = "usw1", "us-west-2" = "usw2",
    "eu-west-1" = "euw1", "eu-west-2" = "euw2", "eu-central-1" = "euc1",
    "ap-southeast-1" = "apse1", "ap-southeast-2" = "apse2", "ap-northeast-1" = "apne1"
  }
  rs         = lookup(local.region_short, var.region, replace(var.region, "-", ""))
  table_name = "${var.project}-${var.environment}-${local.rs}-${var.table_name}"

  default_tags = merge({
    Project = var.project, Environment = var.environment, Region = var.region, ManagedBy = "terraform"
  }, var.tags)

  all_attributes = concat(
    [{ name = var.hash_key, type = var.hash_key_type }],
    var.range_key != null ? [{ name = var.range_key, type = var.range_key_type }] : [],
    var.attributes
  )
  # Deduplicate attribute definitions (GSI keys may overlap with table keys)
  unique_attributes = { for a in local.all_attributes : a.name => a }
}

resource "aws_dynamodb_table" "this" {
  name             = local.table_name
  billing_mode     = var.billing_mode
  read_capacity    = var.billing_mode == "PROVISIONED" ? var.read_capacity : null
  write_capacity   = var.billing_mode == "PROVISIONED" ? var.write_capacity : null
  hash_key         = var.hash_key
  range_key        = var.range_key
  stream_enabled   = var.stream_enabled
  stream_view_type = var.stream_enabled ? var.stream_view_type : null
  deletion_protection_enabled = var.deletion_protection

  dynamic "attribute" {
    for_each = local.unique_attributes
    content {
      name = attribute.value.name
      type = attribute.value.type
    }
  }

  dynamic "ttl" {
    for_each = var.ttl_attribute != null ? [1] : []
    content {
      attribute_name = var.ttl_attribute
      enabled        = true
    }
  }

  point_in_time_recovery {
    enabled = var.point_in_time_recovery
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = var.kms_key_arn
  }

  dynamic "global_secondary_index" {
    for_each = var.global_secondary_indexes
    content {
      name               = global_secondary_index.value.name
      hash_key           = global_secondary_index.value.hash_key
      range_key          = global_secondary_index.value.range_key
      projection_type    = global_secondary_index.value.projection_type
      non_key_attributes = global_secondary_index.value.projection_type == "INCLUDE" ? global_secondary_index.value.non_key_attributes : null
      read_capacity      = var.billing_mode == "PROVISIONED" ? global_secondary_index.value.read_capacity : null
      write_capacity     = var.billing_mode == "PROVISIONED" ? global_secondary_index.value.write_capacity : null
    }
  }

  dynamic "replica" {
    for_each = var.replica_regions
    content {
      region_name = replica.value
    }
  }

  tags = merge(local.default_tags, { Name = local.table_name })
}
