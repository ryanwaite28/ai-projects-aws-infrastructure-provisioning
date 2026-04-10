##
## Module: eventbridge
## Creates an EventBridge event bus with rules and targets.
##

locals {
  region_short = {
    "us-east-1" = "use1", "us-east-2" = "use2", "us-west-1" = "usw1", "us-west-2" = "usw2",
    "eu-west-1" = "euw1", "eu-west-2" = "euw2", "eu-central-1" = "euc1",
    "ap-southeast-1" = "apse1", "ap-southeast-2" = "apse2", "ap-northeast-1" = "apne1"
  }
  rs        = lookup(local.region_short, var.region, replace(var.region, "-", ""))
  bus_name  = var.use_default_bus ? "default" : "${var.project}-${var.environment}-${local.rs}-bus-${var.bus_name}"

  default_tags = merge({
    Project = var.project, Environment = var.environment, Region = var.region, ManagedBy = "terraform"
  }, var.tags)
}

data "aws_caller_identity" "current" {}

resource "aws_cloudwatch_event_bus" "this" {
  count = var.use_default_bus ? 0 : 1
  name  = local.bus_name
  tags  = merge(local.default_tags, { Name = local.bus_name })
}

resource "aws_cloudwatch_event_bus_policy" "this" {
  count    = !var.use_default_bus && length(var.allowed_publisher_arns) > 0 ? 1 : 0
  event_bus_name = aws_cloudwatch_event_bus.this[0].name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid      = "AllowPublish"
      Effect   = "Allow"
      Principal = { AWS = var.allowed_publisher_arns }
      Action   = "events:PutEvents"
      Resource = aws_cloudwatch_event_bus.this[0].arn
    }]
  })
}

resource "aws_cloudwatch_event_rule" "this" {
  for_each       = var.rules
  name           = "${var.project}-${var.environment}-${local.rs}-rule-${each.key}"
  description    = each.value.description
  event_bus_name = var.use_default_bus ? "default" : aws_cloudwatch_event_bus.this[0].name
  state          = each.value.state

  schedule_expression = each.value.schedule_expression
  event_pattern       = each.value.event_pattern

  tags = merge(local.default_tags, { Name = "${var.project}-${var.environment}-${local.rs}-rule-${each.key}" })
}

resource "aws_cloudwatch_event_target" "this" {
  for_each       = {
    for pair in flatten([
      for rule_key, rule in var.rules : [
        for target in rule.targets : {
          rule_key = rule_key
          target   = target
          key      = "${rule_key}-${target.id}"
        }
      ]
    ]) : pair.key => pair
  }

  rule           = aws_cloudwatch_event_rule.this[each.value.rule_key].name
  event_bus_name = var.use_default_bus ? "default" : aws_cloudwatch_event_bus.this[0].name
  target_id      = each.value.target.id
  arn            = each.value.target.arn
  role_arn       = each.value.target.role_arn
  input          = each.value.target.input
  input_path     = each.value.target.input_path

  dynamic "dead_letter_config" {
    for_each = each.value.target.dead_letter_arn != null ? [1] : []
    content { arn = each.value.target.dead_letter_arn }
  }

  dynamic "ecs_target" {
    for_each = each.value.target.ecs_target != null ? [each.value.target.ecs_target] : []
    content {
      task_definition_arn = ecs_target.value.task_definition_arn
      task_count          = ecs_target.value.task_count
      launch_type         = ecs_target.value.launch_type
      network_configuration {
        subnets          = ecs_target.value.subnet_ids
        security_groups  = ecs_target.value.security_group_ids
        assign_public_ip = ecs_target.value.assign_public_ip
      }
    }
  }
}
