# Module: `waf`

Creates a WAFv2 Web ACL with AWS managed rule groups, rate-based rules, and IP allow/block lists. Supports both REGIONAL (ALB, API Gateway) and CLOUDFRONT scopes.

Full name pattern: `{project}-{environment}-{region_short}-waf-{name}`

## Usage

```hcl
module "waf" {
  source = "../../modules/waf"

  project     = "myapp"
  environment = "prod"
  region      = "us-east-1"
  name        = "api"
  scope       = "REGIONAL"

  managed_rule_groups = [
    { name = "AWSManagedRulesCommonRuleSet",         priority = 10 },
    { name = "AWSManagedRulesKnownBadInputsRuleSet", priority = 20 },
    { name = "AWSManagedRulesSQLiRuleSet",           priority = 30 },
  ]

  rate_limit_rules = [
    { name = "rate-limit-global", priority = 1, limit = 2000 }
  ]

  ip_block_list_cidrs = ["192.0.2.0/24"]

  tags = { Team = "security" }
}
```

### CloudFront WAF (must be deployed in us-east-1)

```hcl
module "cdn_waf" {
  source = "../../modules/waf"
  # ...
  scope  = "CLOUDFRONT"
  region = "us-east-1"   # required for CloudFront scope
}
```

## Required Inputs

| Name | Type | Description |
|---|---|---|
| `project` | `string` | Project name prefix |
| `environment` | `string` | Deployment environment |
| `region` | `string` | AWS region |
| `name` | `string` | Short name for the Web ACL |

## Optional Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `scope` | `string` | `"REGIONAL"` | `REGIONAL` (ALB, API Gateway) or `CLOUDFRONT` |
| `managed_rule_groups` | `list(object)` | Common + KnownBad + SQLi | AWS managed rule groups to include |
| `rate_limit_rules` | `list(object)` | 2000 req/5min | Rate-based rules |
| `ip_allow_list_cidrs` | `list(string)` | `[]` | CIDR blocks to explicitly allow (bypasses all rules) |
| `ip_block_list_cidrs` | `list(string)` | `[]` | CIDR blocks to explicitly block |
| `cloudwatch_metrics_enabled` | `bool` | `true` | Enable CloudWatch metrics |
| `sampled_requests_enabled` | `bool` | `true` | Enable sampled request logging in AWS console |
| `tags` | `map(string)` | `{}` | Additional resource tags |

### Managed rule group object schema

| Field | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | required | Rule group name (e.g. `AWSManagedRulesCommonRuleSet`) |
| `vendor_name` | `string` | `"AWS"` | Vendor name |
| `priority` | `number` | required | Evaluation priority (lower = first) |
| `override_action` | `string` | `"none"` | `none` (block) or `count` (observe only) |
| `excluded_rules` | `list(string)` | `[]` | Rule names to exclude from the group |

## Outputs

| Name | Description |
|---|---|
| `web_acl_arn` | WAFv2 Web ACL ARN |
| `web_acl_id` | WAFv2 Web ACL ID |
| `web_acl_name` | WAFv2 Web ACL name |
