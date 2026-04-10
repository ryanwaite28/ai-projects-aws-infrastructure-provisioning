##
## Environment: dev
## Wires the platform stack for the dev environment.
## Extend by adding more module/stack calls below as your architecture grows.
##

terraform {
  required_version = ">= 1.7.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = ">= 5.0" }
  }

  backend "s3" {
    # Values supplied at init time via: -backend-config=config/backend-dev.hcl
  }
}

provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

## ── Platform (base-network + ecs-cluster + security groups + SSM params) ──────
module "platform" {
  source = "../../stacks/platform"

  project     = var.project
  environment = var.environment
  region      = var.region

  # Network
  vpc_cidr             = var.vpc_cidr
  azs                  = var.azs
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  db_subnet_cidrs      = var.db_subnet_cidrs
  single_nat_gateway   = true # cost optimization for dev

  # TLS / DNS
  domain  = var.domain
  zone_id = var.zone_id

  # Monitoring
  alert_emails = var.alert_emails

  # GitHub OIDC — DevOpsRole for application CI/CD (not Terraform execution).
  # The OIDC provider is created by bootstrap/oidc and is stable per account.
  github_oidc_provider_arn = var.github_oidc_provider_arn
  github_repo_subject      = var.github_repo_subject

  tags = var.tags
}

## ── Add additional stacks below as needed ─────────────────────────────────────
## Example: data layer
# module "data" {
#   source      = "../../stacks/data-layer"
#   project     = var.project
#   environment = var.environment
#   region      = var.region
#   ssm_prefix  = module.platform.ssm_prefix
#   ...
# }
