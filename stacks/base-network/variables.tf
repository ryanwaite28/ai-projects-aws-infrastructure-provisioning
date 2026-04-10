variable "project" {
  type        = string
  description = "Project name prefix."
}

variable "environment" {
  type        = string
  description = "Deployment environment."
}

variable "region" {
  type        = string
  description = "Primary AWS region."
}

variable "vpc_cidr" {
  type        = string
  default     = "10.0.0.0/16"
  description = "VPC CIDR block."
}

variable "azs" {
  type        = list(string)
  description = "Availability zones."
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "Public subnet CIDRs (one per AZ)."
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "Private subnet CIDRs (one per AZ)."
}

variable "db_subnet_cidrs" {
  type        = list(string)
  description = "Isolated/DB subnet CIDRs (one per AZ)."
}

variable "single_nat_gateway" {
  type        = bool
  default     = false
  description = "Single NAT GW (true in dev/qa to reduce cost)."
}

variable "interface_endpoints" {
  type        = set(string)
  default     = ["ecr.api", "ecr.dkr", "secretsmanager", "ssm", "logs", "sts"]
  description = "AWS services to create Interface VPC Endpoints for."
}

variable "flow_log_kms_key_arn" {
  type        = string
  default     = null
  description = "KMS key ARN for VPC Flow Logs."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags."
}
