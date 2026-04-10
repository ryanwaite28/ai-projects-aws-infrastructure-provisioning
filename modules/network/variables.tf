variable "project" {
  description = "Project name used as a prefix in resource names and tags."
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, qa, prod)."
  type        = string
}

variable "region" {
  description = "AWS region for this module's resources."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "List of availability zone names to deploy subnets into."
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets, one per AZ. Must have same length as azs."
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private (compute) subnets, one per AZ. Must have same length as azs."
  type        = list(string)
}

variable "db_subnet_cidrs" {
  description = "CIDR blocks for isolated/DB subnets (no internet route), one per AZ."
  type        = list(string)
}

variable "enable_nat_gateway" {
  description = "Create NAT Gateways for private subnet egress."
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway instead of one per AZ. Set true in dev/qa to reduce cost."
  type        = bool
  default     = false
}

variable "enable_vpce_s3" {
  description = "Create a Gateway VPC Endpoint for S3 (free, keeps S3 traffic off internet)."
  type        = bool
  default     = true
}

variable "enable_vpce_dynamodb" {
  description = "Create a Gateway VPC Endpoint for DynamoDB (free)."
  type        = bool
  default     = true
}

variable "interface_endpoints" {
  description = "Set of AWS service names to create Interface VPC Endpoints for (e.g. 'ecr.api', 'secretsmanager', 'logs'). Each endpoint creates an ENI in every private subnet."
  type        = set(string)
  default     = ["ecr.api", "ecr.dkr", "secretsmanager", "ssm", "logs", "sts", "execute-api"]
}

variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs to CloudWatch."
  type        = bool
  default     = true
}

variable "flow_log_retention_days" {
  description = "Retention period in days for the VPC Flow Logs CloudWatch log group."
  type        = number
  default     = 30
}

variable "flow_log_kms_key_arn" {
  description = "KMS key ARN to encrypt the VPC Flow Logs log group. Null uses the AWS-managed key."
  type        = string
  default     = null
}

variable "tags" {
  description = "Additional tags merged into the default tag set applied to every resource."
  type        = map(string)
  default     = {}
}
