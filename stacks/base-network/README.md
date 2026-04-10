# Stack: `base-network`

Provisions the foundational VPC layer: public, private, and isolated/DB subnets across multiple AZs, NAT Gateways, Gateway VPC Endpoints (S3, DynamoDB), Interface VPC Endpoints, and VPC Flow Logs.

This stack is consumed as a child module by `stacks/platform`. It can also be applied standalone if you need networking without the full platform stack.

## What it creates

- VPC
- Public subnets (one per AZ) — ALBs, NAT Gateway EIPs
- Private subnets (one per AZ) — ECS tasks, Lambda, EC2
- Isolated/DB subnets (one per AZ) — RDS, ElastiCache (no internet route)
- Internet Gateway
- NAT Gateways (one per AZ, or one shared in dev/qa)
- S3 and DynamoDB Gateway VPC Endpoints (free)
- Interface VPC Endpoints (ECR, Secrets Manager, SSM, CloudWatch Logs, STS, execute-api)
- VPC Flow Logs → CloudWatch

## Usage

```hcl
module "network" {
  source = "../../stacks/base-network"

  project     = "myapp"
  environment = "prod"
  region      = "us-east-1"

  vpc_cidr             = "10.0.0.0/16"
  azs                  = ["us-east-1a", "us-east-1b", "us-east-1c"]
  public_subnet_cidrs  = ["10.0.0.0/24",  "10.0.1.0/24",  "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
  db_subnet_cidrs      = ["10.0.20.0/24", "10.0.21.0/24", "10.0.22.0/24"]

  single_nat_gateway = false  # one NAT per AZ for HA (set true in dev/qa)
}
```

## Required Inputs

| Name | Type | Description |
|---|---|---|
| `project` | `string` | Project name prefix |
| `environment` | `string` | Deployment environment |
| `region` | `string` | AWS region |
| `azs` | `list(string)` | Availability zone names |
| `public_subnet_cidrs` | `list(string)` | Public subnet CIDRs (one per AZ) |
| `private_subnet_cidrs` | `list(string)` | Private subnet CIDRs (one per AZ) |
| `db_subnet_cidrs` | `list(string)` | Isolated/DB subnet CIDRs (one per AZ) |

## Optional Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `vpc_cidr` | `string` | `"10.0.0.0/16"` | VPC CIDR block |
| `single_nat_gateway` | `bool` | `false` | Share one NAT Gateway across all AZs (cost-saving for dev/qa) |
| `interface_endpoints` | `set(string)` | 6 services | AWS services to create Interface VPC Endpoints for |
| `flow_log_kms_key_arn` | `string` | `null` | KMS key for VPC Flow Log encryption |
| `tags` | `map(string)` | `{}` | Additional resource tags |

## Outputs

| Name | Description |
|---|---|
| `vpc_id` | VPC ID |
| `vpc_cidr` | VPC CIDR |
| `public_subnet_ids` | Public subnet IDs |
| `private_subnet_ids` | Private subnet IDs |
| `db_subnet_ids` | Isolated/DB subnet IDs |
| `nat_public_ips` | Elastic IPs on the NAT Gateways |
| `vpce_security_group_id` | Security group for Interface VPC Endpoints |
| `interface_endpoint_ids` | Map of service name → endpoint ID |
