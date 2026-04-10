##
## Module: firehose
## Creates a Kinesis Data Firehose delivery stream to S3 with optional
## Lambda transformation and dynamic partitioning.
##

locals {
  region_short = {
    "us-east-1" = "use1", "us-east-2" = "use2", "us-west-1" = "usw1", "us-west-2" = "usw2",
    "eu-west-1" = "euw1", "eu-west-2" = "euw2", "eu-central-1" = "euc1",
    "ap-southeast-1" = "apse1", "ap-southeast-2" = "apse2", "ap-northeast-1" = "apne1"
  }
  rs          = lookup(local.region_short, var.region, replace(var.region, "-", ""))
  stream_name = "${var.project}-${var.environment}-${local.rs}-firehose-${var.stream_name}"
  log_group   = "/aws/kinesisfirehose/${local.stream_name}"

  default_tags = merge({
    Project = var.project, Environment = var.environment, Region = var.region, ManagedBy = "terraform"
  }, var.tags)
}

data "aws_caller_identity" "current" {}

resource "aws_cloudwatch_log_group" "firehose" {
  count             = var.cloudwatch_logging_enabled ? 1 : 0
  name              = local.log_group
  retention_in_days = 14
  tags              = local.default_tags
}

resource "aws_cloudwatch_log_stream" "s3_delivery" {
  count          = var.cloudwatch_logging_enabled ? 1 : 0
  name           = "S3Delivery"
  log_group_name = aws_cloudwatch_log_group.firehose[0].name
}

resource "aws_iam_role" "firehose" {
  name = "${local.stream_name}-firehose-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "firehose.amazonaws.com" }
      Condition = { StringEquals = { "sts:ExternalId" = data.aws_caller_identity.current.account_id } }
    }]
  })

  tags = local.default_tags
}

resource "aws_iam_role_policy" "firehose" {
  name = "firehose-delivery"
  role = aws_iam_role.firehose.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat([
      {
        Effect   = "Allow"
        Action   = ["s3:AbortMultipartUpload", "s3:GetBucketLocation", "s3:GetObject", "s3:ListBucket", "s3:ListBucketMultipartUploads", "s3:PutObject"]
        Resource = [var.s3_bucket_arn, "${var.s3_bucket_arn}/*"]
      },
      {
        Effect   = "Allow"
        Action   = ["logs:PutLogEvents"]
        Resource = "*"
      }
    ],
    var.source_kinesis_stream_arn != null ? [{
      Effect   = "Allow"
      Action   = ["kinesis:DescribeStream", "kinesis:GetShardIterator", "kinesis:GetRecords", "kinesis:ListShards"]
      Resource = var.source_kinesis_stream_arn
    }] : [],
    var.transformation_lambda_arn != null ? [{
      Effect   = "Allow"
      Action   = ["lambda:InvokeFunction", "lambda:GetFunctionConfiguration"]
      Resource = var.transformation_lambda_arn
    }] : [],
    var.kms_key_arn != null ? [{
      Effect   = "Allow"
      Action   = ["kms:Decrypt", "kms:GenerateDataKey"]
      Resource = var.kms_key_arn
    }] : [])
  })
}

resource "aws_kinesis_firehose_delivery_stream" "this" {
  name        = local.stream_name
  destination = "extended_s3"

  dynamic "kinesis_source_configuration" {
    for_each = var.source_kinesis_stream_arn != null ? [1] : []
    content {
      kinesis_stream_arn = var.source_kinesis_stream_arn
      role_arn           = aws_iam_role.firehose.arn
    }
  }

  extended_s3_configuration {
    role_arn            = aws_iam_role.firehose.arn
    bucket_arn          = var.s3_bucket_arn
    prefix              = var.s3_prefix
    error_output_prefix = var.s3_error_prefix
    buffering_size      = var.buffering_size_mb
    buffering_interval  = var.buffering_interval_seconds
    compression_format  = var.s3_compression_format

    dynamic_partitioning_configuration {
      enabled        = var.dynamic_partitioning_enabled
      retry_duration = 300
    }

    dynamic "processing_configuration" {
      for_each = var.transformation_lambda_arn != null ? [1] : []
      content {
        enabled = true
        processors {
          type = "Lambda"
          parameters {
            parameter_name  = "LambdaArn"
            parameter_value = var.transformation_lambda_arn
          }
          parameters {
            parameter_name  = "BufferSizeInMBs"
            parameter_value = var.transformation_buffer_size_mb
          }
          parameters {
            parameter_name  = "BufferIntervalInSeconds"
            parameter_value = var.transformation_buffer_interval_seconds
          }
        }
      }
    }

    dynamic "cloudwatch_logging_options" {
      for_each = var.cloudwatch_logging_enabled ? [1] : []
      content {
        enabled         = true
        log_group_name  = aws_cloudwatch_log_group.firehose[0].name
        log_stream_name = aws_cloudwatch_log_stream.s3_delivery[0].name
      }
    }
  }

  tags = merge(local.default_tags, { Name = local.stream_name })
}
