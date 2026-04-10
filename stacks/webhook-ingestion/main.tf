##
## Stack: webhook-ingestion
##
## Architecture:
##
##   Internet
##     │
##     ▼  POST /webhooks  (REST API v1, regional)
##   API Gateway ──────────────────────────────── returns HTTP 200 immediately
##     │  AWS service integration (no Lambda in hot path)
##     │  IAM role allows sqs:SendMessage on this queue
##     ▼
##   SQS Standard Queue   ◄── DLQ after dlq_max_receive_count failures
##     │
##     ▼  Event source mapping (batch)
##   Processor Lambda   ◄── application project deploys handler code here
##
## Why REST API v1 (not HTTP API v2):
##   HTTP API v2 only supports Lambda and HTTP proxy integrations.
##   REST API v1 supports AWS service integrations, enabling APIGW to call
##   SQS directly without a Lambda in the hot path.
##

terraform {
  required_version = ">= 1.7.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = ">= 5.0" }
  }
}

provider "aws" { region = var.region }

data "aws_caller_identity" "current" {}

locals {
  region_short = {
    "us-east-1" = "use1", "us-east-2" = "use2", "us-west-1" = "usw1", "us-west-2" = "usw2",
    "eu-west-1" = "euw1", "eu-west-2" = "euw2", "eu-central-1" = "euc1",
    "ap-southeast-1" = "apse1", "ap-southeast-2" = "apse2", "ap-northeast-1" = "apne1"
  }
  rs          = lookup(local.region_short, var.region, replace(var.region, "-", ""))
  name_prefix = "${var.project}-${var.environment}-${local.rs}"

  tags = merge(
    {
      Project     = var.project
      Environment = var.environment
      Region      = var.region
      ManagedBy   = "terraform"
    },
    var.tags
  )
}

# ── SQS Queue ─────────────────────────────────────────────────────────────────

module "sqs" {
  source      = "../../modules/sqs"
  project     = var.project
  environment = var.environment
  region      = var.region

  queue_name                 = "${var.name}-webhooks"
  fifo                       = false # standard queue: higher throughput, no MessageGroupId required
  visibility_timeout_seconds = var.sqs_visibility_timeout_seconds
  message_retention_seconds  = var.sqs_message_retention_seconds
  kms_key_arn                = var.kms_key_arn
  dlq_enabled                = true
  max_receive_count          = var.dlq_max_receive_count
  tags                       = local.tags
}

# ── IAM: allow API Gateway to SendMessage to the queue ────────────────────────

resource "aws_iam_role" "apigw_sqs" {
  name        = "${local.name_prefix}-role-apigw-${var.name}-sqs"
  description = "Allows API Gateway to send messages to the ${var.name} webhook SQS queue."
  tags        = local.tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "apigateway.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "apigw_sqs" {
  name = "SendToSQS"
  role = aws_iam_role.apigw_sqs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [{
        Sid      = "SendMessage"
        Effect   = "Allow"
        Action   = ["sqs:SendMessage"]
        Resource = module.sqs.queue_arn
      }],
      # KMS permissions required when the queue uses a customer-managed key
      var.kms_key_arn != null ? [{
        Sid      = "KMSForSQS"
        Effect   = "Allow"
        Action   = ["kms:GenerateDataKey", "kms:Decrypt"]
        Resource = var.kms_key_arn
      }] : []
    )
  })
}

# ── REST API ──────────────────────────────────────────────────────────────────

resource "aws_api_gateway_rest_api" "this" {
  name        = "${local.name_prefix}-apigw-${var.name}"
  description = "Webhook ingestion endpoint for ${var.name}. Proxies to SQS; no Lambda in hot path."
  tags        = local.tags

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# /webhooks resource
resource "aws_api_gateway_resource" "webhooks" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = "webhooks"
}

# POST /webhooks
resource "aws_api_gateway_method" "post" {
  rest_api_id      = aws_api_gateway_rest_api.this.id
  resource_id      = aws_api_gateway_resource.webhooks.id
  http_method      = "POST"
  authorization    = "NONE"
  api_key_required = var.api_key_required
}

# AWS service integration: POST → SQS SendMessage
resource "aws_api_gateway_integration" "sqs" {
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.webhooks.id
  http_method             = aws_api_gateway_method.post.http_method
  integration_http_method = "POST"
  type                    = "AWS"
  credentials             = aws_iam_role.apigw_sqs.arn
  uri                     = "arn:aws:apigateway:${var.region}:sqs:path/${data.aws_caller_identity.current.account_id}/${module.sqs.queue_name}"

  # SQS expects application/x-www-form-urlencoded
  request_parameters = {
    "integration.request.header.Content-Type" = "'application/x-www-form-urlencoded'"
  }

  # Encode the raw request body as the SQS MessageBody.
  # The processor Lambda receives this as event["body"].
  request_templates = {
    "application/json" = "Action=SendMessage&MessageBody=$util.urlEncode($input.body)"
  }
}

# Method response: 200 OK
resource "aws_api_gateway_method_response" "ok" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.webhooks.id
  http_method = aws_api_gateway_method.post.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }
}

# Integration response: map SQS 200 → API 200
resource "aws_api_gateway_integration_response" "ok" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.webhooks.id
  http_method = aws_api_gateway_method.post.http_method
  status_code = aws_api_gateway_method_response.ok.status_code

  response_templates = {
    "application/json" = "{\"message\":\"Accepted\"}"
  }

  depends_on = [aws_api_gateway_integration.sqs]
}

# ── Deployment & Stage ────────────────────────────────────────────────────────

resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id

  # Redeploy whenever the API definition changes
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.webhooks,
      aws_api_gateway_method.post,
      aws_api_gateway_integration.sqs,
      aws_api_gateway_integration_response.ok,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_cloudwatch_log_group" "access_logs" {
  name              = "/aws/apigateway/${local.name_prefix}-${var.name}"
  retention_in_days = var.log_retention_days
  tags              = local.tags
}

resource "aws_api_gateway_stage" "this" {
  deployment_id = aws_api_gateway_deployment.this.id
  rest_api_id   = aws_api_gateway_rest_api.this.id
  stage_name    = var.stage_name
  tags          = local.tags

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.access_logs.arn
    format = jsonencode({
      requestId        = "$context.requestId"
      sourceIp         = "$context.identity.sourceIp"
      requestTime      = "$context.requestTime"
      httpMethod       = "$context.httpMethod"
      resourcePath     = "$context.resourcePath"
      status           = "$context.status"
      responseLength   = "$context.responseLength"
      integrationError = "$context.integrationErrorMessage"
    })
  }
}

resource "aws_api_gateway_method_settings" "throttle" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  stage_name  = aws_api_gateway_stage.this.stage_name
  method_path = "*/*"

  settings {
    throttling_rate_limit  = var.throttling_rate_limit
    throttling_burst_limit = var.throttling_burst_limit
    logging_level          = "ERROR"
    metrics_enabled        = true
  }
}

# ── WAF (optional) ────────────────────────────────────────────────────────────

resource "aws_wafv2_web_acl_association" "this" {
  count        = var.waf_acl_arn != null ? 1 : 0
  resource_arn = aws_api_gateway_stage.this.arn
  web_acl_arn  = var.waf_acl_arn
}

# ── API Key + Usage Plan (optional) ───────────────────────────────────────────

resource "aws_api_gateway_api_key" "this" {
  count = var.api_key_required ? 1 : 0
  name  = "${local.name_prefix}-apikey-${var.name}"
  tags  = local.tags
}

resource "aws_api_gateway_usage_plan" "this" {
  count = var.api_key_required ? 1 : 0
  name  = "${local.name_prefix}-usageplan-${var.name}"
  tags  = local.tags

  api_stages {
    api_id = aws_api_gateway_rest_api.this.id
    stage  = aws_api_gateway_stage.this.stage_name
  }

  throttle_settings {
    rate_limit  = var.throttling_rate_limit
    burst_limit = var.throttling_burst_limit
  }
}

resource "aws_api_gateway_usage_plan_key" "this" {
  count         = var.api_key_required ? 1 : 0
  key_id        = aws_api_gateway_api_key.this[0].id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.this[0].id
}

# ── Custom Domain (optional) ──────────────────────────────────────────────────

resource "aws_api_gateway_domain_name" "this" {
  count                    = var.custom_domain_name != null ? 1 : 0
  domain_name              = var.custom_domain_name
  regional_certificate_arn = var.custom_domain_certificate_arn
  tags                     = local.tags

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_base_path_mapping" "this" {
  count       = var.custom_domain_name != null ? 1 : 0
  api_id      = aws_api_gateway_rest_api.this.id
  stage_name  = aws_api_gateway_stage.this.stage_name
  domain_name = aws_api_gateway_domain_name.this[0].domain_name
}

# ── Processor Lambda ──────────────────────────────────────────────────────────
# The application project deploys the handler code via deploy-webhook-ingestion.yml.
# s3_bucket/s3_key are null on first apply; update via CI after initial infra deploy.

module "processor_lambda" {
  source      = "../../modules/lambda"
  project     = var.project
  environment = var.environment
  region      = var.region

  function_name = "${var.name}-webhook-processor"
  description   = "Processes ${var.name} webhook messages from SQS. Handler code deployed by application CI."
  runtime       = var.processor_runtime
  handler       = var.processor_handler
  s3_bucket     = var.processor_s3_bucket
  s3_key        = var.processor_s3_key
  memory_size   = var.processor_memory_size
  timeout       = var.processor_timeout
  kms_key_arn   = var.kms_key_arn
  vpc_config    = var.vpc_config

  reserved_concurrent_executions = var.processor_reserved_concurrency

  environment_variables = var.processor_environment_variables

  sqs_event_source_arns              = [module.sqs.queue_arn]
  sqs_batch_size                     = var.processor_sqs_batch_size
  sqs_maximum_batching_window_seconds = var.processor_sqs_max_batching_window

  tags = local.tags
}
