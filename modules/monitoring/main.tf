##
## Module: monitoring
## Creates CloudWatch log groups, metric alarms, SNS alert topic,
## and optional dashboards.
##

locals {
  region_short = {
    "us-east-1" = "use1", "us-east-2" = "use2", "us-west-1" = "usw1", "us-west-2" = "usw2",
    "eu-west-1" = "euw1", "eu-west-2" = "euw2", "eu-central-1" = "euc1",
    "ap-southeast-1" = "apse1", "ap-southeast-2" = "apse2", "ap-northeast-1" = "apne1"
  }
  rs          = lookup(local.region_short, var.region, replace(var.region, "-", ""))
  name_prefix = "${var.project}-${var.environment}-${local.rs}"

  default_tags = merge({
    Project = var.project, Environment = var.environment, Region = var.region, ManagedBy = "terraform"
  }, var.tags)
}

resource "aws_sns_topic" "alerts" {
  name = "${local.name_prefix}-alerts"
  tags = merge(local.default_tags, { Name = "${local.name_prefix}-alerts" })
}

resource "aws_sns_topic_subscription" "email" {
  count     = length(var.alert_emails)
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_emails[count.index]
}

resource "aws_cloudwatch_log_group" "this" {
  for_each          = var.log_groups
  name              = each.value.name
  retention_in_days = each.value.retention_in_days
  kms_key_id        = each.value.kms_key_arn
  tags              = local.default_tags
}

resource "aws_cloudwatch_metric_alarm" "this" {
  for_each = var.alarms

  alarm_name          = "${local.name_prefix}-alarm-${each.key}"
  comparison_operator = each.value.comparison_operator
  evaluation_periods  = each.value.evaluation_periods
  metric_name         = each.value.metric_name
  namespace           = each.value.namespace
  period              = each.value.period
  statistic           = each.value.statistic
  threshold           = each.value.threshold
  alarm_description   = each.value.alarm_description
  treat_missing_data  = each.value.treat_missing_data
  datapoints_to_alarm = each.value.datapoints_to_alarm

  dimensions = each.value.dimensions

  alarm_actions = length(each.value.alarm_actions) > 0 ? each.value.alarm_actions : [aws_sns_topic.alerts.arn]
  ok_actions    = length(each.value.ok_actions) > 0 ? each.value.ok_actions : [aws_sns_topic.alerts.arn]

  tags = merge(local.default_tags, { Name = "${local.name_prefix}-alarm-${each.key}" })
}

resource "aws_cloudwatch_dashboard" "this" {
  count          = var.dashboard_name != null && var.dashboard_body != null ? 1 : 0
  dashboard_name = "${local.name_prefix}-${var.dashboard_name}"
  dashboard_body = var.dashboard_body
}
