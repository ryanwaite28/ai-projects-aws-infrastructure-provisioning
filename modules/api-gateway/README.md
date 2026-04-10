# Module: `api-gateway`

Creates an API Gateway HTTP (v2) or REST (v1) API with routes, JWT/Lambda authorizers, optional VPC Link for private ALB integration, custom domain, and WAF association.

Full name pattern: `{project}-{environment}-{region_short}-apigw-{api_name}`

## Usage

### HTTP API with Lambda integration

```hcl
module "api" {
  source = "../../modules/api-gateway"

  project     = "myapp"
  environment = "prod"
  region      = "us-east-1"
  api_name    = "public"
  api_type    = "HTTP"
  description = "Public-facing HTTP API"

  cors_configuration = {
    allow_origins = ["https://app.example.com"]
    allow_methods = ["GET", "POST", "PUT", "DELETE"]
    allow_headers = ["Content-Type", "Authorization"]
  }

  authorizers = {
    cognito = {
      jwt_configuration = {
        audience = ["your-client-id"]
        issuer   = "https://cognito-idp.us-east-1.amazonaws.com/us-east-1_XXXXXXX"
      }
    }
  }

  routes = {
    "GET /items" = {
      integration_uri    = module.list_fn.function_invoke_arn
      authorizer_key     = "cognito"
      authorization_type = "JWT"
    }
    "POST /items" = {
      integration_uri    = module.create_fn.function_invoke_arn
      authorizer_key     = "cognito"
      authorization_type = "JWT"
    }
  }

  custom_domain_name            = "api.example.com"
  custom_domain_certificate_arn = module.cert.certificate_arn
  waf_acl_arn                   = module.waf.web_acl_arn

  tags = { Team = "backend" }
}
```

### HTTP API with private ALB via VPC Link

```hcl
module "internal_api" {
  source = "../../modules/api-gateway"
  # ...
  vpc_link_subnet_ids         = module.network.private_subnet_ids
  vpc_link_security_group_ids = [aws_security_group.vpc_link.id]

  routes = {
    "ANY /{proxy+}" = {
      integration_type   = "HTTP_PROXY"
      integration_uri    = module.alb.https_listener_arn
    }
  }
}
```

## Required Inputs

| Name | Type | Description |
|---|---|---|
| `project` | `string` | Project name prefix |
| `environment` | `string` | Deployment environment |
| `region` | `string` | AWS region |
| `api_name` | `string` | Short API name |

## Optional Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `api_type` | `string` | `"HTTP"` | `HTTP` (v2) or `REST` (v1) |
| `description` | `string` | `""` | Human-readable description |
| `stage_name` | `string` | `"$default"` | Stage name |
| `auto_deploy` | `bool` | `true` | Auto-deploy on change (HTTP v2 only) |
| `cors_configuration` | `object` | `null` | CORS configuration for HTTP APIs |
| `routes` | `map(object)` | `{}` | Route configurations (key: `METHOD /path`) |
| `authorizers` | `map(object)` | `{}` | JWT or Lambda authorizer configurations |
| `vpc_link_subnet_ids` | `list(string)` | `[]` | Subnet IDs for VPC Link |
| `vpc_link_security_group_ids` | `list(string)` | `[]` | Security groups for VPC Link |
| `custom_domain_name` | `string` | `null` | Custom domain name |
| `custom_domain_certificate_arn` | `string` | `null` | ACM certificate ARN for custom domain |
| `waf_acl_arn` | `string` | `null` | WAFv2 Web ACL ARN |
| `log_retention_days` | `number` | `30` | Access log retention days |
| `tags` | `map(string)` | `{}` | Additional resource tags |

## Outputs

| Name | Description |
|---|---|
| `api_id` | API Gateway ID |
| `api_endpoint` | Default API endpoint URL |
| `stage_invoke_url` | Stage invoke URL |
| `stage_arn` | Stage ARN |
| `custom_domain_name` | Custom domain name |
| `custom_domain_target` | Target DNS name for Route 53 alias |
| `custom_domain_zone_id` | Hosted zone ID for Route 53 alias |
| `vpc_link_id` | VPC Link ID |
