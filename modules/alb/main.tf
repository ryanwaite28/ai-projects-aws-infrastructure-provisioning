##
## Module: alb
## Creates an Application Load Balancer with HTTPS listener, optional HTTP→HTTPS
## redirect, target groups, listener rules, and optional WAF association.
##

locals {
  region_short = {
    "us-east-1" = "use1", "us-east-2" = "use2", "us-west-1" = "usw1", "us-west-2" = "usw2",
    "eu-west-1" = "euw1", "eu-west-2" = "euw2", "eu-central-1" = "euc1",
    "ap-southeast-1" = "apse1", "ap-southeast-2" = "apse2", "ap-northeast-1" = "apne1"
  }
  rs          = lookup(local.region_short, var.region, replace(var.region, "-", ""))
  name_prefix = "${var.project}-${var.environment}-${local.rs}"
  alb_name    = "${local.name_prefix}-alb-${var.name}"

  default_tags = merge({
    Project     = var.project
    Environment = var.environment
    Region      = var.region
    ManagedBy   = "terraform"
  }, var.tags)
}

resource "aws_lb" "this" {
  name               = local.alb_name
  internal           = var.internal
  load_balancer_type = "application"
  security_groups    = var.security_group_ids
  subnets            = var.subnet_ids
  idle_timeout       = var.idle_timeout
  enable_deletion_protection = var.enable_deletion_protection

  dynamic "access_logs" {
    for_each = var.enable_access_logs && var.access_logs_bucket != null ? [1] : []
    content {
      bucket  = var.access_logs_bucket
      prefix  = "${var.access_logs_prefix}/${local.alb_name}"
      enabled = true
    }
  }

  tags = merge(local.default_tags, { Name = local.alb_name })
}

# ── HTTPS Listener ────────────────────────────────────────────────────────────

resource "aws_lb_listener" "https" {
  count             = var.certificate_arn != null ? 1 : 0
  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = var.ssl_policy
  certificate_arn   = var.certificate_arn

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "404 Not Found"
      status_code  = "404"
    }
  }

  tags = merge(local.default_tags, { Name = "${local.alb_name}-listener-https" })
}

resource "aws_lb_listener_certificate" "additional" {
  for_each        = toset(var.additional_certificate_arns)
  listener_arn    = aws_lb_listener.https[0].arn
  certificate_arn = each.value
}

# ── HTTP → HTTPS Redirect ─────────────────────────────────────────────────────

resource "aws_lb_listener" "http_redirect" {
  count             = var.enable_http_to_https_redirect && var.certificate_arn != null ? 1 : 0
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  tags = merge(local.default_tags, { Name = "${local.alb_name}-listener-http-redirect" })
}

# ── Target Groups ─────────────────────────────────────────────────────────────

resource "aws_lb_target_group" "this" {
  for_each             = var.target_groups
  name                 = "${local.name_prefix}-tg-${each.key}"
  port                 = each.value.port
  protocol             = each.value.protocol
  vpc_id               = var.vpc_id
  target_type          = each.value.target_type
  deregistration_delay = each.value.deregistration_delay

  health_check {
    path                = lookup(each.value.health_check, "path", "/health")
    healthy_threshold   = lookup(each.value.health_check, "healthy_threshold", 2)
    unhealthy_threshold = lookup(each.value.health_check, "unhealthy_threshold", 3)
    interval            = lookup(each.value.health_check, "interval", 30)
    timeout             = lookup(each.value.health_check, "timeout", 5)
    matcher             = lookup(each.value.health_check, "matcher", "200")
  }

  tags = merge(local.default_tags, { Name = "${local.name_prefix}-tg-${each.key}" })

  lifecycle {
    create_before_destroy = true
  }
}

# ── Listener Rules ────────────────────────────────────────────────────────────

resource "aws_lb_listener_rule" "this" {
  count        = length(var.listener_rules)
  listener_arn = aws_lb_listener.https[0].arn
  priority     = var.listener_rules[count.index].priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this[var.listener_rules[count.index].target_group_key].arn
  }

  dynamic "condition" {
    for_each = var.listener_rules[count.index].conditions
    content {
      dynamic "path_pattern" {
        for_each = condition.value.type == "path_pattern" ? [1] : []
        content { values = condition.value.values }
      }
      dynamic "host_header" {
        for_each = condition.value.type == "host_header" ? [1] : []
        content { values = condition.value.values }
      }
      dynamic "source_ip" {
        for_each = condition.value.type == "source_ip" ? [1] : []
        content { values = condition.value.values }
      }
    }
  }
}

# ── WAF Association ───────────────────────────────────────────────────────────

resource "aws_wafv2_web_acl_association" "this" {
  count        = var.waf_acl_arn != null ? 1 : 0
  resource_arn = aws_lb.this.arn
  web_acl_arn  = var.waf_acl_arn
}
