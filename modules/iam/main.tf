##
## Module: iam
## Creates an IAM role with a configurable trust policy, managed policy
## attachments, inline policies, and optional permissions boundary.
##

locals {
  region_short = {
    "us-east-1" = "use1", "us-east-2" = "use2", "us-west-1" = "usw1", "us-west-2" = "usw2",
    "eu-west-1" = "euw1", "eu-west-2" = "euw2", "eu-central-1" = "euc1",
    "ap-southeast-1" = "apse1", "ap-southeast-2" = "apse2", "ap-northeast-1" = "apne1"
  }
  rs          = lookup(local.region_short, var.region, replace(var.region, "-", ""))
  name_prefix = "${var.project}-${var.environment}-${local.rs}"
  full_name   = "${local.name_prefix}-role-${var.role_name}"

  default_tags = merge({
    Project     = var.project
    Environment = var.environment
    Region      = var.region
    ManagedBy   = "terraform"
  }, var.tags)

  # Build trust policy statements
  service_statements = length(var.trusted_service_principals) > 0 ? [{
    Effect    = "Allow"
    Action    = "sts:AssumeRole"
    Principal = { Service = var.trusted_service_principals }
  }] : []

  role_statements = length(var.trusted_role_arns) > 0 ? [{
    Effect    = "Allow"
    Action    = "sts:AssumeRole"
    Principal = { AWS = var.trusted_role_arns }
  }] : []

  oidc_statements = var.trusted_oidc_provider_arn != null ? [{
    Effect = "Allow"
    Action = "sts:AssumeRoleWithWebIdentity"
    Principal = { Federated = var.trusted_oidc_provider_arn }
    Condition = length(var.oidc_subject_conditions) > 0 ? { StringLike = var.oidc_subject_conditions } : null
  }] : []
}

resource "aws_iam_role" "this" {
  name                  = local.full_name
  description           = var.role_description
  max_session_duration  = var.max_session_duration
  permissions_boundary  = var.permission_boundary_arn
  force_detach_policies = var.force_detach_policies

  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = concat(local.service_statements, local.role_statements, local.oidc_statements)
  })

  tags = merge(local.default_tags, { Name = local.full_name })
}

resource "aws_iam_role_policy_attachment" "managed" {
  for_each   = toset(var.managed_policy_arns)
  role       = aws_iam_role.this.name
  policy_arn = each.value
}

resource "aws_iam_role_policy" "inline" {
  for_each = var.inline_policies
  name     = each.key
  role     = aws_iam_role.this.id
  policy   = each.value
}

resource "aws_iam_instance_profile" "this" {
  count = contains(var.trusted_service_principals, "ec2.amazonaws.com") ? 1 : 0
  name  = local.full_name
  role  = aws_iam_role.this.name
  tags  = local.default_tags
}
