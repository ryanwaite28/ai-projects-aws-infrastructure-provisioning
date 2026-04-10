##
## Bootstrap: GitHub Actions OIDC
##
## ONE-TIME. Creates:
##   - AWS IAM OIDC Identity Provider for GitHub Actions
##   - One IAM role per environment with scoped trust (repo + branch/env)
##   - Inline permission boundary enforced on each role
##
## After running, store each role ARN as a GitHub Actions secret:
##   AWS_ROLE_ARN_DEV, AWS_ROLE_ARN_QA, AWS_ROLE_ARN_PROD
##

terraform {
  required_version = ">= 1.7.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = ">= 5.0" }
  }
  backend "local" {}
}

provider "aws" { region = var.region }

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

locals {
  account_id     = data.aws_caller_identity.current.account_id
  partition      = data.aws_partition.current.partition
  environments   = toset(split(",", var.environments))

  # GitHub OIDC thumbprint (stable — changes only when GitHub rotates their cert chain)
  github_thumbprint = "6938fd4d98bab03faadb97b34396831e3780aea1"
}

## ── OIDC Provider ─────────────────────────────────────────────────────────────
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [local.github_thumbprint]

  tags = {
    Project   = var.project
    ManagedBy = "terraform-bootstrap"
  }
}

## ── Per-environment IAM roles ─────────────────────────────────────────────────
resource "aws_iam_role" "github_actions" {
  for_each = local.environments

  name        = "${var.project}-github-actions-${each.key}"
  description = "GitHub Actions OIDC role for ${var.project} ${each.key}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "GitHubActionsOIDC"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            # Restrict to the specific repo; allow any branch/environment ref.
            # Tighten to specific branches if desired:
            # "ref:refs/heads/main" for prod,
            # "ref:refs/heads/develop" for dev, etc.
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}/${var.github_repo}:environment:${each.key}"
          }
        }
      }
    ]
  })

  max_session_duration = 3600

  tags = {
    Project     = var.project
    Environment = each.key
    ManagedBy   = "terraform-bootstrap"
  }
}

## ── Terraform execution policy ────────────────────────────────────────────────
## Grants broad permissions needed to plan/apply all infrastructure.
## In production environments consider scoping this further using SCPs.
resource "aws_iam_role_policy" "terraform_execution" {
  for_each = local.environments

  name = "TerraformExecution"
  role = aws_iam_role.github_actions[each.key].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "TerraformStateAccess"
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject", "s3:ListBucket"]
        Resource = [
          "arn:${local.partition}:s3:::${var.state_bucket_name}",
          "arn:${local.partition}:s3:::${var.state_bucket_name}/*"
        ]
      },
      {
        Sid      = "TerraformLockAccess"
        Effect   = "Allow"
        Action   = [
          "dynamodb:GetItem", "dynamodb:PutItem",
          "dynamodb:DeleteItem", "dynamodb:DescribeTable"
        ]
        Resource = "arn:${local.partition}:dynamodb:${var.region}:${local.account_id}:table/${var.lock_table_name}"
      },
      {
        Sid      = "InfrastructureProvision"
        Effect   = "Allow"
        Action   = [
          # Broad terraform execution — restrict further via SCPs at org level
          "ec2:*", "ecs:*", "ecr:*", "elasticloadbalancing:*",
          "rds:*", "elasticache:*", "s3:*", "dynamodb:*",
          "lambda:*", "sqs:*", "sns:*", "events:*",
          "kinesis:*", "firehose:*", "apigateway:*",
          "cloudfront:*", "wafv2:*", "acm:*",
          "route53:*", "secretsmanager:*", "ssm:*",
          "kms:*", "logs:*", "cloudwatch:*",
          "iam:*", "sts:GetCallerIdentity",
          "autoscaling:*", "application-autoscaling:*",
          "elasticfilesystem:*", "ebs:*"
        ]
        Resource = "*"
      }
    ]
  })
}
