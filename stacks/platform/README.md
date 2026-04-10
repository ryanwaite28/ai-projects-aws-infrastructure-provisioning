# Stack: `platform`

The full shared infrastructure stack. Composes `base-network` + `ecs-cluster` + databases + queues + KMS + monitoring + IAM into a single apply. All outputs are published to SSM Parameter Store so application stacks can consume them without direct state access.

**Apply this once per environment.** Application stacks (`bff`, `microservice`, etc.) read from SSM rather than depending on platform state.

## What it creates

- **Networking** — VPC, subnets, NAT Gateways, VPC Endpoints (via `base-network`)
- **Compute** — ECS cluster, public ALB, private ALB, WAF, ACM certificate (via `ecs-cluster`)
- **Security groups** — RDS, ElastiCache, Lambda (in addition to ALB + ECS groups from ecs-cluster)
- **KMS** — Shared customer-managed key for encryption across all services
- **IAM** — ECS task execution role, DevOps deployment role (for CI/CD OIDC), permission boundary policy
- **Monitoring** — SNS alerts topic, CloudWatch alarms
- **SSM Parameters** — All key outputs written under `/{project}/{environment}/infra/` for cross-stack consumption

## Usage

```hcl
module "platform" {
  source = "../../stacks/platform"

  project     = "myapp"
  environment = "prod"
  region      = "us-east-1"

  vpc_cidr             = "10.0.0.0/16"
  azs                  = ["us-east-1a", "us-east-1b", "us-east-1c"]
  public_subnet_cidrs  = ["10.0.0.0/24",  "10.0.1.0/24",  "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
  db_subnet_cidrs      = ["10.0.20.0/24", "10.0.21.0/24", "10.0.22.0/24"]

  domain  = "example.com"
  zone_id = "Z1234567890ABCDEF"

  github_oidc_provider_arn = data.aws_iam_openid_connect_provider.github.arn
  github_repo_subject      = "repo:your-org/your-app-repo:*"

  alert_emails = ["oncall@example.com"]
  tags         = { Team = "platform" }
}
```

## Reading platform outputs in app stacks

```hcl
# App stacks read from SSM — no Terraform remote state access needed
data "aws_ssm_parameter" "vpc_id" {
  name = "/myapp/prod/infra/vpc_id"
}
data "aws_ssm_parameter" "ecs_cluster_arn" {
  name = "/myapp/prod/infra/ecs_cluster_arn"
}
```

Or pass `ssm_prefix = "/myapp/prod/infra"` to `bff` / `microservice` stacks and they handle SSM lookups automatically.

## Required Inputs

| Name | Type | Description |
|---|---|---|
| `project` | `string` | Project name prefix |
| `environment` | `string` | Deployment environment |
| `region` | `string` | AWS region |
| `azs` | `list(string)` | Availability zones (3 recommended for prod) |
| `public_subnet_cidrs` | `list(string)` | Public subnet CIDRs (one per AZ) |
| `private_subnet_cidrs` | `list(string)` | Private subnet CIDRs (one per AZ) |
| `db_subnet_cidrs` | `list(string)` | Isolated/DB subnet CIDRs (one per AZ) |
| `domain` | `string` | Apex domain for ACM wildcard certificate |
| `zone_id` | `string` | Route 53 hosted zone ID |
| `github_oidc_provider_arn` | `string` | ARN of the GitHub OIDC provider (from `bootstrap/oidc`) |
| `github_repo_subject` | `string` | OIDC subject for the app repo (e.g. `repo:org/repo:*`) |

## Optional Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `vpc_cidr` | `string` | `"10.0.0.0/16"` | VPC CIDR |
| `single_nat_gateway` | `bool` | `false` | Share one NAT Gateway (set `true` in dev/qa) |
| `interface_endpoints` | `set(string)` | 7 services | Interface VPC Endpoints to create |
| `cluster_name` | `string` | `"main"` | ECS cluster short name |
| `execute_command_enabled` | `bool` | `true` | Enable ECS Exec |
| `waf_rate_limit` | `number` | `2000` | WAF rate limit per 5-minute window |
| `alb_access_log_bucket` | `string` | `null` | S3 bucket for ALB access logs |
| `devops_role_name` | `string` | `"DevOpsRole"` | Name for the CI/CD deployment role |
| `alert_emails` | `list(string)` | `[]` | Email addresses for CloudWatch alerts |
| `tags` | `map(string)` | `{}` | Additional resource tags |

## Outputs

| Name | Description |
|---|---|
| `vpc_id` | VPC ID |
| `public_subnet_ids` | Public subnet IDs |
| `private_subnet_ids` | Private subnet IDs |
| `db_subnet_ids` | DB/isolated subnet IDs |
| `ecs_cluster_arn` | ECS cluster ARN |
| `ecs_cluster_name` | ECS cluster name |
| `public_alb_arn` / `public_alb_dns` / `public_alb_listener_arn` | Public ALB details |
| `private_alb_arn` / `private_alb_dns` / `private_alb_listener_arn` | Private ALB details |
| `sg_public_alb_id` / `sg_private_alb_id` / `sg_ecs_tasks_id` | Security group IDs |
| `sg_rds_id` / `sg_elasticache_id` / `sg_lambda_id` | Database/function security group IDs |
| `platform_kms_key_arn` | Shared KMS key ARN |
| `ecs_task_execution_role_arn` | ECS task execution role ARN |
| `devops_role_arn` | DevOps CI/CD role ARN |
| `platform_boundary_policy_arn` | Permission boundary policy ARN |
| `acm_certificate_arn` | Wildcard ACM certificate ARN |
| `alerts_topic_arn` | SNS alerts topic ARN |
| `ssm_prefix` | SSM prefix for all platform outputs (`/{project}/{environment}/infra`) |
