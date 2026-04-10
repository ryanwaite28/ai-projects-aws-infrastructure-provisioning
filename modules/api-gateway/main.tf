##
## Module: api-gateway
## Creates an API Gateway HTTP API (v2) or REST API (v1) with routes,
## integrations, JWT authorizers, VPC Link, and optional custom domain.
##

locals {
  region_short = {
    "us-east-1" = "use1", "us-east-2" = "use2", "us-west-1" = "usw1", "us-west-2" = "usw2",
    "eu-west-1" = "euw1", "eu-west-2" = "euw2", "eu-central-1" = "euc1",
    "ap-southeast-1" = "apse1", "ap-southeast-2" = "apse2", "ap-northeast-1" = "apne1"
  }
  rs        = lookup(local.region_short, var.region, replace(var.region, "-", ""))
  api_name  = "${var.project}-${var.environment}-${local.rs}-apigw-${var.api_name}"
  use_vpc_link = length(var.vpc_link_subnet_ids) > 0

  default_tags = merge({
    Project = var.project, Environment = var.environment, Region = var.region, ManagedBy = "terraform"
  }, var.tags)
}

resource "aws_cloudwatch_log_group" "access_logs" {
  name              = "/aws/apigateway/${local.api_name}"
  retention_in_days = var.log_retention_days
  tags              = local.default_tags
}

# ── VPC Link (for private ALB integration) ────────────────────────────────────

resource "aws_apigatewayv2_vpc_link" "this" {
  count              = local.use_vpc_link ? 1 : 0
  name               = "${local.api_name}-vpc-link"
  subnet_ids         = var.vpc_link_subnet_ids
  security_group_ids = var.vpc_link_security_group_ids
  tags               = merge(local.default_tags, { Name = "${local.api_name}-vpc-link" })
}

# ── HTTP API (v2) ─────────────────────────────────────────────────────────────

resource "aws_apigatewayv2_api" "this" {
  count         = var.api_type == "HTTP" ? 1 : 0
  name          = local.api_name
  protocol_type = "HTTP"
  description   = var.description

  dynamic "cors_configuration" {
    for_each = var.cors_configuration != null ? [var.cors_configuration] : []
    content {
      allow_origins     = cors_configuration.value.allow_origins
      allow_methods     = cors_configuration.value.allow_methods
      allow_headers     = cors_configuration.value.allow_headers
      expose_headers    = cors_configuration.value.expose_headers
      max_age           = cors_configuration.value.max_age
      allow_credentials = cors_configuration.value.allow_credentials
    }
  }

  tags = merge(local.default_tags, { Name = local.api_name })
}

resource "aws_apigatewayv2_authorizer" "this" {
  for_each          = var.api_type == "HTTP" ? var.authorizers : {}
  api_id            = aws_apigatewayv2_api.this[0].id
  name              = each.key
  authorizer_type   = each.value.authorizer_type
  identity_sources  = each.value.identity_sources

  dynamic "jwt_configuration" {
    for_each = each.value.jwt_configuration != null ? [each.value.jwt_configuration] : []
    content {
      audience = jwt_configuration.value.audience
      issuer   = jwt_configuration.value.issuer
    }
  }
}

resource "aws_apigatewayv2_integration" "this" {
  for_each                  = var.api_type == "HTTP" ? var.routes : {}
  api_id                    = aws_apigatewayv2_api.this[0].id
  integration_type          = each.value.integration_type
  integration_uri           = each.value.integration_uri
  integration_method        = each.value.integration_method
  connection_type           = local.use_vpc_link ? "VPC_LINK" : "INTERNET"
  connection_id             = local.use_vpc_link ? aws_apigatewayv2_vpc_link.this[0].id : null
  payload_format_version    = "2.0"
}

resource "aws_apigatewayv2_route" "this" {
  for_each           = var.api_type == "HTTP" ? var.routes : {}
  api_id             = aws_apigatewayv2_api.this[0].id
  route_key          = each.key
  target             = "integrations/${aws_apigatewayv2_integration.this[each.key].id}"
  authorization_type = each.value.authorization_type
  authorizer_id      = each.value.authorizer_key != null ? aws_apigatewayv2_authorizer.this[each.value.authorizer_key].id : null
}

resource "aws_apigatewayv2_stage" "this" {
  count       = var.api_type == "HTTP" ? 1 : 0
  api_id      = aws_apigatewayv2_api.this[0].id
  name        = var.stage_name
  auto_deploy = var.auto_deploy

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.access_logs.arn
  }

  tags = merge(local.default_tags, { Name = "${local.api_name}-stage-${var.stage_name}" })
}

# ── WAF Association ───────────────────────────────────────────────────────────

resource "aws_wafv2_web_acl_association" "this" {
  count        = var.waf_acl_arn != null && var.api_type == "HTTP" ? 1 : 0
  resource_arn = aws_apigatewayv2_stage.this[0].arn
  web_acl_arn  = var.waf_acl_arn
}

# ── Custom Domain ─────────────────────────────────────────────────────────────

resource "aws_apigatewayv2_domain_name" "this" {
  count       = var.custom_domain_name != null && var.custom_domain_certificate_arn != null ? 1 : 0
  domain_name = var.custom_domain_name

  domain_name_configuration {
    certificate_arn = var.custom_domain_certificate_arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }

  tags = merge(local.default_tags, { Name = var.custom_domain_name })
}

resource "aws_apigatewayv2_api_mapping" "this" {
  count       = var.custom_domain_name != null && var.custom_domain_certificate_arn != null && var.api_type == "HTTP" ? 1 : 0
  api_id      = aws_apigatewayv2_api.this[0].id
  domain_name = aws_apigatewayv2_domain_name.this[0].id
  stage       = aws_apigatewayv2_stage.this[0].id
}
