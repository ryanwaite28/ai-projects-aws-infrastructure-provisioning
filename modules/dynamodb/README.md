# Module: `dynamodb`

Creates a DynamoDB table with optional GSIs, TTL, PITR, DynamoDB Streams, and Global Table replication.

Full name pattern: `{project}-{environment}-{region_short}-{table_name}`

## Usage

```hcl
module "sessions_table" {
  source = "../../modules/dynamodb"

  project     = "myapp"
  environment = "prod"
  region      = "us-east-1"
  table_name  = "sessions"
  hash_key    = "session_id"

  billing_mode           = "PAY_PER_REQUEST"
  ttl_attribute          = "expires_at"
  point_in_time_recovery = true

  tags = { Team = "backend" }
}
```

## Required Inputs

| Name | Type | Description |
|---|---|---|
| `project` | `string` | Project name prefix |
| `environment` | `string` | Deployment environment |
| `region` | `string` | AWS region |
| `table_name` | `string` | Short table name |
| `hash_key` | `string` | Partition key attribute name |

## Optional Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `hash_key_type` | `string` | `"S"` | Partition key type: `S`, `N`, or `B` |
| `range_key` | `string` | `null` | Sort key attribute name |
| `range_key_type` | `string` | `"S"` | Sort key type |
| `billing_mode` | `string` | `"PAY_PER_REQUEST"` | `PAY_PER_REQUEST` or `PROVISIONED` |
| `read_capacity` | `number` | `5` | Read capacity (PROVISIONED only) |
| `write_capacity` | `number` | `5` | Write capacity (PROVISIONED only) |
| `ttl_attribute` | `string` | `null` | Attribute name for TTL expiry |
| `point_in_time_recovery` | `bool` | `true` | Enable PITR |
| `deletion_protection` | `bool` | `false` | Prevent accidental deletion |
| `kms_key_arn` | `string` | `null` | KMS key for SSE (null = AWS-owned key) |
| `stream_enabled` | `bool` | `false` | Enable DynamoDB Streams |
| `stream_view_type` | `string` | `"NEW_AND_OLD_IMAGES"` | Stream view: `KEYS_ONLY`, `NEW_IMAGE`, `OLD_IMAGE`, `NEW_AND_OLD_IMAGES` |
| `attributes` | `list(object)` | `[]` | Additional attribute definitions for GSIs/LSIs: `[{name, type}]` |
| `global_secondary_indexes` | `list(object)` | `[]` | GSI configurations |
| `replica_regions` | `list(string)` | `[]` | Regions for Global Table replicas |
| `tags` | `map(string)` | `{}` | Additional resource tags |

## Outputs

| Name | Description |
|---|---|
| `table_name` | Table name |
| `table_arn` | Table ARN |
| `table_id` | Table ID |
| `stream_arn` | DynamoDB Streams ARN (null if disabled) |
| `stream_label` | Stream timestamp label |
