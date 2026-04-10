##
## Module: cloudfront
## Creates a CloudFront distribution with multiple origins, cache behaviors,
## OAC for S3, WAF association, and custom error pages.
##

locals {
  region_short = {
    "us-east-1" = "use1", "us-east-2" = "use2", "us-west-1" = "usw1", "us-west-2" = "usw2",
    "eu-west-1" = "euw1", "eu-west-2" = "euw2", "eu-central-1" = "euc1",
    "ap-southeast-1" = "apse1", "ap-southeast-2" = "apse2", "ap-northeast-1" = "apne1"
  }
  rs   = lookup(local.region_short, var.region, replace(var.region, "-", ""))
  name = "${var.project}-${var.environment}-${local.rs}-cf-${var.name}"

  default_tags = merge({
    Project = var.project, Environment = var.environment, Region = var.region, ManagedBy = "terraform"
  }, var.tags)

  s3_oac_origins = { for k, v in var.origins : k => v if v.s3_oac_enabled }
}

resource "aws_cloudfront_origin_access_control" "s3" {
  for_each                          = local.s3_oac_origins
  name                              = "${local.name}-oac-${each.key}"
  description                       = "OAC for ${each.value.domain_name}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "this" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = local.name
  price_class         = var.price_class
  aliases             = var.aliases
  default_root_object = var.default_root_object
  web_acl_id          = var.waf_web_acl_id
  http_version        = "http2and3"

  dynamic "origin" {
    for_each = var.origins
    content {
      domain_name              = origin.value.domain_name
      origin_id                = origin.value.origin_id
      origin_path              = origin.value.origin_path
      origin_access_control_id = origin.value.s3_oac_enabled ? aws_cloudfront_origin_access_control.s3[origin.key].id : null

      dynamic "custom_origin_config" {
        for_each = !origin.value.s3_oac_enabled ? [1] : []
        content {
          http_port              = origin.value.custom_origin_http_port
          https_port             = origin.value.custom_origin_https_port
          origin_protocol_policy = origin.value.custom_origin_protocol
          origin_ssl_protocols   = ["TLSv1.2"]
        }
      }

      dynamic "custom_header" {
        for_each = origin.value.custom_headers
        content {
          name  = custom_header.key
          value = custom_header.value
        }
      }
    }
  }

  default_cache_behavior {
    target_origin_id       = var.default_cache_behavior.target_origin_id
    viewer_protocol_policy = var.default_cache_behavior.viewer_protocol_policy
    allowed_methods        = var.default_cache_behavior.allowed_methods
    cached_methods         = var.default_cache_behavior.cached_methods
    compress               = var.default_cache_behavior.compress
    cache_policy_id        = var.default_cache_behavior.cache_policy_id
    min_ttl                = var.default_cache_behavior.cache_policy_id == null ? var.default_cache_behavior.min_ttl : null
    default_ttl            = var.default_cache_behavior.cache_policy_id == null ? var.default_cache_behavior.default_ttl : null
    max_ttl                = var.default_cache_behavior.cache_policy_id == null ? var.default_cache_behavior.max_ttl : null
  }

  dynamic "ordered_cache_behavior" {
    for_each = var.ordered_cache_behaviors
    content {
      path_pattern           = ordered_cache_behavior.value.path_pattern
      target_origin_id       = ordered_cache_behavior.value.target_origin_id
      viewer_protocol_policy = ordered_cache_behavior.value.viewer_protocol_policy
      allowed_methods        = ordered_cache_behavior.value.allowed_methods
      cached_methods         = ordered_cache_behavior.value.cached_methods
      compress               = ordered_cache_behavior.value.compress
      cache_policy_id        = ordered_cache_behavior.value.cache_policy_id
      min_ttl                = ordered_cache_behavior.value.cache_policy_id == null ? ordered_cache_behavior.value.min_ttl : null
      default_ttl            = ordered_cache_behavior.value.cache_policy_id == null ? ordered_cache_behavior.value.default_ttl : null
      max_ttl                = ordered_cache_behavior.value.cache_policy_id == null ? ordered_cache_behavior.value.max_ttl : null
    }
  }

  dynamic "custom_error_response" {
    for_each = var.custom_error_responses
    content {
      error_code            = custom_error_response.value.error_code
      response_code         = custom_error_response.value.response_code
      response_page_path    = custom_error_response.value.response_page_path
      error_caching_min_ttl = custom_error_response.value.error_caching_min_ttl
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = var.geo_restriction_type
      locations        = var.geo_restriction_locations
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = var.acm_certificate_arn == null
    acm_certificate_arn            = var.acm_certificate_arn
    ssl_support_method             = var.acm_certificate_arn != null ? "sni-only" : null
    minimum_protocol_version       = var.acm_certificate_arn != null ? "TLSv1.2_2021" : null
  }

  dynamic "logging_config" {
    for_each = var.access_log_bucket != null ? [1] : []
    content {
      bucket          = var.access_log_bucket
      prefix          = "cloudfront/${local.name}/"
      include_cookies = false
    }
  }

  tags = merge(local.default_tags, { Name = local.name })
}
