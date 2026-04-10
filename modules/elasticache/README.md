# Module: `elasticache`

Creates a Redis replication group with Multi-AZ, automatic failover, encryption in transit and at rest, and optional AUTH token.

Full name pattern: `{project}-{environment}-{region_short}-redis-{cluster_id}`

## Usage

```hcl
module "cache" {
  source = "../../modules/elasticache"

  project    = "myapp"
  environment = "prod"
  region     = "us-east-1"
  cluster_id = "session"

  node_type           = "cache.r7g.large"
  num_cache_clusters  = 2
  subnet_ids          = module.network.db_subnet_ids
  security_group_ids  = [aws_security_group.elasticache.id]

  tags = { Team = "backend" }
}
```

## Required Inputs

| Name | Type | Description |
|---|---|---|
| `project` | `string` | Project name prefix |
| `environment` | `string` | Deployment environment |
| `region` | `string` | AWS region |
| `cluster_id` | `string` | Short cluster identifier |
| `subnet_ids` | `list(string)` | Subnet IDs (use isolated/DB subnets) |
| `security_group_ids` | `list(string)` | Security group IDs |

## Optional Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `node_type` | `string` | `"cache.r7g.large"` | ElastiCache node type |
| `engine_version` | `string` | `"7.1"` | Redis engine version |
| `num_cache_clusters` | `number` | `2` | Number of nodes (1 = no replication) |
| `automatic_failover_enabled` | `bool` | `true` | Enable automatic failover |
| `multi_az_enabled` | `bool` | `true` | Enable Multi-AZ |
| `port` | `number` | `6379` | Redis port |
| `at_rest_encryption_enabled` | `bool` | `true` | Encrypt data at rest |
| `transit_encryption_enabled` | `bool` | `true` | Enable TLS in transit |
| `kms_key_arn` | `string` | `null` | KMS key for at-rest encryption |
| `auth_token_secret_arn` | `string` | `null` | Secrets Manager ARN for AUTH token |
| `snapshot_retention_limit` | `number` | `7` | Snapshot retention days |
| `snapshot_window` | `string` | `"03:00-04:00"` | Daily snapshot window (UTC) |
| `maintenance_window` | `string` | `"sun:05:00-sun:06:00"` | Weekly maintenance window |
| `log_delivery_configurations` | `list(object)` | `[]` | Log delivery to CloudWatch or Firehose |
| `tags` | `map(string)` | `{}` | Additional resource tags |

## Outputs

| Name | Description |
|---|---|
| `primary_endpoint` | Primary (writer) endpoint address |
| `reader_endpoint` | Reader endpoint address |
| `port` | Redis port |
| `replication_group_id` | Replication group ID |
| `arn` | Replication group ARN |
| `subnet_group_name` | Subnet group name |
