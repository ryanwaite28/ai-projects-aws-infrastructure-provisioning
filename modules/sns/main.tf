##
## Module: sns
## Creates an SNS topic with subscriptions and access policy.
##

locals {
  region_short = {
    "us-east-1" = "use1", "us-east-2" = "use2", "us-west-1" = "usw1", "us-west-2" = "usw2",
    "eu-west-1" = "euw1", "eu-west-2" = "euw2", "eu-central-1" = "euc1",
    "ap-southeast-1" = "apse1", "ap-southeast-2" = "apse2", "ap-northeast-1" = "apne1"
  }
  rs         = lookup(local.region_short, var.region, replace(var.region, "-", ""))
  name_base  = "${var.project}-${var.environment}-${local.rs}-${var.topic_name}"
  topic_name = var.fifo ? "${local.name_base}.fifo" : local.name_base

  default_tags = merge({
    Project = var.project, Environment = var.environment, Region = var.region, ManagedBy = "terraform"
  }, var.tags)
}

data "aws_caller_identity" "current" {}

resource "aws_sns_topic" "this" {
  name                        = local.topic_name
  fifo_topic                  = var.fifo
  content_based_deduplication = var.fifo && var.content_based_deduplication
  kms_master_key_id           = var.kms_key_arn
  tags                        = merge(local.default_tags, { Name = local.topic_name })
}

resource "aws_sns_topic_policy" "this" {
  count = length(var.allowed_publisher_arns) > 0 || length(var.allowed_service_principals) > 0 || length(var.topic_policy_statements) > 0 ? 1 : 0
  arn   = aws_sns_topic.this.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [{
        Sid    = "OwnerAccess"
        Effect = "Allow"
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
        Action   = "SNS:*"
        Resource = aws_sns_topic.this.arn
      }],
      length(var.allowed_publisher_arns) > 0 ? [{
        Sid      = "AllowPublish"
        Effect   = "Allow"
        Principal = { AWS = var.allowed_publisher_arns }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.this.arn
      }] : [],
      length(var.allowed_service_principals) > 0 ? [{
        Sid      = "AllowServicePublish"
        Effect   = "Allow"
        Principal = { Service = var.allowed_service_principals }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.this.arn
      }] : [],
      var.topic_policy_statements
    )
  })
}

resource "aws_sns_topic_subscription" "this" {
  count     = length(var.subscriptions)
  topic_arn = aws_sns_topic.this.arn
  protocol  = var.subscriptions[count.index].protocol
  endpoint  = var.subscriptions[count.index].endpoint

  filter_policy        = var.subscriptions[count.index].filter_policy
  raw_message_delivery = var.subscriptions[count.index].raw_message_delivery

  dynamic "redrive_policy" {
    for_each = var.subscriptions[count.index].redrive_policy_dlq_arn != null ? [1] : []
    content {
      deadLetterTargetArn = var.subscriptions[count.index].redrive_policy_dlq_arn
    }
  }
}
