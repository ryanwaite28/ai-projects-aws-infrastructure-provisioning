# AWS Infrastructure Provisioning Template

A production-grade, modular Terraform template for provisioning highly available AWS infrastructure. Designed for teams that want a complete, opinionated starting point — networking, compute, data, messaging, security, and delivery — with GitOps-ready GitHub Actions workflows included.

> For full design intent, module reference, bootstrap runbook, and org-wide usage patterns, see [PROJECT.md](PROJECT.md).

---

## What This Is

This is a **GitHub Template Repository**. You copy it once per project, customize the placeholders, and get:

- A full library of reusable Terraform modules covering every major AWS service
- Opinionated stack compositions that wire modules together for common patterns
- Per-environment Terraform roots (`dev`, `qa`, `prod`) with remote state wiring
- Reusable GitHub Actions workflows for infrastructure CI/CD and application deployment
- A bootstrap sequence that sets up remote state and GitHub OIDC authentication

---

## Architecture Overview

```
Internet
   │
   ▼
CloudFront ──── S3 (static frontend)
   │
   ▼
API Gateway (REST)
   │  ┌──────────────────┐
   ├──► ALB (public)      │
   │  │  ECS Fargate BFF  │
   │  └──────────────────┘
   │  ┌──────────────────────┐
   ├──► ALB (private)         │
   │  │  ECS Fargate Services  │
   │  └──────────────────────┘
   │
   ▼ (webhook ingestion path)
API Gateway ──► SQS ──► Lambda Processor
   │
   └── VPC
         ├── Aurora PostgreSQL (RDS)
         ├── ElastiCache Redis
         ├── DynamoDB (global tables)
         └── VPC Endpoints (ECR, SSM, Secrets Manager, etc.)
```

All infrastructure is managed by Terraform. Application code is deployed via GitHub Actions reusable workflows that are kept separate from infrastructure state.

---

## Repository Layout

```
.
├── bootstrap/              # One-time setup (remote state + OIDC)
│   ├── state-backend/      # S3 bucket + DynamoDB for Terraform state
│   └── oidc/               # GitHub OIDC provider + per-env IAM roles
│
├── modules/                # Reusable single-service Terraform modules
│   ├── network/            # VPC, subnets, NAT, VPC endpoints
│   ├── ecs/                # ECS cluster + Fargate service + autoscaling
│   ├── alb/                # Application Load Balancer
│   ├── lambda/             # Lambda function + execution role + log group
│   ├── sqs/                # SQS queue + DLQ
│   ├── sns/                # SNS topic + subscriptions
│   ├── rds/                # Aurora cluster (PostgreSQL / MySQL)
│   ├── elasticache/        # Redis replication group
│   ├── dynamodb/           # DynamoDB table + GSIs + streams
│   ├── s3/                 # S3 bucket + policy + lifecycle rules
│   ├── cloudfront/         # CloudFront distribution + OAC
│   ├── api-gateway/        # API Gateway HTTP v2
│   ├── ecr/                # ECR repository
│   ├── iam/                # IAM role + policies
│   ├── kms/                # KMS CMK + key policy
│   ├── acm/                # ACM certificate + DNS validation
│   ├── route53/            # Hosted zone + DNS records
│   ├── waf/                # WAFv2 Web ACL + managed rules
│   ├── secrets-manager/    # Secrets Manager secret + rotation
│   ├── monitoring/         # CloudWatch alarms + SNS alerts + dashboards
│   ├── eventbridge/        # EventBridge bus + rules + targets
│   ├── kinesis/            # Kinesis Data Stream
│   ├── firehose/           # Kinesis Firehose delivery stream
│   ├── ebs/                # EBS volume
│   └── efs/                # EFS file system + mount targets + access points
│
├── stacks/                 # Module compositions for common patterns
│   ├── platform/           # "Day zero" stack: network + ECS + ALBs + IAM + KMS
│   ├── base-network/       # VPC + subnets + NAT + endpoints only
│   ├── ecs-cluster/        # ECS cluster + public/private ALBs + security groups
│   ├── bff/                # BFF service: ECR + ECS + public ALB rule
│   ├── microservice/       # Internal service: ECR + ECS + private ALB rule
│   ├── async-worker/       # ECS worker: SQS-triggered, autoscales on queue depth
│   ├── serverless/         # Lambda + DynamoDB + EventBridge + optional VPC
│   ├── scheduled-job/      # EventBridge cron → Lambda or ECS task
│   ├── webhook-ingestion/  # API Gateway → SQS → Lambda processor
│   ├── notification/       # SNS topic + SQS/Lambda/email subscribers
│   ├── event-driven/       # EventBridge bus + rules + Lambda consumers
│   ├── data-layer/         # RDS + ElastiCache + DynamoDB + S3
│   ├── data-pipeline/      # Kinesis + Firehose → S3 (partitioned)
│   └── frontend/           # S3 + CloudFront + ACM + Route 53
│
├── environments/           # Per-environment Terraform roots (where you run apply)
│   ├── dev/
│   ├── qa/
│   └── prod/
│
├── config/                 # Remote backend config per environment
│   ├── backend-dev.hcl
│   ├── backend-qa.hcl
│   └── backend-prod.hcl
│
└── .github/workflows/      # Reusable GitHub Actions workflows
    ├── bootstrap.yml           # One-time: state backend + OIDC setup
    ├── tf-plan.yml             # PR: terraform plan per changed environment
    ├── tf-apply.yml            # Merge: terraform apply in order dev→qa→prod
    ├── tf-destroy.yml          # Manual: targeted resource destroy
    ├── tf-drift.yml            # Scheduled: drift detection, opens Issues
    ├── deploy-frontend.yml     # App: build + S3 sync + CloudFront invalidation
    ├── deploy-service.yml      # App: build + ECR push + ECS rolling deploy
    ├── deploy-lambda.yml       # App: build + S3 upload + Lambda update
    └── deploy-webhook-ingestion.yml  # App: build + deploy SQS processor Lambda
```

---

## Quick Start

### 1. Create your repo from this template

Click **"Use this template"** on GitHub, or:

```bash
git clone --depth=1 https://github.com/<your-org>/aws-infrastructure-provisioning.git myapp-infrastructure
cd myapp-infrastructure && rm -rf .git
git init && git add . && git commit -m "chore: init from template"
```

### 2. Replace placeholders

```bash
# Find all CHANGEME tokens
grep -r "CHANGEME" .

# Replace with your project name
find . -type f -not -path './.git/*' \
  -exec sed -i '' 's/CHANGEME/myapp/g' {} +
```

### 3. Bootstrap remote state and OIDC (run once)

Create a short-lived IAM user with permissions to create S3, DynamoDB, IAM OIDC, and IAM roles. Add its keys as **repository-level** secrets (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`), then trigger the bootstrap workflow manually:

```
GitHub → Actions → Bootstrap → Run workflow
```

After it completes, copy the printed OIDC role ARNs into your GitHub **Environment** secrets (`dev`, `qa`, `prod`), then delete the IAM user and its keys.

### 4. Deploy platform infrastructure

```bash
terraform -chdir=environments/dev init \
  -backend-config=config/backend-dev.hcl

terraform -chdir=environments/dev apply
```

Or push to `main` and let `tf-apply.yml` handle it.

### 5. Wire application repos

Application repos call the reusable deploy workflows. No Terraform knowledge required:

```yaml
# In your application repo's .github/workflows/deploy.yml
jobs:
  deploy:
    uses: your-org/myapp-infrastructure/.github/workflows/deploy-service.yml@main
    with:
      environment: prod
      ecr_repository: myapp-prod-use1-ecr-payments-api
      ecs_cluster: myapp-prod-use1-ecs-main
      ecs_service: myapp-prod-use1-svc-payments-api
      container_name: app
      runtime: nodejs
    secrets:
      aws_role_arn: ${{ secrets.AWS_ROLE_ARN }}
```

---

## Key Design Decisions

| Decision | Rationale |
|---|---|
| No IAM users for CI/CD | All pipelines use GitHub OIDC — no long-lived credentials in repos |
| SSM Parameter Store for cross-stack wiring | App stacks read platform outputs without needing Terraform state access |
| REST API v1 for webhook ingestion | HTTP API v2 can't do direct AWS service integrations (SQS); REST v1 can |
| `environments/` roots, not workspaces | True per-account isolation; different stacks can be enabled per env |
| Permission boundary on all platform roles | Prevents IAM escalation even if a role is misconfigured |
| Two-layer IAM roles | Terraform execution role (from `bootstrap/oidc`) is separate from DevOpsRole (from `stacks/platform`) |

---

## Supported Runtimes (Deploy Workflows)

| Workflow | Supported runtimes |
|---|---|
| `deploy-service.yml` | `docker-only`, `nodejs`, `java-maven`, `java-gradle`, `python`, `go` |
| `deploy-lambda.yml` | `python`, `nodejs`, `java-maven`, `java-gradle`, `go`, `zip-only` |
| `deploy-webhook-ingestion.yml` | Same as `deploy-lambda.yml` |
| `deploy-frontend.yml` | `npm`, `yarn`, `pnpm` |

---

## Documentation

| Document | Purpose |
|---|---|
| [PROJECT.md](PROJECT.md) | Full reference: module docs, stack patterns, bootstrap runbook, org usage guide, environment secrets guidance |
| [RELEASES.md](RELEASES.md) | Changelog |
| [CLAUDE.md](CLAUDE.md) | AI assistant instructions for this repo (slash commands, conventions) |
