##
## Module: sqs
## Creates an SQS queue (standard or FIFO) with optional DLQ,
## encryption, and publisher policy.
##

locals {
  region_short = {
    "us-east-1" = "use1", "us-east-2" = "use2", "us-west-1" = "usw1", "us-west-2" = "usw2",
    "eu-west-1" = "euw1", "eu-west-2" = "euw2", "eu-central-1" = "euc1",
    "ap-southeast-1" = "apse1", "ap-southeast-2" = "apse2", "ap-northeast-1" = "apne1"
  }
  rs          = lookup(local.region_short, var.region, replace(var.region, "-", ""))
  name_base   = "${var.project}-${var.environment}-${local.rs}-${var.queue_name}"
  queue_name  = var.fifo ? "${local.name_base}.fifo" : local.name_base
  dlq_name    = var.fifo ? "${local.name_base}-dlq.fifo" : "${local.name_base}-dlq"

  default_tags = merge({
    Project = var.project, Environment = var.environment, Region = var.region, ManagedBy = "terraform"
  }, var.tags)
}

resource "aws_sqs_queue" "dlq" {
  count                       = var.dlq_enabled ? 1 : 0
  name                        = local.dlq_name
  fifo_queue                  = var.fifo
  content_based_deduplication = var.fifo && var.content_based_deduplication
  message_retention_seconds   = 1209600 # 14 days — max for DLQ
  kms_master_key_id           = var.kms_key_arn
  tags                        = merge(local.default_tags, { Name = local.dlq_name, QueueType = "dlq" })
}

resource "aws_sqs_queue" "this" {
  name                        = local.queue_name
  fifo_queue                  = var.fifo
  content_based_deduplication = var.fifo && var.content_based_deduplication
  visibility_timeout_seconds  = var.visibility_timeout_seconds
  message_retention_seconds   = var.message_retention_seconds
  max_message_size            = var.max_message_size
  delay_seconds               = var.delay_seconds
  receive_wait_time_seconds   = var.receive_wait_time_seconds
  kms_master_key_id           = var.kms_key_arn

  dynamic "redrive_policy" {
    for_each = var.dlq_enabled ? [1] : []
    content {
      dead_letter_target_arn = aws_sqs_queue.dlq[0].arn
      maxReceiveCount        = var.max_receive_count
    }
  }

  tags = merge(local.default_tags, { Name = local.queue_name })
}

resource "aws_sqs_queue_policy" "this" {
  count     = length(var.allowed_publisher_arns) > 0 || var.queue_policy_json != null ? 1 : 0
  queue_url = aws_sqs_queue.this.id

  policy = var.queue_policy_json != null ? var.queue_policy_json : jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowPublish"
      Effect    = "Allow"
      Principal = { AWS = var.allowed_publisher_arns }
      Action    = "sqs:SendMessage"
      Resource  = aws_sqs_queue.this.arn
    }]
  })
}
