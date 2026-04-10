variable "project" {
  type        = string
  description = "Project name prefix."
}

variable "environment" {
  type        = string
  description = "Deployment environment."
}

variable "region" {
  type        = string
  description = "AWS region (for tagging; CloudFront is global)."
}

variable "name" {
  description = "Short name for the distribution."
  type        = string
}

variable "aliases" {
  description = "Custom domain aliases (CNAMEs) for the distribution (e.g. ['app.example.com'])."
  type        = list(string)
  default     = []
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN in us-east-1 for HTTPS on custom domains."
  type        = string
  default     = null
}

variable "origins" {
  description = "Map of origin configurations."
  type = map(object({
    domain_name              = string
    origin_id                = string
    origin_path              = optional(string, "")
    s3_oac_enabled           = optional(bool, false)   # use Origin Access Control for S3
    custom_origin_protocol   = optional(string, "https-only")
    custom_origin_http_port  = optional(number, 80)
    custom_origin_https_port = optional(number, 443)
    custom_headers = optional(map(string), {})
  }))
}

variable "default_root_object" {
  description = "Default root object (e.g. 'index.html' for SPAs)."
  type        = string
  default     = "index.html"
}

variable "default_cache_behavior" {
  description = "Default cache behavior configuration."
  type = object({
    target_origin_id       = string
    viewer_protocol_policy = optional(string, "redirect-to-https")
    allowed_methods        = optional(list(string), ["GET", "HEAD", "OPTIONS"])
    cached_methods         = optional(list(string), ["GET", "HEAD"])
    cache_policy_id        = optional(string, null)   # use managed policy ID or null for legacy TTL
    min_ttl                = optional(number, 0)
    default_ttl            = optional(number, 86400)
    max_ttl                = optional(number, 31536000)
    compress               = optional(bool, true)
  })
}

variable "ordered_cache_behaviors" {
  description = "Ordered list of path-based cache behaviors (evaluated before default)."
  type = list(object({
    path_pattern           = string
    target_origin_id       = string
    viewer_protocol_policy = optional(string, "redirect-to-https")
    allowed_methods        = optional(list(string), ["GET", "HEAD"])
    cached_methods         = optional(list(string), ["GET", "HEAD"])
    cache_policy_id        = optional(string, null)
    min_ttl                = optional(number, 0)
    default_ttl            = optional(number, 300)
    max_ttl                = optional(number, 86400)
    compress               = optional(bool, true)
  }))
  default = []
}

variable "custom_error_responses" {
  description = "Custom error response configurations (e.g. SPA 404 → index.html)."
  type = list(object({
    error_code            = number
    response_code         = optional(number, 200)
    response_page_path    = optional(string, "/index.html")
    error_caching_min_ttl = optional(number, 10)
  }))
  default = [{ error_code = 404 }, { error_code = 403 }]
}

variable "geo_restriction_type" {
  description = "Geo restriction type: none | blacklist | whitelist."
  type        = string
  default     = "none"
}

variable "geo_restriction_locations" {
  description = "ISO 3166-1 alpha-2 country codes for geo restriction."
  type        = list(string)
  default     = []
}

variable "waf_web_acl_id" {
  description = "WAFv2 Web ACL ARN (CLOUDFRONT scope, must be in us-east-1)."
  type        = string
  default     = null
}

variable "access_log_bucket" {
  description = "S3 bucket domain name for CloudFront access logs."
  type        = string
  default     = null
}

variable "price_class" {
  description = "CloudFront price class: PriceClass_All | PriceClass_200 | PriceClass_100."
  type        = string
  default     = "PriceClass_100"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags."
}
