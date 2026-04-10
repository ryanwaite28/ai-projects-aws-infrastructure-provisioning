# Stack: `ecs-cluster`

Provisions an ECS Fargate cluster with a public ALB (internet-facing), a private ALB (internal), WAF, ACM certificate, and the three foundational security groups (public ALB, private ALB, ECS tasks).

This stack is consumed as a child module by `stacks/platform`. It can also be applied standalone when you need the compute tier without the full platform stack.

## What it creates

- ECS cluster (Fargate, Container Insights enabled)
- Public ALB + HTTPS listener + HTTP→HTTPS redirect
- Private ALB + HTTPS listener
- WAFv2 Web ACL attached to the public ALB (rate limiting + AWS managed rules)
- ACM wildcard certificate DNS-validated against the provided Route 53 zone
- Security groups: `public_alb`, `private_alb`, `ecs_tasks`

## Usage

```hcl
module "cluster" {
  source = "../../stacks/ecs-cluster"

  project     = "myapp"
  environment = "prod"
  region      = "us-east-1"

  vpc_id             = module.network.vpc_id
  vpc_cidr           = module.network.vpc_cidr
  public_subnet_ids  = module.network.public_subnet_ids
  private_subnet_ids = module.network.private_subnet_ids

  domain  = "example.com"
  zone_id = "Z1234567890ABCDEF"

  tags = { Team = "platform" }
}
```

## Required Inputs

| Name | Type | Description |
|---|---|---|
| `project` | `string` | Project name prefix |
| `environment` | `string` | Deployment environment |
| `region` | `string` | AWS region |
| `vpc_id` | `string` | VPC ID (from `base-network`) |
| `public_subnet_ids` | `list(string)` | Public subnet IDs for the public ALB |
| `private_subnet_ids` | `list(string)` | Private subnet IDs for the private ALB and ECS tasks |
| `vpc_cidr` | `string` | VPC CIDR for security group rules |
| `domain` | `string` | Apex domain for ACM wildcard certificate (e.g. `example.com`) |
| `zone_id` | `string` | Route 53 hosted zone ID for ACM DNS validation |

## Optional Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `cluster_name` | `string` | `"main"` | Short ECS cluster name |
| `container_insights_enabled` | `bool` | `true` | Enable CloudWatch Container Insights |
| `execute_command_enabled` | `bool` | `true` | Enable ECS Exec for debugging |
| `waf_rate_limit` | `number` | `2000` | Requests per 5-minute window per IP |
| `alb_access_log_bucket` | `string` | `null` | S3 bucket for ALB access logs |
| `alb_log_retention_days` | `number` | `30` | ALB access log retention |
| `tags` | `map(string)` | `{}` | Additional resource tags |

## Outputs

| Name | Description |
|---|---|
| `ecs_cluster_arn` | ECS cluster ARN |
| `ecs_cluster_name` | ECS cluster name |
| `public_alb_arn` | Public ALB ARN |
| `public_alb_dns` | Public ALB DNS name |
| `public_alb_listener_arn` | Public HTTPS listener ARN |
| `private_alb_arn` | Private ALB ARN |
| `private_alb_dns` | Private ALB DNS name |
| `private_alb_listener_arn` | Private HTTPS listener ARN |
| `sg_public_alb_id` | Public ALB security group ID |
| `sg_private_alb_id` | Private ALB security group ID |
| `sg_ecs_tasks_id` | ECS tasks security group ID |
| `waf_web_acl_arn` | WAFv2 Web ACL ARN |
| `acm_certificate_arn` | ACM wildcard certificate ARN |
