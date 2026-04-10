variable "project" {
  type = string
}

variable "environment" {
  type    = string
  default = "qa"
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "vpc_cidr" {
  type    = string
  default = "10.20.0.0/16"
}

variable "azs" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.20.0.0/24", "10.20.1.0/24", "10.20.2.0/24"]
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.20.10.0/24", "10.20.11.0/24", "10.20.12.0/24"]
}

variable "db_subnet_cidrs" {
  type    = list(string)
  default = ["10.20.20.0/24", "10.20.21.0/24", "10.20.22.0/24"]
}

variable "domain" {
  type        = string
  description = "Apex domain managed in Route 53."
}

variable "zone_id" {
  type        = string
  description = "Route 53 hosted zone ID for the domain."
}

variable "alert_emails" {
  type    = list(string)
  default = []
}

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
