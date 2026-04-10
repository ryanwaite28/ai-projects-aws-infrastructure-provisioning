# Module: `alb`

Creates an Application Load Balancer (public or internal) with HTTPS listener, HTTP→HTTPS redirect, target groups, listener rules, optional WAF association, and access logging.

Full name pattern: `{project}-{environment}-{region_short}-alb-{name}`

## Usage

```hcl
module "alb" {
  source = "../../modules/alb"

  project     = "myapp"
  environment = "prod"
  region      = "us-east-1"
  name        = "public"

  internal           = false
  vpc_id             = module.network.vpc_id
  subnet_ids         = module.network.public_subnet_ids
  security_group_ids = [aws_security_group.alb.id]
  certificate_arn    = module.cert.certificate_arn

  target_groups = {
    api = {
      port        = 8080
      target_type = "ip"
      health_check = {
        path    = "/health"
        matcher = "200"
      }
    }
  }

  listener_rules = [
    {
      priority         = 10
      target_group_key = "api"
      conditions = [
        { type = "path_pattern", values = ["/api/*"] }
      ]
    }
  ]

  tags = { Team = "platform" }
}
```

### Internal ALB for private services

```hcl
module "internal_alb" {
  source = "../../modules/alb"
  # ...
  internal   = true
  subnet_ids = module.network.private_subnet_ids
}
```

## Required Inputs

| Name | Type | Description |
|---|---|---|
| `project` | `string` | Project name prefix |
| `environment` | `string` | Deployment environment |
| `region` | `string` | AWS region |
| `name` | `string` | Short ALB name |
| `vpc_id` | `string` | VPC ID |
| `subnet_ids` | `list(string)` | Subnet IDs (public for internet-facing; private for internal) |

## Optional Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `internal` | `bool` | `false` | `true` for internal (private) ALB |
| `security_group_ids` | `list(string)` | `[]` | Security group IDs for the ALB |
| `certificate_arn` | `string` | `null` | ACM certificate ARN for HTTPS listener |
| `additional_certificate_arns` | `list(string)` | `[]` | Additional certificates for SNI |
| `ssl_policy` | `string` | TLS 1.3 policy | SSL negotiation policy |
| `enable_http_to_https_redirect` | `bool` | `true` | Create HTTP:80 → HTTPS:443 redirect |
| `idle_timeout` | `number` | `60` | Connection idle timeout in seconds |
| `enable_deletion_protection` | `bool` | `false` | Prevent accidental deletion |
| `enable_access_logs` | `bool` | `false` | Enable access logging to S3 |
| `access_logs_bucket` | `string` | `null` | S3 bucket name for access logs |
| `access_logs_prefix` | `string` | `"alb-access-logs"` | S3 key prefix for access logs |
| `waf_acl_arn` | `string` | `null` | WAFv2 Web ACL ARN to associate |
| `target_groups` | `map(object)` | `{}` | Target group configurations |
| `listener_rules` | `list(object)` | `[]` | HTTPS listener rules in priority order |
| `tags` | `map(string)` | `{}` | Additional resource tags |

## Outputs

| Name | Description |
|---|---|
| `alb_id` | ALB ID |
| `alb_arn` | ALB ARN |
| `alb_dns_name` | ALB DNS name (use as Route 53 alias target) |
| `alb_zone_id` | ALB hosted zone ID (for Route 53 alias records) |
| `https_listener_arn` | ARN of the HTTPS:443 listener |
| `http_listener_arn` | ARN of the HTTP:80 redirect listener |
| `target_group_arns` | Map of target group key to ARN |
| `target_group_names` | Map of target group key to name |
