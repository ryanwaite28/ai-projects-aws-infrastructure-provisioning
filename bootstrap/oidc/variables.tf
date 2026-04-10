variable "project" {
  type        = string
  description = "Project name"
}

variable "region" {
  type        = string
  description = "AWS region"
}

variable "github_org" {
  type        = string
  description = "GitHub org or username"
}

variable "github_repo" {
  type        = string
  description = "GitHub repository name (without org prefix)"
}

variable "environments" {
  type        = string
  default     = "dev,qa,prod"
  description = "Comma-separated list of environments"
}

variable "state_bucket_name" {
  type        = string
  description = "S3 bucket name for Terraform state (for role policy)"
}

variable "lock_table_name" {
  type        = string
  description = "DynamoDB table name (for role policy)"
}
