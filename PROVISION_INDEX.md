# PROVISION_INDEX.md

Portable reference guide for developers and AI workflows consuming this infrastructure template.
Copy this file into your application project to give your team and AI tools the context they need to correctly provision and wire up AWS infrastructure.

---

## What This Template Is

This repository is a Terraform module library and GitHub Actions workflow template for provisioning production-grade, multi-region AWS infrastructure. It is **not an application** — it is the infrastructure layer that your application projects reference.

### Repository structure

```
modules/          # 25 reusable Terraform modules (one AWS service each)
stacks/           # Pre-composed module bundles for common app patterns
environments/     # Per-environment Terraform roots (dev, qa, prod)
bootstrap/        # One-time setup: OIDC trust + S3/DynamoDB remote state
.github/workflows/ # Reusable GitHub Actions workflows for plan/apply/deploy
```

---

## Modules Quick Reference

Each module lives at `modules/<name>/`. Instantiate with:

```hcl
module "<label>" {
  source = "github.com/your-org/aws-infra-template//modules/<name>?ref=v1.0.0"
  # or local path: source = "../../modules/<name>"
  project     = var.project
  environment = var.environment
  region      = var.region
  # ...module-specific variables
}
```

### Networking & Security

| Module | Creates | Key Required Inputs |
|---|---|---|
| `network` | VPC, subnets (public/private/db), NAT GW, VPC Endpoints, Flow Logs | `azs`, `public_subnet_cidrs`, `private_subnet_cidrs`, `db_subnet_cidrs` |
| `alb` | Application Load Balancer, HTTPS listener, target groups | `vpc_id`, `subnet_ids` |
| `waf` | WAFv2 Web ACL (REGIONAL or CLOUDFRONT) | `name`, `scope` |
| `acm` | ACM certificate with DNS validation | `domain_name`, `zone_id` |
| `route53` | Hosted zone lookup/create + DNS records | `zone_name` |
| `kms` | Customer-managed KMS key + alias | `alias` |

### Compute

| Module | Creates | Key Required Inputs |
|---|---|---|
| `lambda` | Lambda function, execution role, log group, SQS event source | `function_name` |
| `ecs` | ECS Fargate cluster and/or service, task definition, auto-scaling | `cluster_name` |

### Storage

| Module | Creates | Key Required Inputs |
|---|---|---|
| `s3` | S3 bucket, encryption, lifecycle, replication | `bucket_suffix` |
| `ecr` | ECR repository, lifecycle policy, scan-on-push | `repository_name` |
| `ebs` | EBS volume | `volume_name`, `availability_zone` |
| `efs` | EFS file system, mount targets, access points | `name`, `subnet_ids`, `vpc_id`, `allowed_security_group_ids` |

### Databases

| Module | Creates | Key Required Inputs |
|---|---|---|
| `rds` | Aurora cluster (PostgreSQL/MySQL), instances, monitoring | `cluster_identifier`, `database_name`, `subnet_ids`, `vpc_security_group_ids` |
| `elasticache` | Redis replication group, subnet group | `cluster_id`, `subnet_ids`, `security_group_ids` |
| `dynamodb` | DynamoDB table, GSIs, TTL, PITR, Streams | `table_name`, `hash_key` |

### Messaging & Events

| Module | Creates | Key Required Inputs |
|---|---|---|
| `sqs` | SQS queue + optional DLQ | `queue_name` |
| `sns` | SNS topic + subscriptions | `topic_name` |
| `eventbridge` | EventBridge bus + rules + targets | *(none beyond project/env/region)* |
| `kinesis` | Kinesis Data Stream, enhanced fan-out consumers | `stream_name` |
| `firehose` | Kinesis Firehose delivery stream to S3 | `stream_name`, `s3_bucket_arn` |

### Frontend & API

| Module | Creates | Key Required Inputs |
|---|---|---|
| `cloudfront` | CloudFront distribution, OAC, custom errors | `name`, `origins`, `default_cache_behavior` |
| `api-gateway` | API Gateway HTTP (v2) or REST (v1), routes, authorizers | `api_name` |

### Observability & IAM

| Module | Creates | Key Required Inputs |
|---|---|---|
| `monitoring` | SNS alerts topic, CloudWatch alarms, log groups, dashboard | *(none beyond project/env/region)* |
| `secrets-manager` | Secrets Manager secret, rotation, resource policy | `secret_name` |
| `iam` | IAM role, trust policy, inline/managed policies | `role_name` |

---

## Stacks Quick Reference

Stacks are pre-wired compositions of modules. Use them to deploy a complete workload pattern in one shot. Reference from `environments/<env>/main.tf`:

```hcl
module "api" {
  source = "../../stacks/bff"
  # ...
}
```

| Stack | Pattern | Key Services |
|---|---|---|
| `base-network` | VPC + subnets + endpoints | `network` |
| `platform` | Shared cluster, databases, queues, secrets | `ecs`, `rds`, `elasticache`, `sqs`, `sns`, `kms`, SSM outputs |
| `ecs-cluster` | ECS cluster + ALB + security groups | `ecs`, `alb` |
| `bff` | Backend-for-Frontend HTTP service on ECS | `ecs`, `alb`, `route53`, `acm` |
| `microservice` | Internal ECS service behind private ALB | `ecs`, `alb` |
| `serverless` | Lambda function + API Gateway | `lambda`, `api-gateway` |
| `async-worker` | Lambda/ECS consuming from SQS | `lambda` or `ecs`, `sqs` |
| `scheduled-job` | EventBridge cron → Lambda/ECS | `lambda` or `ecs`, `eventbridge` |
| `notification` | SNS fan-out to SQS + email | `sns`, `sqs` |
| `event-driven` | EventBridge → Lambda/ECS pipeline | `eventbridge`, `lambda` or `ecs` |
| `data-pipeline` | Kinesis → Firehose → S3 | `kinesis`, `firehose`, `s3` |
| `data-layer` | Aurora + ElastiCache + DynamoDB | `rds`, `elasticache`, `dynamodb` |
| `frontend` | S3 + CloudFront + WAF + ACM | `s3`, `cloudfront`, `waf`, `acm` |
| `webhook-ingestion` | API Gateway → SQS → Lambda | `api-gateway`, `sqs`, `lambda` |

---

## Naming Convention

All resources follow this pattern:

```
{project}-{environment}-{region_short}[-{resource_type}[-{qualifier}]]
```

Region short codes:

| Region | Short Code |
|---|---|
| `us-east-1` | `use1` |
| `us-east-2` | `use2` |
| `us-west-2` | `usw2` |
| `eu-west-1` | `euw1` |

**Examples:**
- `myapp-prod-use1-vpc`
- `myapp-prod-use1-alb-public`
- `myapp-prod-use1-fn-order-processor`
- `myapp-prod-use1-redis-session`
- `myapp/prod/db/primary/password` (Secrets Manager path)
- `myapp/prod/api` (ECR repository)

---

## Cross-Stack Wiring via SSM

The `platform` stack publishes all shared infrastructure outputs to SSM Parameter Store under a prefix. App stacks read these parameters instead of hard-coding values or using Terraform remote state.

### SSM prefix pattern

```
/{project}/{environment}/infra/
```

### Reading SSM parameters in an app stack

```hcl
variable "ssm_prefix" {
  default = "/myapp/prod/infra"
}

data "aws_ssm_parameter" "vpc_id" {
  name = "${var.ssm_prefix}/vpc_id"
}

data "aws_ssm_parameter" "private_subnet_ids" {
  name = "${var.ssm_prefix}/private_subnet_ids"
}
```

### Key SSM paths published by `stacks/platform`

| SSM Path | Value |
|---|---|
| `{prefix}/vpc_id` | VPC ID |
| `{prefix}/private_subnet_ids` | Comma-separated private subnet IDs |
| `{prefix}/db_subnet_ids` | Comma-separated DB subnet IDs |
| `{prefix}/public_subnet_ids` | Comma-separated public subnet IDs |
| `{prefix}/ecs_cluster_arn` | ECS cluster ARN |
| `{prefix}/rds_endpoint` | Aurora writer endpoint |
| `{prefix}/rds_reader_endpoint` | Aurora reader endpoint |
| `{prefix}/rds_secret_arn` | RDS managed password secret ARN |
| `{prefix}/redis_primary_endpoint` | Redis primary endpoint |
| `{prefix}/redis_port` | Redis port |
| `{prefix}/sqs_orders_url` | Orders queue URL |
| `{prefix}/sqs_orders_arn` | Orders queue ARN |
| `{prefix}/kms_key_arn` | Shared KMS key ARN |

---

## Required Tags

Every resource must include these tags. They are applied automatically by all modules:

```hcl
tags = {
  Project     = var.project
  Environment = var.environment
  Region      = var.region
  ManagedBy   = "terraform"
  Repository  = var.repository
}
```

Pass additional tags via the `tags` input:

```hcl
tags = {
  Team        = "backend"
  CostCenter  = "eng-platform"
}
```

---

## GitHub Actions Workflows

### Reusable Terraform workflows

Call these from your application repository's workflows using `workflow_call`:

| Workflow | Trigger | What It Does |
|---|---|---|
| `tf-plan.yml` | PR / on-demand | Runs `terraform plan`, posts diff to PR |
| `tf-apply.yml` | Push to main / on-demand | Runs `terraform apply` with auto-approve |
| `tf-destroy.yml` | On-demand (manual) | Destroys infrastructure (protected by required input) |
| `tf-drift.yml` | Scheduled (daily) | Detects configuration drift |

### Application deployment workflows

| Workflow | What It Does | Key Inputs |
|---|---|---|
| `deploy-lambda.yml` | Builds + uploads ZIP to S3, updates function code | `function_name`, `s3_bucket`, `s3_key` |
| `deploy-service.yml` | Builds + pushes Docker image to ECR, updates ECS service | `ecr_repository`, `cluster_name`, `service_name` |
| `deploy-frontend.yml` | Builds SPA, syncs to S3, invalidates CloudFront | `s3_bucket`, `distribution_id` |
| `deploy-webhook-ingestion.yml` | Deploys webhook ingestion Lambda | `function_name` |

### Calling a workflow from your application repo

```yaml
# .github/workflows/deploy-prod.yml
on:
  push:
    branches: [main]

jobs:
  deploy:
    uses: your-org/aws-infra-template/.github/workflows/deploy-service.yml@v1.0.0
    with:
      environment:    prod
      aws_region:     us-east-1
      ecr_repository: myapp/prod/api
      cluster_name:   myapp-prod-use1-ecs-main
      service_name:   myapp-prod-use1-svc-api
      image_tag:      ${{ github.sha }}
    secrets:
      aws_role_arn: ${{ secrets.AWS_ROLE_ARN }}
```

---

## OIDC Authentication (No IAM Users)

All CI/CD uses OIDC to assume AWS roles — no long-lived access keys.

### How it works

1. `bootstrap/oidc` creates the OIDC trust between GitHub and your AWS account.
2. The Terraform execution role (`TerraformExecutionRole`) is created by bootstrap — it is the role `tf-plan` and `tf-apply` assume.
3. The DevOps deployment role (`DevOpsRole`) is created by `stacks/platform` — it is the role app deploy workflows assume.

### GitHub repository environment secrets

Set `AWS_ROLE_ARN` as an **environment-scoped** secret (not repository-scoped):

| GitHub Environment | AWS Account | Role |
|---|---|---|
| `dev` | dev account | `TerraformExecutionRole` or `DevOpsRole` (dev) |
| `qa` | qa account | `TerraformExecutionRole` or `DevOpsRole` (qa) |
| `prod` | prod account | `TerraformExecutionRole` or `DevOpsRole` (prod) |

**Why environment-scoped?** Prevents a dev workflow from accidentally assuming the prod role.

```yaml
jobs:
  deploy:
    environment: prod   # must match the GitHub Environment name
    permissions:
      id-token: write
      contents: read
```

---

## Remote State & Backend Configuration

### How it works

Terraform requires a backend to store state remotely, but does **not** allow variables inside `terraform {}` blocks. The solution used here is a **partial backend configuration**:

Each environment root (`environments/dev/main.tf`, etc.) declares an empty backend block:

```hcl
terraform {
  backend "s3" {
    # Values supplied at init time via: -backend-config=config/backend-dev.hcl
  }
}
```

The `config/backend-<env>.hcl` file provides the actual values at `terraform init` time:

```hcl
# config/backend-dev.hcl
bucket         = "myapp-terraform-state"   # S3 bucket (shared per AWS account)
key            = "dev/terraform.tfstate"   # object path — scoped to this environment
region         = "us-east-1"
dynamodb_table = "myapp-terraform-locks"   # shared lock table
encrypt        = true
```

Terraform merges the `.hcl` file into the empty block at init. All subsequent `plan`/`apply`/`destroy` runs use the resolved config automatically — no flags needed after init.

### Shared per account, isolated by key path

One S3 bucket and one DynamoDB table serve all stacks within the same AWS account. Different stacks get different state files by using different `key` paths:

```
myapp-terraform-state/           ← one bucket per account
  dev/terraform.tfstate          ← dev environment
  qa/terraform.tfstate           ← qa environment
  prod/terraform.tfstate         ← prod environment
  dev/payments/terraform.tfstate ← additional stacks use sub-paths
```

DynamoDB locks are keyed by the state file path, so concurrent Terraform runs on different stacks never block each other.

### Multi-account isolation

In a multi-account org (recommended for prod), each AWS account gets its own bucket and table — provisioned once by `bootstrap/state-backend`. This means:

- A compromised CI role in the dev account cannot read prod state
- Terraform state (which contains plaintext secrets) never crosses account boundaries
- The same `config/backend-<env>.hcl` pattern works across all accounts; just point `bucket` at the account-specific bucket name

### GitHub Actions usage

The workflow selects the right backend config based on the `environment` input:

```bash
terraform init -backend-config=config/backend-${{ inputs.environment }}.hcl
terraform plan  # uses the resolved backend automatically
terraform apply
```

The `backend-*.hcl` files are committed to the repo (they contain no secrets — just bucket names and region).

---

## Dependency Order for Fresh Deploys

Apply in this order on a new environment:

1. `bootstrap/state-backend` — S3 bucket + DynamoDB for Terraform state
2. `bootstrap/oidc` — OIDC provider + Terraform execution role
3. `environments/<env>` (base-network stack) — VPC and subnets
4. `environments/<env>` (platform stack) — ECS cluster, databases, queues, KMS → publishes SSM parameters
5. App stacks — consume SSM parameters from platform

---

## Common Patterns

### Pattern: Lambda reading from SQS

```hcl
module "queue" {
  source     = "../../modules/sqs"
  queue_name = "orders"
  # ...
}

module "processor" {
  source        = "../../modules/lambda"
  function_name = "order-processor"
  runtime       = "python3.12"
  handler       = "handler.process"

  sqs_event_source_arns = [module.queue.queue_arn]
  sqs_batch_size        = 10
  # ...
}
```

### Pattern: ECS service behind ALB

```hcl
module "alb" {
  source = "../../modules/alb"
  target_groups = {
    api = { port = 8080, target_type = "ip" }
  }
  # ...
}

module "api" {
  source           = "../../modules/ecs"
  target_group_arn = module.alb.target_group_arns["api"]
  container_port   = 8080
  # ...
}
```

### Pattern: EventBridge cron → Lambda

```hcl
module "bus" {
  source = "../../modules/eventbridge"
  rules = {
    daily-job = {
      schedule_expression = "cron(0 8 * * ? *)"
      targets = [{ id = "fn", arn = module.job.function_arn }]
    }
  }
}
```

### Pattern: S3 + CloudFront SPA

```hcl
module "assets" {
  source        = "../../modules/s3"
  bucket_suffix = "frontend-assets"
}

module "cdn" {
  source = "../../modules/cloudfront"
  origins = {
    s3 = {
      domain_name    = module.assets.bucket_domain_name
      origin_id      = "s3"
      s3_oac_enabled = true
    }
  }
  default_cache_behavior = { target_origin_id = "s3" }
}
```

### Pattern: Aurora + Secrets Manager password

```hcl
module "db" {
  source             = "../../modules/rds"
  cluster_identifier = "primary"
  database_name      = "appdb"
  subnet_ids         = local.db_subnet_ids
  vpc_security_group_ids = [aws_security_group.rds.id]
  # RDS manages the password automatically when master_password_secret_arn is null
}

# Pass the auto-managed secret ARN to your application via environment variable
# module.db.master_user_secret_arn → ECS task environment / Lambda env var
```

---

## Secrets Management

**Rule:** Never put secrets in `.tfvars` files or environment variables committed to git.

| Secret Type | How to Manage |
|---|---|
| DB passwords | Use RDS-managed rotation (`master_password_secret_arn = null`) |
| API keys, tokens | Create with `secrets-manager` module; populate out-of-band |
| TLS certificates | Use `acm` module; DNS-validated automatically |
| IAM credentials | Use OIDC — no IAM user access keys |
| CI/CD secrets | GitHub Environment secrets (`AWS_ROLE_ARN`) |

Applications retrieve secrets at runtime via the AWS SDK using the secret ARN:

```python
import boto3, json
client = boto3.client("secretsmanager")
secret = json.loads(client.get_secret_value(SecretId=os.environ["DB_SECRET_ARN"])["SecretString"])
```

---

## IAM Rules

- No wildcard (`*`) actions unless explicitly justified with a comment.
- Every Lambda/ECS task gets a **dedicated** execution role — no sharing.
- All CI/CD uses OIDC assume-role — no IAM users with access keys.
- Use the `iam` module for all role creation; never write `aws_iam_role` inline in stacks.

---

## AI Workflow Guidance

When generating Terraform for this project:

1. **Check this index first** to identify the right module(s) for the resource type.
2. **Use module source paths** as `../../modules/<name>` (local) or `github.com/your-org/aws-infra-template//modules/<name>?ref=vX.Y.Z` (remote).
3. **Always pass** `project`, `environment`, and `region` to every module.
4. **Use SSM parameters** to read cross-stack values — do not hardcode VPC IDs, subnet IDs, or cluster ARNs.
5. **Never hardcode** account IDs, ARNs, or region strings. Use variables or data sources.
6. **Read the module README** (`modules/<name>/README.md`) for the full variable reference before generating code.
7. **Check `examples/basic/main.tf`** in each module for a working starting point.
8. **Secrets** go through `secrets-manager` or SSM SecureString — never in `.tfvars`.
9. **Tags** are applied automatically by modules; add team/cost-center tags via the `tags` input.
10. For new workload patterns, check `stacks/` first — a pre-composed stack likely already covers the pattern.
