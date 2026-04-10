##
## Module: waf
## Creates a WAFv2 Web ACL with managed rule groups, rate limiting,
## and optional IP allow/block lists.
##

locals {
  region_short = {
    "us-east-1" = "use1", "us-east-2" = "use2", "us-west-1" = "usw1", "us-west-2" = "usw2",
    "eu-west-1" = "euw1", "eu-west-2" = "euw2", "eu-central-1" = "euc1",
    "ap-southeast-1" = "apse1", "ap-southeast-2" = "apse2", "ap-northeast-1" = "apne1"
  }
  rs          = lookup(local.region_short, var.region, replace(var.region, "-", ""))
  name_prefix = "${var.project}-${var.environment}-${local.rs}"
  acl_name    = "${local.name_prefix}-waf-${var.name}"

  default_tags = merge({
    Project = var.project, Environment = var.environment, Region = var.region, ManagedBy = "terraform"
  }, var.tags)
}

resource "aws_wafv2_ip_set" "allow" {
  count              = length(var.ip_allow_list_cidrs) > 0 ? 1 : 0
  name               = "${local.acl_name}-ip-allow"
  scope              = var.scope
  ip_address_version = "IPV4"
  addresses          = var.ip_allow_list_cidrs
  tags               = local.default_tags
}

resource "aws_wafv2_ip_set" "block" {
  count              = length(var.ip_block_list_cidrs) > 0 ? 1 : 0
  name               = "${local.acl_name}-ip-block"
  scope              = var.scope
  ip_address_version = "IPV4"
  addresses          = var.ip_block_list_cidrs
  tags               = local.default_tags
}

resource "aws_wafv2_web_acl" "this" {
  name  = local.acl_name
  scope = var.scope

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = var.cloudwatch_metrics_enabled
    metric_name                = replace(local.acl_name, "-", "")
    sampled_requests_enabled   = var.sampled_requests_enabled
  }

  # IP allow list (priority 0 — evaluated first)
  dynamic "rule" {
    for_each = length(var.ip_allow_list_cidrs) > 0 ? [1] : []
    content {
      name     = "ip-allow-list"
      priority = 0
      action { allow {} }
      statement {
        ip_set_reference_statement {
          arn = aws_wafv2_ip_set.allow[0].arn
        }
      }
      visibility_config {
        cloudwatch_metrics_enabled = var.cloudwatch_metrics_enabled
        metric_name                = "${replace(local.acl_name, "-", "")}IPAllow"
        sampled_requests_enabled   = var.sampled_requests_enabled
      }
    }
  }

  # IP block list
  dynamic "rule" {
    for_each = length(var.ip_block_list_cidrs) > 0 ? [1] : []
    content {
      name     = "ip-block-list"
      priority = 1
      action { block {} }
      statement {
        ip_set_reference_statement {
          arn = aws_wafv2_ip_set.block[0].arn
        }
      }
      visibility_config {
        cloudwatch_metrics_enabled = var.cloudwatch_metrics_enabled
        metric_name                = "${replace(local.acl_name, "-", "")}IPBlock"
        sampled_requests_enabled   = var.sampled_requests_enabled
      }
    }
  }

  # Rate-based rules
  dynamic "rule" {
    for_each = var.rate_limit_rules
    content {
      name     = rule.value.name
      priority = rule.value.priority
      dynamic "action" {
        for_each = rule.value.action == "block" ? [1] : []
        content { block {} }
      }
      dynamic "action" {
        for_each = rule.value.action == "count" ? [1] : []
        content { count {} }
      }
      statement {
        rate_based_statement {
          limit              = rule.value.limit
          aggregate_key_type = rule.value.aggregate_key_type
        }
      }
      visibility_config {
        cloudwatch_metrics_enabled = var.cloudwatch_metrics_enabled
        metric_name                = replace(rule.value.name, "-", "")
        sampled_requests_enabled   = var.sampled_requests_enabled
      }
    }
  }

  # AWS Managed Rule Groups
  dynamic "rule" {
    for_each = var.managed_rule_groups
    content {
      name     = rule.value.name
      priority = rule.value.priority
      dynamic "override_action" {
        for_each = rule.value.override_action == "count" ? [1] : []
        content { count {} }
      }
      dynamic "override_action" {
        for_each = rule.value.override_action == "none" ? [1] : []
        content { none {} }
      }
      statement {
        managed_rule_group_statement {
          name        = rule.value.name
          vendor_name = rule.value.vendor_name

          dynamic "rule_action_override" {
            for_each = rule.value.excluded_rules
            content {
              name          = rule_action_override.value
              action_to_use { count {} }
            }
          }
        }
      }
      visibility_config {
        cloudwatch_metrics_enabled = var.cloudwatch_metrics_enabled
        metric_name                = replace(rule.value.name, "-", "")
        sampled_requests_enabled   = var.sampled_requests_enabled
      }
    }
  }

  tags = merge(local.default_tags, { Name = local.acl_name })
}
