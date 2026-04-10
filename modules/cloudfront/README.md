# Module: `cloudfront`

Creates a CloudFront distribution with configurable origins, cache behaviors, custom error responses (SPA support), optional WAF, and Origin Access Control for S3 origins.

Full name pattern: `{project}-{environment}-cloudfront-{name}`

## Usage

### SPA with S3 origin

```hcl
module "cdn" {
  source = "../../modules/cloudfront"

  project     = "myapp"
  environment = "prod"
  region      = "us-east-1"
  name        = "frontend"

  aliases             = ["app.example.com"]
  acm_certificate_arn = module.cert.certificate_arn   # must be in us-east-1

  origins = {
    s3 = {
      domain_name    = module.assets.bucket_domain_name
      origin_id      = "s3-assets"
      s3_oac_enabled = true
    }
  }

  default_cache_behavior = {
    target_origin_id = "s3-assets"
  }

  custom_error_responses = [
    { error_code = 404, response_code = 200, response_page_path = "/index.html" },
    { error_code = 403, response_code = 200, response_page_path = "/index.html" },
  ]

  waf_web_acl_id = module.waf.web_acl_arn

  tags = { Team = "frontend" }
}
```

### API + S3 multi-origin

```hcl
module "cdn" {
  source = "../../modules/cloudfront"
  # ...
  origins = {
    api = {
      domain_name              = "api.example.com"
      origin_id                = "api"
      custom_origin_protocol   = "https-only"
    }
    static = {
      domain_name    = module.static.bucket_domain_name
      origin_id      = "static"
      s3_oac_enabled = true
    }
  }

  default_cache_behavior = { target_origin_id = "api" }

  ordered_cache_behaviors = [
    {
      path_pattern     = "/static/*"
      target_origin_id = "static"
    }
  ]
}
```

## Required Inputs

| Name | Type | Description |
|---|---|---|
| `project` | `string` | Project name prefix |
| `environment` | `string` | Deployment environment |
| `region` | `string` | AWS region (for tagging; CloudFront is global) |
| `name` | `string` | Short distribution name |
| `origins` | `map(object)` | Origin configurations |
| `default_cache_behavior` | `object` | Default cache behavior |

## Optional Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `aliases` | `list(string)` | `[]` | Custom domain aliases (CNAMEs) |
| `acm_certificate_arn` | `string` | `null` | ACM certificate ARN in us-east-1 for custom domains |
| `default_root_object` | `string` | `"index.html"` | Default root object |
| `ordered_cache_behaviors` | `list(object)` | `[]` | Path-based cache behaviors |
| `custom_error_responses` | `list(object)` | 404+403 → index.html | Custom error responses |
| `geo_restriction_type` | `string` | `"none"` | `none`, `blacklist`, or `whitelist` |
| `geo_restriction_locations` | `list(string)` | `[]` | Country codes for geo restriction |
| `waf_web_acl_id` | `string` | `null` | WAFv2 Web ACL ARN (CLOUDFRONT scope, us-east-1) |
| `access_log_bucket` | `string` | `null` | S3 bucket domain name for access logs |
| `price_class` | `string` | `"PriceClass_100"` | `PriceClass_All`, `PriceClass_200`, `PriceClass_100` |
| `tags` | `map(string)` | `{}` | Additional resource tags |

## Outputs

| Name | Description |
|---|---|
| `distribution_id` | CloudFront distribution ID |
| `distribution_arn` | CloudFront distribution ARN |
| `domain_name` | CloudFront domain name (e.g. `d111111abcdef8.cloudfront.net`) |
| `hosted_zone_id` | Route 53 hosted zone ID for alias records |
| `oac_ids` | Map of origin key to OAC ID |
