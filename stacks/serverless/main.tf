##
## Stack: serverless
## Lambda + SQS + EventBridge + DynamoDB — general async serverless pattern.
##

terraform {
  required_version = ">= 1.7.0"
  required_providers { aws = { source = "hashicorp/aws", version = ">= 5.0" } }
}

provider "aws" { region = var.region }

module "sqs" {
  source      = "../../modules/sqs"
  project     = var.project
  environment = var.environment
  region      = var.region
  queue_name  = var.name
  fifo        = false
  dlq_enabled = true
  kms_key_arn = var.kms_key_arn
  tags        = var.tags
}

module "dynamodb" {
  count       = var.dynamodb_table_name != null ? 1 : 0
  source      = "../../modules/dynamodb"
  project     = var.project
  environment = var.environment
  region      = var.region
  table_name  = var.dynamodb_table_name
  hash_key    = var.dynamodb_hash_key
  kms_key_arn = var.kms_key_arn
  tags        = var.tags
}

module "lambda" {
  source        = "../../modules/lambda"
  project       = var.project
  environment   = var.environment
  region        = var.region
  function_name = var.name
  runtime       = var.lambda_runtime
  handler       = var.lambda_handler
  s3_bucket     = var.lambda_s3_bucket
  s3_key        = var.lambda_s3_key
  memory_size   = var.lambda_memory_size
  timeout       = var.lambda_timeout
  kms_key_arn   = var.kms_key_arn
  vpc_config    = var.vpc_config
  environment_variables = merge(var.lambda_environment_variables,
    var.dynamodb_table_name != null ? { DYNAMODB_TABLE = module.dynamodb[0].table_name } : {}
  )
  sqs_event_source_arns = [module.sqs.queue_arn]
  execution_role_extra_policies = var.dynamodb_table_name != null ? {
    dynamodb-access = jsonencode({
      Version = "2012-10-17"
      Statement = [{ Effect = "Allow", Action = ["dynamodb:GetItem","dynamodb:PutItem","dynamodb:UpdateItem","dynamodb:DeleteItem","dynamodb:Query","dynamodb:Scan"], Resource = module.dynamodb[0].table_arn }]
    })
  } : {}
  tags = var.tags
}

module "eventbridge" {
  count       = length(var.schedule_expressions) > 0 ? 1 : 0
  source      = "../../modules/eventbridge"
  project     = var.project
  environment = var.environment
  region      = var.region
  bus_name    = var.name
  rules = { for idx, expr in var.schedule_expressions :
    "schedule-${idx}" => {
      schedule_expression = expr
      targets = [{ id = "lambda", arn = module.lambda.function_arn }]
    }
  }
  tags = var.tags
}

resource "aws_lambda_permission" "eventbridge" {
  count         = length(var.schedule_expressions) > 0 ? 1 : 0
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda.function_name
  principal     = "events.amazonaws.com"
}
