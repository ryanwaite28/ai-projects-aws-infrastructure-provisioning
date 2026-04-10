##
## Bootstrap: AWS Organizations + SCPs
##
## ONE-TIME. Run from the root/management account.
## Creates:
##   - AWS Organization (if not already created)
##   - Organizational Units: workloads/dev, workloads/qa, workloads/prod
##   - Service Control Policies (SCPs):
##       * DenyLeavingOrg     — prevents accounts from leaving the org
##       * DenyRootUser       — blocks root user activity in member accounts
##       * DenyPublicS3       — blocks public S3 bucket/ACL configuration
##       * RequireIMDSv2      — enforces IMDSv2 on EC2 instances
##   - SCP attachments to each OU
##
## After running, create/invite member accounts and move them into the OUs.
##

terraform {
  required_version = ">= 1.7.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = ">= 5.0" }
  }
  backend "local" {}
}

provider "aws" { region = var.region }

## ── Organization ──────────────────────────────────────────────────────────────
resource "aws_organizations_organization" "this" {
  aws_service_access_principals = [
    "cloudtrail.amazonaws.com",
    "config.amazonaws.com",
    "sso.amazonaws.com",
    "guardduty.amazonaws.com",
    "securityhub.amazonaws.com",
    "access-analyzer.amazonaws.com",
  ]
  feature_set          = "ALL"
  enabled_policy_types = ["SERVICE_CONTROL_POLICY"]
}

## ── Organizational Units ──────────────────────────────────────────────────────
resource "aws_organizations_organizational_unit" "workloads" {
  name      = "workloads"
  parent_id = aws_organizations_organization.this.roots[0].id
}

resource "aws_organizations_organizational_unit" "env" {
  for_each  = toset(["dev", "qa", "prod"])
  name      = each.key
  parent_id = aws_organizations_organizational_unit.workloads.id
}

## ── SCPs ──────────────────────────────────────────────────────────────────────
resource "aws_organizations_policy" "deny_leaving_org" {
  name        = "DenyLeavingOrg"
  description = "Prevent member accounts from leaving the organization"
  type        = "SERVICE_CONTROL_POLICY"
  content = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid      = "DenyLeaveOrg"
      Effect   = "Deny"
      Action   = "organizations:LeaveOrganization"
      Resource = "*"
    }]
  })
}

resource "aws_organizations_policy" "deny_root_user" {
  name        = "DenyRootUser"
  description = "Block all root user activity in member accounts"
  type        = "SERVICE_CONTROL_POLICY"
  content = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid      = "DenyRootUser"
      Effect   = "Deny"
      Action   = "*"
      Resource = "*"
      Condition = {
        StringLike = { "aws:PrincipalArn" = ["arn:aws:iam::*:root"] }
      }
    }]
  })
}

resource "aws_organizations_policy" "deny_public_s3" {
  name        = "DenyPublicS3"
  description = "Prevent disabling S3 Block Public Access or making buckets/objects public"
  type        = "SERVICE_CONTROL_POLICY"
  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyDisableBlockPublicAccess"
        Effect = "Deny"
        Action = [
          "s3:PutBucketPublicAccessBlock",
          "s3:DeletePublicAccessBlock"
        ]
        Resource = "*"
        Condition = {
          StringNotEquals = {
            "s3:ResourceAccount" = ["{{ exceptions_account_id }}"]
          }
        }
      },
      {
        Sid    = "DenyPublicACL"
        Effect = "Deny"
        Action = ["s3:PutBucketAcl", "s3:PutObjectAcl"]
        Resource = "*"
        Condition = {
          StringEqualsIgnoreCase = {
            "s3:x-amz-acl" = ["public-read", "public-read-write", "authenticated-read"]
          }
        }
      }
    ]
  })
}

resource "aws_organizations_policy" "require_imdsv2" {
  name        = "RequireIMDSv2"
  description = "Require IMDSv2 on all EC2 instance launches"
  type        = "SERVICE_CONTROL_POLICY"
  content = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "DenyIMDSv1"
      Effect = "Deny"
      Action = "ec2:RunInstances"
      Resource = "arn:aws:ec2:*:*:instance/*"
      Condition = {
        StringNotEquals = {
          "ec2:MetadataHttpTokens" = "required"
        }
      }
    }]
  })
}

## ── SCP Attachments ───────────────────────────────────────────────────────────
locals {
  root_scps = [
    aws_organizations_policy.deny_leaving_org.id,
    aws_organizations_policy.deny_root_user.id,
    aws_organizations_policy.deny_public_s3.id,
    aws_organizations_policy.require_imdsv2.id,
  ]
  env_ous = {
    for env in ["dev", "qa", "prod"] : env => aws_organizations_organizational_unit.env[env].id
  }
  # Attach all SCPs to all env OUs
  attachments = flatten([
    for env, ou_id in local.env_ous : [
      for scp_id in local.root_scps : {
        key    = "${env}-${scp_id}"
        ou_id  = ou_id
        scp_id = scp_id
      }
    ]
  ])
}

resource "aws_organizations_policy_attachment" "env_scps" {
  for_each  = { for a in local.attachments : a.key => a }
  policy_id = each.value.scp_id
  target_id = each.value.ou_id
}
