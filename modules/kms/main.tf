##
## Module: kms
## Creates a KMS customer-managed key with alias, key policy, and optional multi-region support.
##

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

locals {
  region_short = {
    "us-east-1" = "use1", "us-east-2" = "use2", "us-west-1" = "usw1", "us-west-2" = "usw2",
    "eu-west-1" = "euw1", "eu-west-2" = "euw2", "eu-central-1" = "euc1",
    "ap-southeast-1" = "apse1", "ap-southeast-2" = "apse2", "ap-northeast-1" = "apne1"
  }
  rs          = lookup(local.region_short, var.region, replace(var.region, "-", ""))
  name_prefix = "${var.project}-${var.environment}-${local.rs}"
  account_id  = data.aws_caller_identity.current.account_id
  partition   = data.aws_partition.current.partition

  default_tags = merge({
    Project     = var.project
    Environment = var.environment
    Region      = var.region
    ManagedBy   = "terraform"
  }, var.tags)

  # Root account always has full key access so Terraform can manage it
  admin_arns = length(var.admin_principal_arns) > 0 ? var.admin_principal_arns : ["arn:${local.partition}:iam::${local.account_id}:root"]
}

resource "aws_kms_key" "this" {
  description              = var.description
  deletion_window_in_days  = var.deletion_window_in_days
  enable_key_rotation      = var.enable_key_rotation
  multi_region             = var.multi_region
  tags                     = merge(local.default_tags, { Name = "${local.name_prefix}-kms-${var.alias}" })

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      # Root account full access (required so IAM can manage the key)
      [{
        Sid       = "EnableRootAccess"
        Effect    = "Allow"
        Principal = { AWS = "arn:${local.partition}:iam::${local.account_id}:root" }
        Action    = "kms:*"
        Resource  = "*"
      }],
      # Admin principals
      length(var.admin_principal_arns) > 0 ? [{
        Sid       = "KeyAdministration"
        Effect    = "Allow"
        Principal = { AWS = var.admin_principal_arns }
        Action    = ["kms:Create*", "kms:Describe*", "kms:Enable*", "kms:List*", "kms:Put*", "kms:Update*", "kms:Revoke*", "kms:Disable*", "kms:Get*", "kms:Delete*", "kms:TagResource", "kms:UntagResource", "kms:ScheduleKeyDeletion", "kms:CancelKeyDeletion"]
        Resource  = "*"
      }] : [],
      # Usage principals (IAM roles/users that encrypt/decrypt)
      length(var.usage_principal_arns) > 0 ? [{
        Sid       = "KeyUsage"
        Effect    = "Allow"
        Principal = { AWS = var.usage_principal_arns }
        Action    = ["kms:Encrypt", "kms:Decrypt", "kms:ReEncrypt*", "kms:GenerateDataKey*", "kms:DescribeKey"]
        Resource  = "*"
      }] : [],
      # Service principals (e.g. CloudWatch Logs, SNS)
      length(var.service_principals) > 0 ? [{
        Sid       = "ServiceUsage"
        Effect    = "Allow"
        Principal = { Service = var.service_principals }
        Action    = ["kms:Encrypt", "kms:Decrypt", "kms:ReEncrypt*", "kms:GenerateDataKey*", "kms:DescribeKey", "kms:CreateGrant", "kms:ListGrants", "kms:RevokeGrant"]
        Resource  = "*"
      }] : []
    )
  })
}

resource "aws_kms_alias" "this" {
  name          = "alias/${local.name_prefix}-${var.alias}"
  target_key_id = aws_kms_key.this.key_id
}
