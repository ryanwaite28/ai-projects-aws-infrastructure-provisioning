# AWS Infrastructure Provisioning — Terraform Template

## Overview

This project is a general-purpose, modular Terraform template for provisioning production-grade AWS infrastructure. It is designed to support a **highly available, multi-region application system architecture** and is optimized for use within a **GitHub Actions** CI/CD environment.

The template provides composable modules covering every major infrastructure layer — networking, compute, data, messaging, security, and delivery — so teams can assemble a full system architecture from building blocks rather than writing bespoke Terraform from scratch.

---

## Using This Template

This repository is designed to be copied (not forked) as the starting point for a new project's infrastructure repo. Follow the steps below to go from template to a working project.

### Step 1 — Create Your New Repository

**Option A — GitHub UI (recommended)**

This repo is configured as a GitHub Template Repository. Navigate to it on GitHub and click **"Use this template" → "Create a new repository"**. Give it a name following the convention `{project-name}-infrastructure` (e.g., `myapp-infrastructure`).

**Option B — CLI**

```bash
# Clone the template without its git history
git clone --depth=1 https://github.com/<your-org>/aws-infrastructure-provisioning.git myapp-infrastructure
cd myapp-infrastructure
rm -rf .git
git init && git add . && git commit -m "chore: init from infrastructure template"
```

Then create a new repo on GitHub and push:

```bash
git remote add origin https://github.com/<your-org>/myapp-infrastructure.git
git push -u origin main
```

---

### Step 2 — Replace Template Placeholders

Search the repo for the placeholder token `CHANGEME` and replace every instance with your project-specific values. Key locations:

| File/Directory | What to change |
|---|---|
| `environments/*/terraform.tfvars` | `project`, `region`, `secondary_region`, domain names |
| `environments/*/main.tf` | Which stacks/modules your project actually needs |
| `config/backend-*.hcl` | S3 bucket name, DynamoDB table name, region per account |
| `.github/workflows/*.yml` | GitHub org/repo name, AWS account IDs, secret names |
| `bootstrap/oidc/terraform.tfvars` | `github_org`, `github_repo` |
| `bootstrap/state-backend/terraform.tfvars` | `account_name`, `region` |

Quick find-and-replace:

```bash
# Preview all occurrences
grep -r "CHANGEME" .

# Replace with your project name (macOS/BSD sed)
find . -type f -not -path './.git/*' \
  -exec sed -i '' 's/CHANGEME/myapp/g' {} +
```

---

### Step 3 — Remove Modules You Don't Need

The template includes every available module. Delete the modules and stack references your project will not use to keep the repo clean.

```bash
# Example: remove ElastiCache and CloudFront if not needed
rm -rf modules/elasticache modules/cloudfront

# Then remove any references from stacks/ and environments/
grep -r "elasticache\|cloudfront" stacks/ environments/
# Edit each file to remove the unused module blocks
```

Also remove the corresponding sections from `PROJECT.md` and `CLAUDE.md`.

---

### Step 4 — Configure GitHub Repository Settings

In your new GitHub repository:

1. **Enable the repository as a template** (Settings → General → Template repository) if you want it to serve as a template itself downstream.
2. **Add required GitHub Actions secrets** (Settings → Secrets and variables → Actions):
   ```
   AWS_ROLE_ARN_DEV       # IAM role ARN from bootstrap/oidc in the dev account
   AWS_ROLE_ARN_QA        # IAM role ARN from bootstrap/oidc in the qa account
   AWS_ROLE_ARN_PROD      # IAM role ARN from bootstrap/oidc in the prod account
   AWS_ROLE_ARN_OPS       # IAM role ARN from bootstrap/oidc in the ops account
   ```
3. **Set branch protection on `main`**:
   - Require PR before merging
   - Require the `tf-plan` status check to pass
   - Require at least 1 approval for prod-touching changes

4. **Add environment protection rules** (Settings → Environments):
   - Create environments: `dev`, `qa`, `prod`
   - For `prod`: enable required reviewers and a deployment wait timer

---

### Step 5 — Run the Bootstrap Runbook

Before any CI pipeline can run, the one-time manual bootstrap must be completed. See the **Bootstrap Runbook** section below for the full sequence (AWS Org → accounts → SSO → remote state → OIDC).

---

### Step 6 — Verify End-to-End

Once bootstrap is complete, open a test PR with a trivial change (e.g., add a tag) to an `environments/dev/` variable file. Confirm:

- [ ] `tf-plan` workflow triggers and posts a plan comment on the PR
- [ ] Merging to `main` triggers `tf-apply` for dev
- [ ] Plan output shows only the expected change (no unexpected drift)

---

### Ongoing: Keeping in Sync with the Template

If the upstream template receives new modules or workflow improvements you want to pull in:

```bash
# Add the template as a remote
git remote add template https://github.com/<your-org>/aws-infrastructure-provisioning.git
git fetch template

# Cherry-pick or merge specific changes
git checkout -b chore/sync-template-vX.Y.Z
git merge template/main --allow-unrelated-histories --no-commit

# Review the diff carefully — resolve conflicts in your favour for env-specific files
git diff --cached
```

Only pull in modules or workflow changes that are relevant to your project. Do not blindly merge.

---

## Design Principles

- **Modular** — each AWS service or concern is an isolated, reusable Terraform module
- **Multi-region by default** — every stateful module (S3, RDS, DynamoDB, ElastiCache) accepts replication / read-replica configuration
- **Least-privilege IAM** — roles and policies are scoped tightly per service; no wildcard admin roles
- **Environment-parity** — `dev`, `qa`, and `prod` environments are driven by `.tfvars` overlays, not code branches
- **GitOps-first** — all provisioning runs through GitHub Actions OIDC; no long-lived AWS access keys
- **Separation of concerns** — base infrastructure (VPC, IAM, S3 state backend) is provisioned once by ops; application infrastructure is provisioned per environment by CI

---

## Repository Structure

```
.
├── PROJECT.md                   # This file
├── README.md                    # Quick-start guide
│
├── bootstrap/                   # One-time account & org setup (run manually)
│   ├── organizations/           # AWS Org, OUs, SCPs
│   ├── accounts/                # Sub-account creation (ops/dev/qa/prod)
│   ├── iam-identity-center/     # SSO / IAM Identity Center setup
│   ├── oidc/                    # GitHub Actions OIDC provider
│   └── state-backend/           # S3 + DynamoDB for Terraform remote state
│
├── modules/                     # Reusable Terraform modules
│   ├── network/                 # VPC, subnets, routing, gateways, endpoints
│   ├── s3/                      # Buckets, replication, versioning, lifecycle
│   ├── dynamodb/                # Tables, GSIs, TTL, PITR, replication
│   ├── iam/                     # Roles, policies, instance profiles
│   ├── sqs/                     # Queues, DLQs, encryption, policies
│   ├── sns/                     # Topics, subscriptions, fan-out policies
│   ├── eventbridge/             # Event buses, rules, targets, pipes
│   ├── lambda/                  # Functions, layers, aliases, event sources
│   ├── rds/                     # Aurora/RDS cluster, parameter groups, proxies
│   ├── elasticache/             # Redis/Valkey cluster, subnet groups
│   ├── ebs/                     # EBS volumes, snapshots, encryption
│   ├── efs/                     # EFS file systems, mount targets, access points
│   ├── cloudfront/              # Distributions, origins, behaviors, WAF
│   ├── alb/                     # Public & private ALBs, listeners, target groups
│   ├── api-gateway/             # REST & HTTP APIs, stages, authorizers, VPC links
│   ├── ecs/                     # Cluster, service, task definition, autoscaling
│   ├── ecr/                     # Container registries, lifecycle policies
│   ├── kinesis/                 # Data Streams, shards, enhanced fan-out
│   ├── firehose/                # Delivery streams, S3/Redshift/OpenSearch targets
│   ├── acm/                     # TLS certificates, DNS validation
│   ├── route53/                 # Hosted zones, records, health checks
│   ├── waf/                     # Web ACLs, managed rule groups
│   ├── secrets-manager/         # Secrets, rotation, resource policies
│   ├── kms/                     # Keys, aliases, key policies
│   └── monitoring/              # CloudWatch dashboards, alarms, log groups
│
├── environments/                # Per-environment root modules
│   ├── dev/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── terraform.tfvars
│   ├── qa/
│   └── prod/
│
├── stacks/                      # Opinionated compositions of modules
│   ├── platform/                # HIGH-LEVEL: base-network + ecs-cluster + security groups
│   ├── base-network/            # VPC + subnets + gateways + VPC endpoints
│   ├── ecs-cluster/             # ECS cluster + public/private ALBs (shared infra)
│   ├── data-layer/              # RDS + ElastiCache + DynamoDB + S3
│   ├── frontend/                # S3 + CloudFront + ACM + Route53
│   ├── bff/                     # ECR + ECS service + IAM + public ALB path
│   ├── microservice/            # ECR + ECS service + IAM + private ALB path
│   ├── serverless/              # Lambda + SQS + EventBridge + DynamoDB
│   ├── webhook-ingestion/       # API Gateway + FIFO SQS + Lambda processor
│   ├── event-driven/            # EventBridge + Lambda + DynamoDB (async)
│   ├── data-pipeline/           # Kinesis Streams + Firehose + S3 + Lambda
│   ├── notification/            # SNS + SQS fan-out + Lambda
│   ├── async-worker/            # SQS + ECS worker service (batch/job processing)
│   └── scheduled-job/           # EventBridge Scheduler + Lambda/ECS task
│
└── .github/
    └── workflows/
        ├── tf-plan.yml          # PR: terraform plan for changed environments
        ├── tf-apply.yml         # Push to main: terraform apply
        ├── tf-destroy.yml       # Manual: targeted destroy with approval gate
        ├── tf-drift.yml         # Scheduled: detect config drift
        └── bootstrap.yml        # Manual: one-time org/account bootstrap
```

---

## Modules Reference

### `modules/network`
Creates a complete VPC networking stack.

**Provisions:**
- VPC with configurable CIDR
- Public subnets (one per AZ) — with Internet Gateway
- Private subnets (one per AZ) — with NAT Gateway (one per AZ for HA)
- Isolated/DB subnets (no route to internet)
- Route tables and subnet associations
- VPC Endpoints (S3 Gateway, DynamoDB Gateway, and optional Interface endpoints)
- VPC Flow Logs to CloudWatch or S3

**Key variables:** `vpc_cidr`, `azs`, `public_subnets`, `private_subnets`, `db_subnets`, `enable_nat_gateway`, `single_nat_gateway`, `enable_vpce_s3`, `enable_vpce_dynamodb`, `interface_endpoints`

---

### `modules/s3`
Creates an S3 bucket with full lifecycle management.

**Provisions:**
- S3 bucket with configurable name and region
- Versioning toggle
- Server-side encryption (SSE-S3 or SSE-KMS)
- Lifecycle rules (transition to IA/Glacier, expiration)
- Optional cross-region replication (requires IAM role)
- VPC endpoint route (Gateway endpoint association)
- Block public access (on by default)
- Bucket policy

**Key variables:** `bucket_name`, `region`, `versioning_enabled`, `replication_enabled`, `replication_region`, `storage_class`, `kms_key_arn`, `vpc_endpoint_ids`

---

### `modules/dynamodb`
Creates a DynamoDB table with optional global replication.

**Provisions:**
- Table with hash key, optional sort key
- GSIs and LSIs
- TTL attribute
- Point-in-time recovery (PITR)
- Server-side encryption (AWS-owned or KMS)
- Optional Global Table replicas (multi-region)
- Auto-scaling for read/write capacity (or on-demand)

**Key variables:** `table_name`, `hash_key`, `range_key`, `attributes`, `gsis`, `ttl_attribute`, `billing_mode`, `replica_regions`, `kms_key_arn`

---

### `modules/iam`
Creates IAM roles, policies, and instance profiles.

**Provisions:**
- Execution roles (Lambda, ECS task, EC2)
- DevOps/pipeline roles (cross-account assume-role patterns)
- Inline and managed policy attachments
- Instance profiles
- Role boundaries (optional permission boundary policy)

**Key variables:** `role_name`, `trusted_services`, `trusted_role_arns`, `managed_policy_arns`, `inline_policies`, `permission_boundary_arn`

---

### `modules/sqs`
Creates SQS queues with dead-letter queue support.

**Provisions:**
- Standard or FIFO queue
- Dead-letter queue with configurable max receive count
- SSE encryption (SQS-managed or KMS)
- Queue policy
- CloudWatch alarms for DLQ depth

**Key variables:** `queue_name`, `fifo`, `visibility_timeout_seconds`, `message_retention_seconds`, `dlq_enabled`, `kms_key_arn`

---

### `modules/eventbridge`
Creates EventBridge event buses, rules, and targets.

**Provisions:**
- Custom event bus
- Rules with event pattern or schedule expression
- Targets (Lambda, SQS, ECS task, Step Functions)
- IAM role for EventBridge to invoke targets
- EventBridge Pipes (source → enrichment → target)

**Key variables:** `bus_name`, `rules`, `pipes`

---

### `modules/lambda`
Creates Lambda functions with full supporting infrastructure.

**Provisions:**
- Lambda function (zip or container image)
- Execution IAM role with scoped permissions
- Function URL or API Gateway integration
- Layers
- Aliases and weighted routing
- Event source mappings (SQS, DynamoDB streams, Kinesis)
- CloudWatch log group with retention
- Reserved/provisioned concurrency

**Key variables:** `function_name`, `runtime`, `handler`, `image_uri`, `memory_size`, `timeout`, `environment_variables`, `layers`, `sqs_trigger_arn`, `reserved_concurrency`

---

### `modules/rds`
Creates Aurora or RDS instances with Multi-AZ support.

**Provisions:**
- Aurora PostgreSQL or MySQL cluster (Serverless v2 or provisioned)
- RDS PostgreSQL/MySQL instance with Multi-AZ
- DB subnet group (uses isolated subnets)
- Parameter group
- Security group
- RDS Proxy (optional)
- Automated backups, deletion protection
- Performance Insights and Enhanced Monitoring
- Global cluster for cross-region (Aurora only)

**Key variables:** `cluster_identifier`, `engine`, `engine_version`, `instance_class`, `replica_count`, `database_name`, `db_subnet_ids`, `enable_proxy`, `deletion_protection`

---

### `modules/elasticache`
Creates ElastiCache Redis (Valkey) cluster.

**Provisions:**
- Redis cluster mode disabled or enabled (sharded)
- Multi-AZ with automatic failover
- Subnet group
- Security group
- Encryption at-rest and in-transit
- Parameter group
- Slow log and engine log to CloudWatch

**Key variables:** `cluster_id`, `node_type`, `num_cache_nodes`, `num_shards`, `num_replicas_per_shard`, `engine_version`, `at_rest_encryption`, `transit_encryption`

---

### `modules/cloudfront`
Creates a CloudFront distribution.

**Provisions:**
- Distribution with one or more origins (ALB, S3, custom)
- Cache behaviors (default + path patterns)
- Origin Access Control (OAC) for S3
- WAF Web ACL association
- Custom domain with ACM certificate
- Geo restriction
- Access logs to S3

**Key variables:** `origins`, `default_cache_behavior`, `ordered_cache_behaviors`, `aliases`, `acm_certificate_arn`, `waf_acl_arn`

---

### `modules/alb`
Creates Application Load Balancers for BFF and microservice tiers.

**Provisions:**
- Public ALB (internet-facing) — for BFF / frontend
- Private ALB (internal) — for microservice-to-microservice routing
- HTTPS listener with ACM certificate
- HTTP → HTTPS redirect listener
- Target groups (IP or instance)
- Listener rules (path-based, host-based routing)
- Security groups
- Access logs to S3

**Key variables:** `name`, `internal`, `vpc_id`, `subnet_ids`, `certificate_arn`, `target_groups`, `listener_rules`

---

### `modules/ecs`
Creates an ECS cluster with Fargate services.

**Provisions:**
- ECS cluster with Container Insights
- Task definition (Fargate; CPU/memory; container definitions)
- ECS service with desired count and deployment circuit breaker
- Service auto-scaling (CPU/memory/ALB request count targets)
- IAM task execution role and task role
- CloudWatch log group per container
- Service discovery (Cloud Map namespace + service)

**Key variables:** `cluster_name`, `service_name`, `task_cpu`, `task_memory`, `container_definitions`, `desired_count`, `subnets`, `security_groups`, `target_group_arn`, `autoscaling_min`, `autoscaling_max`

---

### `modules/ecr`
Creates Elastic Container Registry repositories.

**Provisions:**
- ECR repository
- Lifecycle policy (keep last N images, clean untagged)
- Repository policy (cross-account pull for ops → prod pattern)
- Image scan on push

**Key variables:** `repository_name`, `image_tag_mutability`, `scan_on_push`, `lifecycle_policy_rules`, `cross_account_pull_arns`

---

### `modules/acm`
Creates ACM TLS certificates with automated DNS validation.

**Provisions:**
- ACM certificate with SANs
- Route 53 DNS validation records
- Certificate in `us-east-1` for CloudFront use (via provider alias)

**Key variables:** `domain_name`, `subject_alternative_names`, `zone_id`

---

### `modules/route53`
Manages Route 53 hosted zones and records.

**Provisions:**
- Public or private hosted zone
- A/AAAA/CNAME/TXT records
- Alias records (ALB, CloudFront, API Gateway)
- Health checks and failover routing policies
- Latency-based and weighted routing

**Key variables:** `zone_name`, `records`, `private_zone`, `vpc_id`

---

### `modules/waf`
Creates WAF v2 Web ACLs.

**Provisions:**
- Web ACL (regional for ALB/API GW; CloudFront scope)
- AWS Managed Rule Groups (Core, Known Bad Inputs, SQL injection, etc.)
- Rate-limiting rules
- IP allow/block lists
- CloudWatch metrics and sampled requests

**Key variables:** `name`, `scope`, `managed_rule_groups`, `rate_limit_rules`, `ip_set_rules`

---

### `modules/secrets-manager`
Creates and manages Secrets Manager secrets.

**Provisions:**
- Secret with optional initial value
- Automatic rotation (Lambda-based)
- Resource policy (cross-account access)
- KMS encryption

**Key variables:** `secret_name`, `secret_value`, `kms_key_arn`, `rotation_lambda_arn`, `rotation_days`

---

### `modules/kms`
Creates KMS customer-managed keys.

**Provisions:**
- Symmetric encryption key
- Key alias
- Key policy with admin and usage principals
- Multi-region key (optional)

**Key variables:** `alias`, `description`, `admin_arns`, `usage_arns`, `multi_region`

---

### `modules/monitoring`
Creates CloudWatch observability resources.

**Provisions:**
- CloudWatch log groups with retention
- Metric alarms (CPU, memory, error rates, latency)
- Composite alarms
- CloudWatch dashboards
- SNS topic for alarm notifications
- CloudWatch Contributor Insights rules

**Key variables:** `alarms`, `dashboards`, `log_groups`, `sns_alert_emails`

---

### `modules/sns`
Creates SNS topics with subscription and fan-out support.

**Provisions:**
- Standard or FIFO SNS topic
- Subscriptions (SQS, Lambda, HTTP/S, email, SMS)
- Topic policy (cross-account publish, service-linked publish)
- SSE encryption (SNS-managed or KMS)
- Dead-letter queue for failed deliveries
- CloudWatch alarms on delivery failures and message age

**Key variables:** `topic_name`, `fifo`, `subscriptions`, `kms_key_arn`, `dlq_arn`, `topic_policy_statements`

---

### `modules/ebs`
Creates EBS volumes with encryption and snapshot management.

**Provisions:**
- EBS volume (gp3, io2, st1, sc1) with configurable IOPS and throughput
- KMS encryption (AWS-managed or CMK)
- Volume attachment to an EC2 instance or ECS task host
- Automated snapshot policy via DLM (Data Lifecycle Manager)
- Snapshot copy to secondary region for DR

**Key variables:** `volume_name`, `availability_zone`, `size_gb`, `volume_type`, `iops`, `throughput`, `kms_key_arn`, `instance_id`, `dlm_schedule`, `snapshot_copy_region`

---

### `modules/efs`
Creates an EFS file system for shared persistent storage across containers or instances.

**Provisions:**
- EFS file system with lifecycle management (IA transition)
- Encryption at rest (KMS CMK)
- Mount targets in each specified subnet (one per AZ)
- Security group controlling NFS access (port 2049)
- Access points (per-service isolated paths with POSIX user context)
- Backup policy (AWS Backup integration)
- EFS-to-EFS replication to secondary region (optional)

**Key variables:** `name`, `subnet_ids`, `vpc_id`, `allowed_security_group_ids`, `kms_key_arn`, `lifecycle_policy`, `access_points`, `replication_region`

---

### `modules/api-gateway`
Creates REST or HTTP APIs with stage management, authorizers, and VPC integration.

**Provisions:**
- HTTP API (v2) or REST API (v1) — configurable
- Routes and integrations (Lambda, ALB via VPC Link, HTTP)
- VPC Link for private ALB integration
- JWT or Lambda authorizer
- Usage plans and API keys (REST only)
- Custom domain with ACM certificate
- Stage with access logging to CloudWatch
- WAF Web ACL association
- CORS configuration

**Key variables:** `api_name`, `api_type`, `routes`, `integrations`, `authorizer`, `vpc_link_subnet_ids`, `vpc_link_security_group_ids`, `custom_domain`, `certificate_arn`, `stage_name`, `waf_acl_arn`

---

### `modules/kinesis`
Creates Kinesis Data Streams for real-time data ingestion.

**Provisions:**
- Kinesis Data Stream (provisioned or on-demand capacity mode)
- Configurable shard count and retention period (1–365 days)
- Server-side encryption (KMS)
- Enhanced fan-out consumers (registered consumers with dedicated throughput)
- CloudWatch alarms on iterator age, throttling, and incoming records
- IAM policies for producer and consumer roles

**Key variables:** `stream_name`, `shard_count`, `retention_period_hours`, `on_demand`, `kms_key_arn`, `enhanced_fan_out_consumers`, `producer_role_arns`, `consumer_role_arns`

---

### `modules/firehose`
Creates Kinesis Data Firehose delivery streams to S3, Redshift, or OpenSearch.

**Provisions:**
- Firehose delivery stream with configurable destination (S3, Redshift, OpenSearch, HTTP endpoint)
- S3 destination with prefix, error prefix, buffering hints, and Parquet/ORC conversion via Glue
- Data transformation via Lambda (optional)
- Dynamic partitioning for S3 (partition by event fields)
- Encryption in transit and at rest (KMS)
- IAM role for Firehose to write to destination
- CloudWatch logging for delivery errors

**Key variables:** `stream_name`, `destination`, `s3_bucket_arn`, `s3_prefix`, `s3_error_prefix`, `buffering_size_mb`, `buffering_interval_seconds`, `transformation_lambda_arn`, `dynamic_partitioning_enabled`, `kms_key_arn`, `redshift_config`, `opensearch_config`

---

## Stacks Reference

Stacks are opinionated, ready-to-deploy compositions of modules. Each stack is a standalone Terraform root module under `stacks/` that wires together the modules it needs. Stacks are consumed by environment root modules in `environments/`.

> **Dependency order:** `platform` (base-network + ecs-cluster) → `data-layer` → application stacks (frontend, bff, microservice, etc.)

---

### `stacks/platform`
**Purpose:** High-level "day zero" infrastructure stack. Provisions everything a DevOps team needs before a single application component is deployed — networking, shared compute, load balancers, and all security groups. This is the first stack applied to a fresh environment and the one maintained by the platform/ops team. Application teams treat its outputs as stable inputs.

**Composes:** `stacks/base-network`, `stacks/ecs-cluster`, `modules/iam`, `modules/kms`, `modules/secrets-manager`, `modules/monitoring`, `modules/route53`, `modules/acm`

> This stack calls `base-network` and `ecs-cluster` as child Terraform modules (via relative source paths), passing outputs between them internally. All outputs from both child stacks are re-exported so consuming application stacks only need to reference `platform` state.

---

#### Networking layer (`base-network`)
- VPC with configurable CIDR, across 3 AZs
- **Public subnets** — Internet Gateway, route table, subnet associations (ALB tier)
- **Private subnets** — NAT Gateways (one per AZ for HA), route tables (ECS/compute tier)
- **Isolated/DB subnets** — no route to internet (RDS, ElastiCache tier)
- VPC Gateway Endpoints: S3, DynamoDB (free, keeps traffic off internet)
- VPC Interface Endpoints: ECR API, ECR DKR, Secrets Manager, SSM, CloudWatch Logs, STS (keeps container pull and secret fetch inside VPC)
- VPC Flow Logs → CloudWatch Log Group (KMS-encrypted)

---

#### Security Groups
All security groups are defined and managed here so application stacks receive pre-wired, least-privilege groups rather than creating ad-hoc ones. The platform stack creates and outputs:

| Security Group | Allows Inbound | Allows Outbound |
|---|---|---|
| `sg_public_alb` | 0.0.0.0/0 on 443, 80 | `sg_ecs_tasks` on `var.container_port_range` |
| `sg_private_alb` | `sg_ecs_tasks` on 443 | `sg_ecs_tasks` on `var.container_port_range` |
| `sg_ecs_tasks` | `sg_public_alb` + `sg_private_alb` on container port range | 443 (HTTPS to VPC endpoints + internet via NAT) |
| `sg_rds` | `sg_ecs_tasks` on 5432 (PostgreSQL) | — |
| `sg_elasticache` | `sg_ecs_tasks` on 6379 (Redis) | — |
| `sg_efs` | `sg_ecs_tasks` on 2049 (NFS) | — |
| `sg_lambda` | — (Lambda is not an ALB target) | 443 to VPC endpoints; `sg_rds`; `sg_elasticache` |
| `sg_vpce` | VPC CIDR on 443 | — (interface endpoints only accept from VPC) |

Rules are implemented as separate `aws_security_group_rule` resources (not inline) so downstream modules can append rules without replacing the group.

---

#### ECS Compute layer (`ecs-cluster`)
- ECS cluster with Container Insights and execute-command enabled
- **Public ALB** (internet-facing, in public subnets, `sg_public_alb`)
  - HTTPS :443 listener with ACM wildcard certificate (`*.{domain}`)
  - HTTP :80 → HTTPS :443 redirect listener
  - Default action: 404 fixed response (services register listener rules)
  - WAF Web ACL (AWS managed rules: Core, Known Bad Inputs, rate limit)
  - Access logs → S3 bucket
- **Private ALB** (internal, in private subnets, `sg_private_alb`)
  - HTTPS :443 listener with ACM wildcard certificate
  - Default action: 404 fixed response
  - No WAF (internal traffic only)
  - Access logs → S3 bucket
- ALB access log S3 bucket with lifecycle expiration (configurable retention)
- CloudWatch alarms: public ALB 5xx rate, private ALB 5xx rate, unhealthy host counts on both

---

#### Platform IAM
- **`DevOpsRole`** — assumable by GitHub Actions OIDC and ops engineers; permissions cover ECS, ECR, ALB, Route53, ACM, Secrets Manager, SSM, CloudWatch, IAM role passing for ECS tasks
- **`ECSTaskExecutionRole`** — shared baseline execution role; policies: `AmazonECSTaskExecutionRolePolicy`, ECR pull, CloudWatch Logs write, Secrets Manager `GetSecretValue`, SSM `GetParameter`
- **`ECSTaskBaseRole`** — minimal baseline task role; policies: none by default; application-level `bff` and `microservice` stacks extend this via additional policy attachments
- IAM permission boundary policy (`PlatformBoundary`) — attached to all task roles; caps maximum effective permissions (no IAM self-modification, no org-level actions, no billing)

---

#### TLS & DNS
- ACM wildcard certificate for `*.{var.domain}` with DNS validation (automatically creates Route 53 validation records)
- ACM certificate in `us-east-1` (via provider alias) for CloudFront use — issued alongside the primary regional cert
- Route 53 public hosted zone (or data source if zone pre-exists)
- Route 53 A alias records:
  - `{env}.{domain}` → public ALB
  - `internal.{env}.{domain}` → private ALB

---

#### Platform Secrets & Config
- KMS CMK (`platform-{env}-cmk`) — used for: VPC Flow Logs, ECS exec session encryption, SSM SecureString parameters, Secrets Manager secrets
- SSM Parameter Store entries (SecureString) for cross-stack references:
  - `/platform/{env}/vpc_id`
  - `/platform/{env}/public_subnet_ids`
  - `/platform/{env}/private_subnet_ids`
  - `/platform/{env}/db_subnet_ids`
  - `/platform/{env}/ecs_cluster_arn`
  - `/platform/{env}/public_alb_listener_arn`
  - `/platform/{env}/private_alb_listener_arn`
  - `/platform/{env}/sg_ecs_tasks_id`
  - `/platform/{env}/sg_rds_id`
  - `/platform/{env}/sg_elasticache_id`
  - `/platform/{env}/sg_lambda_id`
  - All security group IDs

> Application stacks read these SSM parameters via `data "aws_ssm_parameter"` rather than using `terraform_remote_state`, keeping state files decoupled.

---

#### Monitoring & Alerting baseline
- CloudWatch Log Groups: VPC Flow Logs, ECS cluster (Container Insights), ALB access logs
- SNS alert topic (`platform-{env}-alerts`) with email subscription(s)
- CloudWatch composite alarm: fires if public ALB 5xx rate > threshold **or** any unhealthy host count > 0
- CloudWatch dashboard: VPC flow log anomalies, ALB request rates and error rates, ECS cluster CPU/memory reservation

---

**Key variables:**
`project`, `environment`, `region`, `secondary_region`, `vpc_cidr`, `azs`, `domain`, `alert_emails`, `container_port_range`, `ecs_exec_enabled`, `single_nat_gateway` (false for prod, true for dev/qa to save cost), `waf_rate_limit`, `alb_log_retention_days`

**Key outputs (all re-exported to SSM Parameter Store and as Terraform outputs):**
`vpc_id`, `public_subnet_ids`, `private_subnet_ids`, `db_subnet_ids`, `vpc_cidr`,
`ecs_cluster_arn`, `ecs_cluster_name`,
`public_alb_arn`, `public_alb_dns`, `public_alb_listener_arn`,
`private_alb_arn`, `private_alb_dns`, `private_alb_listener_arn`,
`sg_public_alb_id`, `sg_private_alb_id`, `sg_ecs_tasks_id`, `sg_rds_id`, `sg_elasticache_id`, `sg_efs_id`, `sg_lambda_id`, `sg_vpce_id`,
`platform_kms_key_arn`, `ecs_task_execution_role_arn`, `ecs_task_base_role_arn`, `devops_role_arn`,
`acm_certificate_arn`, `acm_certificate_arn_us_east_1`, `route53_zone_id`,
`platform_alerts_sns_arn`

---

### `stacks/base-network`
**Purpose:** Foundation networking layer. Must be deployed first. All other stacks reference its outputs.

**Composes:** `modules/network`, `modules/kms`, `modules/monitoring`

**Provisions:**
- VPC with public, private, and isolated (DB) subnets across 3 AZs
- Internet Gateway (public tier) and NAT Gateways (private tier, one per AZ)
- Route tables and subnet associations
- VPC Gateway Endpoints (S3, DynamoDB)
- VPC Interface Endpoints (ECR API, ECR DKR, Secrets Manager, SSM, CloudWatch Logs)
- KMS key for VPC Flow Logs encryption
- VPC Flow Logs to CloudWatch

**Key outputs:** `vpc_id`, `public_subnet_ids`, `private_subnet_ids`, `db_subnet_ids`, `vpc_cidr`

---

### `stacks/ecs-cluster`
**Purpose:** Shared ECS compute platform for all containerized services. Deploy once per environment; BFF and microservice stacks attach to this cluster.

**Composes:** `modules/ecs` (cluster only), `modules/alb` (×2), `modules/acm`, `modules/waf`, `modules/monitoring`

**Provisions:**
- ECS cluster with Container Insights enabled
- **Public ALB** (internet-facing) — HTTPS:443 listener with ACM certificate; HTTP:80 → HTTPS redirect; WAF Web ACL attached
- **Private ALB** (internal) — HTTPS:443 listener on private subnets for service-to-service traffic
- Default 404 listener rules on both ALBs (services register their own path rules)
- Security groups: public ALB allows 0.0.0.0/0 on 443/80; private ALB allows VPC CIDR on 443
- CloudWatch alarms on ALB 5xx rates and target unhealthy host counts

**Key outputs:** `ecs_cluster_arn`, `ecs_cluster_name`, `public_alb_arn`, `public_alb_listener_arn`, `private_alb_arn`, `private_alb_listener_arn`, `public_alb_dns`, `private_alb_dns`

---

### `stacks/data-layer`
**Purpose:** All persistent data stores for an environment.

**Composes:** `modules/rds`, `modules/elasticache`, `modules/dynamodb`, `modules/s3`, `modules/kms`, `modules/secrets-manager`, `modules/monitoring`

**Provisions:**
- Aurora PostgreSQL cluster (Multi-AZ, Serverless v2 or provisioned) in isolated subnets
- RDS Proxy for connection pooling
- DB credentials stored in Secrets Manager with automatic rotation
- ElastiCache Redis cluster (Multi-AZ with automatic failover) in isolated subnets
- DynamoDB tables for high-throughput key-value / session data (configurable list)
- S3 buckets for application assets, uploads, and exports
- KMS CMKs for RDS, ElastiCache, and DynamoDB encryption
- CloudWatch alarms on DB CPU, connections, replication lag, cache evictions

**Key outputs:** `rds_cluster_endpoint`, `rds_reader_endpoint`, `rds_proxy_endpoint`, `redis_primary_endpoint`, `s3_bucket_ids`

---

### `stacks/frontend`
**Purpose:** Static web application hosting with global CDN delivery.

**Composes:** `modules/s3`, `modules/cloudfront`, `modules/acm`, `modules/route53`, `modules/waf`, `modules/monitoring`

**Provisions:**
- S3 bucket (private, no public access) as the CloudFront origin
- Origin Access Control (OAC) — CloudFront signs requests to S3; no public bucket policy
- CloudFront distribution with:
  - Custom domain (e.g., `app.example.com`)
  - ACM certificate (us-east-1) for HTTPS
  - Managed cache policies (static assets: long TTL; HTML: short TTL)
  - Geo restriction (optional)
  - WAF Web ACL (managed rules + rate limiting)
  - Custom error pages (404 → `/index.html` for SPA routing)
- Route 53 A alias record pointing to CloudFront
- CloudFront access logs delivered to S3

**Key outputs:** `cloudfront_distribution_id`, `cloudfront_domain`, `s3_bucket_name`, `s3_bucket_arn`

---

### `stacks/bff`
**Purpose:** Deploy a BFF (Backend For Frontend) or public-facing API service as a container on the shared ECS cluster, routable via the public ALB.

**Composes:** `modules/ecr`, `modules/ecs` (service + task), `modules/alb` (target group + listener rule), `modules/iam`, `modules/secrets-manager`, `modules/monitoring`

**Provisions:**
- ECR repository for the service's container image
- ECS task definition (Fargate) with container spec, environment variables, and Secrets Manager secret injection
- ECS service attached to the shared ECS cluster
- IAM task execution role (ECR pull, Secrets Manager read, CloudWatch Logs write) and task role (scoped to service's AWS resource needs)
- ALB target group (IP mode) registered on the **public ALB**
- HTTPS listener rule on the public ALB routing a configurable path prefix (e.g., `/api/*`) to this service's target group
- Route 53 record for the service subdomain pointing to the public ALB (optional)
- Service auto-scaling on CPU and request count
- CloudWatch alarms on task count, CPU, memory, and ALB 5xx rate per target group

**Inputs:** `cluster_arn`, `public_alb_listener_arn`, `vpc_id`, `private_subnet_ids`, `service_name`, `container_image`, `container_port`, `path_pattern`, `desired_count`, `task_cpu`, `task_memory`, `secret_arns`

**Key outputs:** `ecr_repository_url`, `ecs_service_name`, `target_group_arn`, `task_role_arn`

---

### `stacks/microservice`
**Purpose:** Deploy an internal microservice as a container on the shared ECS cluster, routable only via the private ALB. Not directly reachable from the internet.

**Composes:** `modules/ecr`, `modules/ecs` (service + task), `modules/alb` (target group + listener rule), `modules/iam`, `modules/secrets-manager`, `modules/monitoring`

**Provisions:**
- ECR repository for the service's container image
- ECS task definition (Fargate) with container spec and Secrets Manager injection
- ECS service attached to the shared ECS cluster (private subnets)
- IAM task execution role and scoped task role
- ALB target group registered on the **private ALB**
- HTTPS listener rule on the private ALB routing a configurable path prefix (e.g., `/payments/*`) to this service's target group
- Security group allowing inbound only from the private ALB security group and other trusted service security groups
- Service auto-scaling on CPU and queue depth (optional SQS trigger)
- CloudWatch alarms on task health, CPU, memory, and DLQ depth (if applicable)

**Inputs:** `cluster_arn`, `private_alb_listener_arn`, `vpc_id`, `private_subnet_ids`, `service_name`, `container_image`, `container_port`, `path_pattern`, `desired_count`, `task_cpu`, `task_memory`, `secret_arns`

**Key outputs:** `ecr_repository_url`, `ecs_service_name`, `target_group_arn`, `task_role_arn`

---

### `stacks/webhook-ingestion`
**Purpose:** Durable, serverless webhook receiver — accepts inbound HTTP events, enqueues them to a FIFO queue, and processes them with Lambda. Decouples ingestion from processing and guarantees exactly-once delivery.

**Composes:** `modules/api-gateway`, `modules/sqs`, `modules/lambda`, `modules/iam`, `modules/kms`, `modules/monitoring`

**Provisions:**
- HTTP API Gateway (v2) with a `POST /webhook/{source}` route
- Lambda authorizer on the route for HMAC signature validation (optional)
- API Gateway → SQS direct integration (no Lambda in the hot path) using an IAM role
- FIFO SQS queue with content-based deduplication and a dead-letter queue (DLQ)
- Lambda processor subscribed to the FIFO queue as an event source (configurable batch size and concurrency)
- KMS encryption on the SQS queue and Lambda environment
- IAM roles: API GW → SQS publish; Lambda → SQS consume, CloudWatch Logs write, Secrets Manager read
- CloudWatch alarms on DLQ depth, Lambda error rate, and API Gateway 4xx/5xx
- Custom domain on the API Gateway (e.g., `webhooks.example.com`)

**Key outputs:** `api_endpoint`, `queue_url`, `dlq_url`, `processor_lambda_arn`

---

### `stacks/serverless`
**Purpose:** General-purpose event-driven serverless compute pattern.

**Composes:** `modules/lambda`, `modules/sqs`, `modules/eventbridge`, `modules/dynamodb`, `modules/iam`, `modules/kms`, `modules/monitoring`

**Provisions:**
- Lambda function(s) with configurable triggers
- Standard SQS queue + DLQ for async invocation buffering
- EventBridge rule(s) targeting Lambda (schedule or event pattern)
- DynamoDB table for Lambda state/result storage
- KMS CMK shared across Lambda, SQS, and DynamoDB
- IAM execution roles per Lambda with least-privilege policies
- CloudWatch Log groups with configurable retention
- CloudWatch alarms on Lambda error rate, duration, throttles, and DLQ depth

**Key outputs:** `lambda_function_arns`, `queue_urls`, `dynamodb_table_names`

---

### `stacks/event-driven`
**Purpose:** Async event processing backbone — services emit domain events to EventBridge; downstream consumers (Lambda or ECS) react without point-to-point coupling.

**Composes:** `modules/eventbridge`, `modules/lambda`, `modules/sqs`, `modules/dynamodb`, `modules/iam`, `modules/monitoring`

**Provisions:**
- Custom EventBridge event bus (one per domain or environment)
- EventBridge rules for each event pattern, targeting Lambda or SQS
- Per-rule DLQ for failed event delivery
- Lambda consumers per event type (or ECS task triggers via EventBridge Pipes)
- DynamoDB event store table (optional — for event sourcing pattern)
- IAM roles: per-service publish to event bus; EventBridge invoke Lambda/SQS
- CloudWatch alarms on failed invocations, DLQ depth, and event bus throttling

**Key outputs:** `event_bus_arn`, `event_bus_name`, `consumer_lambda_arns`

---

### `stacks/data-pipeline`
**Purpose:** Real-time streaming data ingestion and delivery to durable storage for analytics or downstream processing.

**Composes:** `modules/kinesis`, `modules/firehose`, `modules/s3`, `modules/lambda`, `modules/iam`, `modules/kms`, `modules/monitoring`

**Provisions:**
- Kinesis Data Stream (configurable shards or on-demand) as the ingestion layer
- Kinesis Data Firehose delivery stream sourced from the Kinesis stream
- S3 destination bucket with dynamic partitioning (e.g., `year/month/day/hour`)
- Optional Lambda transformation function (enrich, filter, or convert records in-stream before S3 delivery)
- Parquet conversion via AWS Glue Data Catalog (optional)
- KMS encryption on stream, Firehose, and S3
- IAM roles: Firehose → S3 write, KMS, Glue; Lambda execution role
- CloudWatch alarms on iterator age, delivery failures, and Firehose delivery success rate

**Key outputs:** `kinesis_stream_arn`, `firehose_stream_arn`, `s3_bucket_name`, `transformer_lambda_arn`

---

### `stacks/notification`
**Purpose:** Fan-out notification delivery — a single publish produces messages to multiple independent consumers (email, SMS, SQS queues, Lambda functions).

**Composes:** `modules/sns`, `modules/sqs`, `modules/lambda`, `modules/iam`, `modules/kms`, `modules/monitoring`

**Provisions:**
- SNS topic as the fan-out hub
- SQS queue subscription(s) per consumer domain (each with its own DLQ)
- Lambda subscription(s) for real-time notification processing (email dispatch, push, etc.)
- SNS topic policy allowing designated producer services to publish
- SQS queue policies allowing SNS to send messages
- KMS CMK for topic and queue encryption
- CloudWatch alarms on SNS delivery failures, SQS DLQ depth, and Lambda errors

**Key outputs:** `sns_topic_arn`, `queue_arns`, `subscriber_lambda_arns`

---

### `stacks/async-worker`
**Purpose:** Durable background job processing — work items are enqueued to SQS and consumed by an auto-scaling ECS worker service (or Lambda for short-lived tasks).

**Composes:** `modules/sqs`, `modules/ecs` (service + task), `modules/iam`, `modules/kms`, `modules/monitoring`

**Provisions:**
- Standard SQS work queue with DLQ and configurable visibility timeout
- ECS Fargate worker service (no ALB — internal only) in private subnets
- Auto-scaling policy: scale out/in based on `ApproximateNumberOfMessagesVisible` CloudWatch metric
- IAM task role with SQS receive/delete permissions and scoped access to downstream resources (RDS, S3, etc.)
- KMS encryption on SQS and Lambda environment variables
- CloudWatch alarms on DLQ depth, queue age (iterator age equivalent), and worker task count

**Inputs:** `cluster_arn`, `vpc_id`, `private_subnet_ids`, `worker_image`, `task_cpu`, `task_memory`, `min_tasks`, `max_tasks`

**Key outputs:** `queue_url`, `dlq_url`, `ecs_service_name`

---

### `stacks/scheduled-job`
**Purpose:** Run a recurring or one-time job on a cron or rate schedule, targeting a Lambda function or an ECS Fargate task.

**Composes:** `modules/eventbridge`, `modules/lambda` or `modules/ecs` (task), `modules/iam`, `modules/monitoring`

**Provisions:**
- EventBridge Scheduler schedule group
- Schedule(s) with cron or rate expression
- Target: Lambda invoke **or** ECS `RunTask` (selectable per schedule)
- Scheduler IAM role with `lambda:InvokeFunction` or `ecs:RunTask` + `iam:PassRole` permissions
- Lambda execution role or ECS task role scoped to the job's resource needs
- Flexible time window (optional — allows scheduler to batch within a window for load smoothing)
- CloudWatch alarms on Lambda error rate or ECS task stop codes

**Key outputs:** `schedule_group_name`, `schedule_arns`, `target_lambda_arn` or `target_task_definition_arn`

---

## Bootstrap Runbook

> Run these steps once, in order, before any CI/CD pipelines are used. These steps are performed manually by an ops/admin user.

### Step 1 — Purchase a Domain Name
- Register a domain via Route 53 Registrar (or transfer from another registrar)
- This domain will be the apex for all environments (e.g., `example.com`)
- Subdomain strategy: `app.example.com` (prod), `qa.app.example.com`, `dev.app.example.com`

### Step 2 — Set Up Email for AWS Accounts
AWS requires a unique email address per account. Use email aliases via a hosted email provider (e.g., Google Workspace, Zoho, or a self-hosted solution).

Recommended account email convention:
```
aws-root@example.com
aws-ops@example.com
aws-dev@example.com
aws-qa@example.com
aws-prod@example.com
```

### Step 3 — Create the Root AWS Account
- Sign up at https://aws.amazon.com with `aws-root@example.com`
- Enable MFA on the root account immediately
- Do **not** use the root account for any operational work after setup
- Set billing alerts and a budget

### Step 4 — Set Up AWS Organizations
- Create an AWS Organization from the root account
- Enable all features (not just consolidated billing)
- Create the following Organizational Unit (OU) structure:
  ```
  Root
  ├── Infrastructure/
  │   └── Ops account (aws-ops@example.com)
  ├── Workloads/
  │   ├── Dev account (aws-dev@example.com)
  │   ├── QA account  (aws-qa@example.com)
  │   └── Prod account (aws-prod@example.com)
  └── Security/ (optional)
      └── Audit/log archive account
  ```
- Apply Service Control Policies (SCPs):
  - Deny root account usage in all member accounts
  - Deny disabling CloudTrail
  - Restrict regions to only those in use
  - Deny creation of IAM users with console access (enforce SSO)

### Step 5 — Set Up IAM Identity Center (SSO)
- Enable IAM Identity Center in the root/management account
- Configure your identity source (built-in directory, Google Workspace SAML, or Okta)
- Create permission sets:
  - `AdministratorAccess` — ops/devops engineers
  - `DeveloperAccess` — developers (read-heavy, limited write)
  - `ReadOnlyAccess` — management / auditors
- Assign users/groups to accounts with appropriate permission sets

### Step 6 — Bootstrap Terraform Remote State
Run the `bootstrap/state-backend` module once per environment account:
```bash
cd bootstrap/state-backend
terraform init
terraform apply -var="account_name=dev" -var="region=us-east-1"
```
This creates:
- An S3 bucket for Terraform state (`tfstate-<account_id>-<region>`)
- A DynamoDB table for state locking (`terraform-state-lock`)
- A KMS key for state encryption

### Step 7 — Configure GitHub Actions OIDC
Run the `bootstrap/oidc` module in each environment account:
```bash
cd bootstrap/oidc
terraform apply -var="github_org=your-org" -var="github_repo=your-repo"
```
This creates:
- An IAM OIDC Identity Provider for `token.actions.githubusercontent.com`
- An IAM role (`github-actions-role`) with a trust policy scoped to your repository
- Permissions policies for the CI role (scoped to what Terraform needs)

Store the role ARNs as GitHub Actions secrets:
```
AWS_ROLE_ARN_DEV
AWS_ROLE_ARN_QA
AWS_ROLE_ARN_PROD
AWS_ROLE_ARN_OPS
```

---

## GitHub Actions Workflows

### `tf-plan.yml` — Pull Request Validation
Triggers on: PR opened/updated targeting `main`

Steps:
1. Checkout code
2. Detect which `environments/` directories changed
3. Assume OIDC role for the target account
4. `terraform init` with remote backend config
5. `terraform validate`
6. `terraform plan -out=plan.tfplan`
7. Post plan output as PR comment

### `tf-apply.yml` — Apply on Merge
Triggers on: push to `main`

Steps:
1. Checkout code
2. Detect changed environments
3. For each changed environment (in order: dev → qa → prod):
   a. Assume OIDC role
   b. `terraform init`
   c. `terraform apply -auto-approve` (dev/qa) or require manual approval (prod)

### `tf-destroy.yml` — Targeted Destroy
Triggers on: manual `workflow_dispatch` with inputs: `environment`, `target_resource`

Steps:
1. Require explicit "DESTROY" confirmation input
2. Assume OIDC role
3. `terraform destroy -target=<resource>` with approval gate

### `tf-drift.yml` — Drift Detection
Triggers on: daily schedule (`cron: '0 9 * * 1-5'`)

Steps:
1. Run `terraform plan` in all environments
2. If plan shows changes (drift), open a GitHub Issue with the diff

### `bootstrap.yml` — One-time Bootstrap
Triggers on: manual `workflow_dispatch` with input: `bootstrap_step`

Steps:
1. Assume root/ops OIDC role
2. Run specified bootstrap module

---

## Conventions

### Naming
All resources follow: `{project}-{environment}-{region_short}-{resource_type}[-{qualifier}]`

Examples:
- `myapp-prod-use1-vpc`
- `myapp-prod-use1-ecs-cluster`
- `myapp-prod-use1-rds-aurora`

Region short codes: `use1` (us-east-1), `use2` (us-east-2), `usw2` (us-west-2), `euw1` (eu-west-1)

### Tagging
All resources are tagged with:
```hcl
tags = {
  Project     = var.project
  Environment = var.environment
  Region      = var.region
  ManagedBy   = "terraform"
  Repository  = var.repository
}
```

### Variable Files
- `variables.tf` — variable declarations with descriptions and types
- `terraform.tfvars` — environment-specific values (committed, no secrets)
- `secrets.auto.tfvars` — secret values (never committed; injected by CI via Secrets Manager)

### State Management
- Remote state in S3 with DynamoDB locking per environment
- State file path convention: `{environment}/{stack}/terraform.tfstate`
- Cross-stack data sharing via `terraform_remote_state` data sources or SSM Parameter Store outputs

### Module Versioning
- Modules are versioned using git tags: `modules/network/v1.2.0`
- Stacks pin to module versions; environments pin to stack versions
- Changelog maintained per module in `modules/<name>/CHANGELOG.md`

---

## Local Development

### Prerequisites
```
terraform >= 1.7.0
aws-cli >= 2.x
tflint
terraform-docs
checkov
```

### Authenticate Locally
```bash
# Via IAM Identity Center (recommended)
aws sso login --profile dev

# Set profile for terraform
export AWS_PROFILE=dev
```

### Plan Locally
```bash
cd environments/dev
terraform init -backend-config=../../config/backend-dev.hcl
terraform plan -var-file=terraform.tfvars
```

### Lint & Security Scan
```bash
tflint --recursive
checkov -d . --framework terraform
```

### Generate Module Docs
```bash
terraform-docs markdown modules/network > modules/network/README.md
```

---

## Security Considerations

- No IAM users with programmatic access keys — all CI/CD uses OIDC
- All secrets stored in Secrets Manager or SSM Parameter Store (SecureString)
- All data at rest encrypted (KMS CMKs where possible)
- All inter-service traffic stays within VPC (VPC endpoints for AWS services)
- WAF on all public-facing ALBs and CloudFront distributions
- CloudTrail enabled in all accounts, logs shipped to centralized S3 bucket in ops account
- Config Rules for compliance drift detection
- GuardDuty enabled in all accounts

---

## Contributing

1. Create a feature branch: `feat/module-name-description`
2. Follow the module structure: `main.tf`, `variables.tf`, `outputs.tf`, `README.md`
3. Add a usage example in `modules/<name>/examples/`
4. Run `tflint` and `checkov` before opening a PR
5. Update `CHANGELOG.md` for the affected module
6. PRs require plan output posted as a comment before merge
