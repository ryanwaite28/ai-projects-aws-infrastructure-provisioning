##
## Module: lambda
## Creates a Lambda function with execution role, CloudWatch log group,
## optional VPC config, and SQS event source mappings.
##

locals {
  region_short = {
    "us-east-1" = "use1", "us-east-2" = "use2", "us-west-1" = "usw1", "us-west-2" = "usw2",
    "eu-west-1" = "euw1", "eu-west-2" = "euw2", "eu-central-1" = "euc1",
    "ap-southeast-1" = "apse1", "ap-southeast-2" = "apse2", "ap-northeast-1" = "apne1"
  }
  rs            = lookup(local.region_short, var.region, replace(var.region, "-", ""))
  name_prefix   = "${var.project}-${var.environment}-${local.rs}"
  function_name = "${local.name_prefix}-fn-${var.function_name}"
  create_role   = var.execution_role_arn == null

  default_tags = merge({
    Project = var.project, Environment = var.environment, Region = var.region, ManagedBy = "terraform"
  }, var.tags)
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/${local.function_name}"
  retention_in_days = var.log_retention_days
  tags              = local.default_tags
}

resource "aws_iam_role" "execution" {
  count = local.create_role ? 1 : 0
  name  = "${local.function_name}-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })

  tags = local.default_tags
}

resource "aws_iam_role_policy_attachment" "basic_execution" {
  count      = local.create_role ? 1 : 0
  role       = aws_iam_role.execution[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "vpc_access" {
  count      = local.create_role && var.vpc_config != null ? 1 : 0
  role       = aws_iam_role.execution[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy_attachment" "sqs_access" {
  count      = local.create_role && length(var.sqs_event_source_arns) > 0 ? 1 : 0
  role       = aws_iam_role.execution[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole"
}

resource "aws_iam_role_policy" "extra" {
  for_each = local.create_role ? var.execution_role_extra_policies : {}
  name     = each.key
  role     = aws_iam_role.execution[0].id
  policy   = each.value
}

resource "aws_lambda_function" "this" {
  function_name                  = local.function_name
  description                    = var.description
  role                           = local.create_role ? aws_iam_role.execution[0].arn : var.execution_role_arn
  package_type                   = var.package_type
  runtime                        = var.package_type == "Zip" ? var.runtime : null
  handler                        = var.package_type == "Zip" ? var.handler : null
  filename                       = var.filename
  s3_bucket                      = var.s3_bucket
  s3_key                         = var.s3_key
  image_uri                      = var.image_uri
  memory_size                    = var.memory_size
  timeout                        = var.timeout
  reserved_concurrent_executions = var.reserved_concurrent_executions
  layers                         = var.layers
  architectures                  = var.architectures
  publish                        = var.publish_version
  kms_key_arn                    = var.kms_key_arn

  dynamic "environment" {
    for_each = length(var.environment_variables) > 0 ? [1] : []
    content {
      variables = var.environment_variables
    }
  }

  dynamic "vpc_config" {
    for_each = var.vpc_config != null ? [var.vpc_config] : []
    content {
      subnet_ids         = vpc_config.value.subnet_ids
      security_group_ids = vpc_config.value.security_group_ids
    }
  }

  tags       = merge(local.default_tags, { Name = local.function_name })
  depends_on = [aws_cloudwatch_log_group.this]
}

resource "aws_lambda_event_source_mapping" "sqs" {
  count                            = length(var.sqs_event_source_arns)
  event_source_arn                 = var.sqs_event_source_arns[count.index]
  function_name                    = aws_lambda_function.this.arn
  batch_size                       = var.sqs_batch_size
  maximum_batching_window_in_seconds = var.sqs_maximum_batching_window_seconds
  enabled                          = true
}
