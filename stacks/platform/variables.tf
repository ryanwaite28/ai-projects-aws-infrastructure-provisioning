variable "project" {
  type        = string
  description = "Project name prefix."
}

variable "environment" {
  type        = string
  description = "Deployment environment (dev, qa, prod)."
}

variable "region" {
  type        = string
  description = "Primary AWS region."
}

# ── Networking ────────────────────────────────────────────────────────────────

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "azs" {
  type        = list(string)
  description = "Availability zones (3 recommended)."
}

variable "public_subnet_cidrs" {
  type = list(string)
}

variable "private_subnet_cidrs" {
  type = list(string)
}

variable "db_subnet_cidrs" {
  type = list(string)
}

variable "single_nat_gateway" {
  type        = bool
  default     = false
  description = "Use a single NAT gateway (true in dev/qa, false in prod for HA)."
}

variable "interface_endpoints" {
  type    = set(string)
  default = ["ecr.api", "ecr.dkr", "secretsmanager", "ssm", "logs", "sts", "execute-api"]
}

# ── TLS / DNS ─────────────────────────────────────────────────────────────────

variable "domain" {
  type        = string
  description = "Apex domain (e.g. example.com)."
}

variable "zone_id" {
  type        = string
  description = "Route 53 hosted zone ID."
}

# ── ALB / WAF ─────────────────────────────────────────────────────────────────

variable "waf_rate_limit" {
  type    = number
  default = 2000
}

variable "alb_access_log_bucket" {
  type    = string
  default = null
}

# ── ECS ───────────────────────────────────────────────────────────────────────

variable "cluster_name" {
  type    = string
  default = "main"
}

variable "execute_command_enabled" {
  type    = bool
  default = true
}

# ── IAM / KMS ─────────────────────────────────────────────────────────────────

variable "devops_role_name" {
  type    = string
  default = "DevOpsRole"
}

variable "github_oidc_provider_arn" {
  type        = string
  description = "ARN of the GitHub Actions OIDC provider (created by bootstrap/oidc). Required — omitting leaves DevOpsRole with no trust policy."
}

variable "github_repo_subject" {
  type        = string
  description = "OIDC subject for the application repo (e.g. 'repo:org/app-repo:*'). Scopes DevOpsRole trust to a specific repository."
}

# ── Monitoring ────────────────────────────────────────────────────────────────

variable "alert_emails" {
  type    = list(string)
  default = []
}

variable "tags" {
  type    = map(string)
  default = {}
}
