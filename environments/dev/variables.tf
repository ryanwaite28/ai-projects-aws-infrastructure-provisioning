variable "project" {
  type = string
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "region" {
  type    = string
  default = "us-east-1"
}

# Network
variable "vpc_cidr" {
  type    = string
  default = "10.10.0.0/16"
}

variable "azs" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.10.0.0/24", "10.10.1.0/24", "10.10.2.0/24"]
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.10.10.0/24", "10.10.11.0/24", "10.10.12.0/24"]
}

variable "db_subnet_cidrs" {
  type    = list(string)
  default = ["10.10.20.0/24", "10.10.21.0/24", "10.10.22.0/24"]
}

# TLS / DNS
variable "domain" {
  type        = string
  description = "Apex domain managed in Route 53 (e.g. dev.example.com)."
}

variable "zone_id" {
  type        = string
  description = "Route 53 hosted zone ID for the domain."
}

# Monitoring
variable "alert_emails" {
  type    = list(string)
  default = []
}

# GitHub OIDC — required for the platform DevOpsRole (application CI/CD role).
# The OIDC provider is created by bootstrap/oidc; the ARN is stable per account.
variable "github_oidc_provider_arn" {
  type        = string
  description = "ARN of the GitHub Actions OIDC provider from bootstrap/oidc."
}

variable "github_repo_subject" {
  type        = string
  description = "OIDC subject for the application repo (e.g. repo:org/app-repo:*)."
}

variable "tags" {
  type    = map(string)
  default = {}
}
