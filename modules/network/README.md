# Module: `network`

Creates a production-grade VPC with public, private, and isolated/DB subnets across multiple AZs. Includes Internet Gateway, NAT Gateways, Gateway VPC Endpoints (S3, DynamoDB), Interface VPC Endpoints, and VPC Flow Logs.

Full name pattern: `{project}-{environment}-{region_short}-vpc`

## Usage

```hcl
module "network" {
  source = "../../modules/network"

  project     = "myapp"
  environment = "prod"
  region      = "us-east-1"

  vpc_cidr             = "10.0.0.0/16"
  azs                  = ["us-east-1a", "us-east-1b", "us-east-1c"]
  public_subnet_cidrs  = ["10.0.0.0/24",  "10.0.1.0/24",  "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
  db_subnet_cidrs      = ["10.0.20.0/24", "10.0.21.0/24", "10.0.22.0/24"]

  enable_nat_gateway  = true
  single_nat_gateway  = false   # one NAT per AZ for HA

  enable_vpce_s3        = true
  enable_vpce_dynamodb  = true

  interface_endpoints = ["ecr.api", "ecr.dkr", "secretsmanager", "ssm", "logs", "sts", "execute-api"]

  enable_flow_logs          = true
  flow_log_retention_days   = 30
  flow_log_kms_key_arn      = module.kms.key_arn

  tags = { Team = "platform" }
}
```

### Dev/QA (cost-optimized)

```hcl
module "network" {
  source = "../../modules/network"
  # ...
  single_nat_gateway  = true    # single NAT to reduce cost
  interface_endpoints = []       # no Interface endpoints in dev
}
```

## Required Inputs

| Name | Type | Description |
|---|---|---|
| `project` | `string` | Project name prefix |
| `environment` | `string` | Deployment environment |
| `region` | `string` | AWS region |
| `azs` | `list(string)` | AZ names to deploy subnets into |
| `public_subnet_cidrs` | `list(string)` | CIDRs for public subnets (one per AZ) |
| `private_subnet_cidrs` | `list(string)` | CIDRs for private compute subnets (one per AZ) |
| `db_subnet_cidrs` | `list(string)` | CIDRs for isolated/DB subnets (one per AZ) |

## Optional Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `vpc_cidr` | `string` | `"10.0.0.0/16"` | VPC CIDR block |
| `enable_nat_gateway` | `bool` | `true` | Create NAT Gateways for private subnet egress |
| `single_nat_gateway` | `bool` | `false` | Single NAT Gateway instead of one per AZ (dev/qa cost saving) |
| `enable_vpce_s3` | `bool` | `true` | Gateway VPC Endpoint for S3 (free) |
| `enable_vpce_dynamodb` | `bool` | `true` | Gateway VPC Endpoint for DynamoDB (free) |
| `interface_endpoints` | `set(string)` | 7 common services | Interface VPC Endpoints to create |
| `enable_flow_logs` | `bool` | `true` | Enable VPC Flow Logs to CloudWatch |
| `flow_log_retention_days` | `number` | `30` | Flow log retention in days |
| `flow_log_kms_key_arn` | `string` | `null` | KMS key for flow log encryption |
| `tags` | `map(string)` | `{}` | Additional resource tags |

## Outputs

| Name | Description |
|---|---|
| `vpc_id` | VPC ID |
| `vpc_cidr` | VPC CIDR block |
| `public_subnet_ids` | Public subnet IDs (one per AZ) |
| `private_subnet_ids` | Private subnet IDs (one per AZ) |
| `db_subnet_ids` | Isolated/DB subnet IDs (one per AZ) |
| `public_route_table_id` | Public route table ID |
| `private_route_table_ids` | Private route table IDs (per AZ) |
| `internet_gateway_id` | Internet Gateway ID |
| `nat_gateway_ids` | NAT Gateway IDs |
| `nat_public_ips` | Elastic IPs assigned to NAT Gateways |
| `vpce_security_group_id` | Security group for Interface VPC Endpoints |
| `interface_endpoint_ids` | Map of service name to Interface VPC Endpoint ID |
| `vpce_s3_id` | S3 Gateway VPC Endpoint ID |
| `vpce_dynamodb_id` | DynamoDB Gateway VPC Endpoint ID |
| `flow_log_log_group_arn` | CloudWatch Log Group ARN for VPC Flow Logs |
