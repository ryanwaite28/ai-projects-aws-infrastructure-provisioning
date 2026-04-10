##
## Stack: event-driven
## Custom EventBridge bus + Lambda consumers for async domain events.
##

terraform {
  required_version = ">= 1.7.0"
  required_providers { aws = { source = "hashicorp/aws", version = ">= 5.0" } }
}

provider "aws" { region = var.region }

module "event_bus" {
  source      = "../../modules/eventbridge"
  project     = var.project
  environment = var.environment
  region      = var.region
  bus_name    = var.bus_name
  allowed_publisher_arns = var.allowed_publisher_arns
  rules       = var.event_rules
  tags        = var.tags
}

module "consumer_lambdas" {
  for_each      = var.consumers
  source        = "../../modules/lambda"
  project       = var.project
  environment   = var.environment
  region        = var.region
  function_name = "${var.bus_name}-consumer-${each.key}"
  runtime       = each.value.runtime
  handler       = each.value.handler
  s3_bucket     = each.value.s3_bucket
  s3_key        = each.value.s3_key
  memory_size   = lookup(each.value, "memory_size", 512)
  timeout       = lookup(each.value, "timeout", 60)
  environment_variables = lookup(each.value, "environment_variables", {})
  vpc_config    = lookup(each.value, "vpc_config", null)
  tags          = var.tags
}

resource "aws_lambda_permission" "eventbridge" {
  for_each      = var.consumers
  statement_id  = "AllowEventBridgeInvoke-${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = module.consumer_lambdas[each.key].function_name
  principal     = "events.amazonaws.com"
  source_arn    = module.event_bus.bus_arn
}
