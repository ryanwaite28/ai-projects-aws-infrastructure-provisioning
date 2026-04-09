---
name: Project Intent — AWS Terraform Infrastructure Template
description: Core purpose, scope, and design goals for this Terraform + GitHub Actions provisioning template project
type: project
---

This project is a general-purpose Terraform module library and GitHub Actions workflow template for provisioning highly available, multi-region AWS infrastructure.

**Why:** Serves as a reusable starting point so teams don't write bespoke Terraform from scratch. Designed for GitOps — all provisioning runs via GitHub Actions OIDC (no long-lived access keys).

**How to apply:** When adding modules or workflows, follow the design principles in PROJECT.md: modular, multi-region, least-privilege IAM, environment-parity via `.tfvars`, GitOps-first.

## Modules planned
network, s3, dynamodb, iam, sqs, sns, eventbridge, lambda, rds, elasticache, ebs, efs, cloudfront, alb, api-gateway, ecs, ecr, kinesis, firehose, acm, route53, waf, secrets-manager, kms, monitoring

## Stacks planned (compositions of modules)
platform (HIGH-LEVEL: base-network + ecs-cluster + security groups + IAM + TLS/DNS + SSM outputs — deploy first),
base-network, ecs-cluster, data-layer, frontend, bff, microservice, serverless, webhook-ingestion, event-driven, data-pipeline, notification, async-worker, scheduled-job

## Deployment order
platform → data-layer → application stacks (frontend, bff, microservice, etc.)
Application stacks reference platform outputs via SSM Parameter Store (not terraform_remote_state).

## Bootstrap runbook (manual, one-time ops steps)
1. Buy domain (Route 53)
2. Set up email aliases for each AWS account
3. Create root AWS account
4. Create AWS Organizations with OUs (Infrastructure/Ops, Workloads/Dev+QA+Prod, Security)
5. Apply SCPs (deny root usage, deny disabling CloudTrail, region restriction, no IAM console users)
6. Set up IAM Identity Center (SSO) with permission sets
7. Bootstrap Terraform remote state (S3 + DynamoDB + KMS) per account
8. Configure GitHub Actions OIDC per account; store role ARNs as GitHub secrets

## GitHub Actions workflows
tf-plan.yml (PR), tf-apply.yml (merge), tf-destroy.yml (manual), tf-drift.yml (scheduled), bootstrap.yml (manual)
