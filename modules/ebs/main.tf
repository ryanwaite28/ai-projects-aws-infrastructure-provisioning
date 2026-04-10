##
## Module: ebs
## Creates an encrypted EBS volume with configurable type, IOPS, and throughput.
##

locals {
  region_short = {
    "us-east-1" = "use1", "us-east-2" = "use2", "us-west-1" = "usw1", "us-west-2" = "usw2",
    "eu-west-1" = "euw1", "eu-west-2" = "euw2", "eu-central-1" = "euc1",
    "ap-southeast-1" = "apse1", "ap-southeast-2" = "apse2", "ap-northeast-1" = "apne1"
  }
  rs          = lookup(local.region_short, var.region, replace(var.region, "-", ""))
  volume_name = "${var.project}-${var.environment}-${local.rs}-ebs-${var.volume_name}"

  default_tags = merge({
    Project = var.project, Environment = var.environment, Region = var.region, ManagedBy = "terraform"
  }, var.tags)
}

resource "aws_ebs_volume" "this" {
  availability_zone    = var.availability_zone
  size                 = var.size_gb
  type                 = var.volume_type
  iops                 = var.iops
  throughput           = var.throughput
  encrypted            = true
  kms_key_id           = var.kms_key_arn
  snapshot_id          = var.snapshot_id
  multi_attach_enabled = var.multi_attach_enabled
  tags                 = merge(local.default_tags, { Name = local.volume_name })
}
