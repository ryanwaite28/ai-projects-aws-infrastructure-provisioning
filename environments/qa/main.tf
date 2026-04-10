##
## Environment: qa
##

terraform {
  required_version = ">= 1.7.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = ">= 5.0" }
  }
  backend "s3" {
    # Values supplied at init time via: -backend-config=config/backend-qa.hcl
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

module "platform" {
  source = "../../stacks/platform"

  project     = var.project
  environment = var.environment
  region      = var.region

  vpc_cidr             = var.vpc_cidr
  azs                  = var.azs
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  db_subnet_cidrs      = var.db_subnet_cidrs
  single_nat_gateway   = true # one NAT is sufficient for qa

  domain  = var.domain
  zone_id = var.zone_id

  alert_emails = var.alert_emails

  github_oidc_provider_arn = var.github_oidc_provider_arn
  github_repo_subject      = var.github_repo_subject

  tags = var.tags
}
