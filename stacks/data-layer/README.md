# Stack: `data-layer`

Provisions the persistence tier: Aurora (PostgreSQL or MySQL), ElastiCache Redis, DynamoDB tables, and S3 buckets — all encrypted with a shared KMS key. Each service is independently toggleable.

## What it creates

- KMS customer-managed key (shared across all data resources)
- Aurora cluster + instances (optional, `rds_enabled = true`)
- ElastiCache Redis replication group (optional, `elasticache_enabled = true`)
- DynamoDB tables (one per entry in `dynamodb_tables`)
- S3 buckets (one per entry in `s3_buckets`)

## Usage

```hcl
module "data" {
  source = "../../stacks/data-layer"

  project     = "myapp"
  environment = "prod"
  region      = "us-east-1"

  db_subnet_ids      = module.platform.db_subnet_ids
  sg_rds_ids         = [module.platform.sg_rds_id]
  sg_elasticache_ids = [module.platform.sg_elasticache_id]

  rds_enabled        = true
  rds_engine         = "aurora-postgresql"
  rds_engine_version = "15.4"
  rds_instance_class = "db.r8g.large"
  rds_instance_count = 2
  rds_database_name  = "appdb"

  elasticache_enabled     = true
  elasticache_node_type   = "cache.r7g.large"
  elasticache_cluster_count = 2

  dynamodb_tables = {
    sessions = { hash_key = "session_id", billing_mode = "PAY_PER_REQUEST" }
    events   = { hash_key = "event_id", range_key = "created_at" }
  }

  s3_buckets = {
    uploads  = { versioning = true }
    exports  = {}
  }

  tags = { Team = "data" }
}
```

## Required Inputs

| Name | Type | Description |
|---|---|---|
| `project` | `string` | Project name prefix |
| `environment` | `string` | Deployment environment |
| `region` | `string` | AWS region |
| `db_subnet_ids` | `list(string)` | Isolated/DB subnet IDs |

## Optional Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `rds_enabled` | `bool` | `true` | Create Aurora cluster |
| `rds_engine` | `string` | `"aurora-postgresql"` | Aurora engine |
| `rds_engine_version` | `string` | `"15.4"` | Engine version |
| `rds_instance_class` | `string` | `"db.r8g.large"` | DB instance class |
| `rds_serverless_v2` | `bool` | `false` | Use Aurora Serverless v2 |
| `rds_instance_count` | `number` | `2` | Number of DB instances |
| `rds_database_name` | `string` | `"appdb"` | Initial database name |
| `rds_deletion_protection` | `bool` | `true` | Prevent accidental deletion |
| `rds_skip_final_snapshot` | `bool` | `false` | Skip final snapshot (set `true` in dev only) |
| `sg_rds_ids` | `list(string)` | `[]` | Security group IDs for RDS |
| `elasticache_enabled` | `bool` | `true` | Create ElastiCache Redis |
| `elasticache_node_type` | `string` | `"cache.r7g.large"` | Redis node type |
| `elasticache_cluster_count` | `number` | `2` | Number of Redis nodes |
| `sg_elasticache_ids` | `list(string)` | `[]` | Security group IDs for ElastiCache |
| `dynamodb_tables` | `map(object)` | `{}` | DynamoDB table configurations |
| `s3_buckets` | `map(object)` | `{}` | S3 bucket configurations |
| `tags` | `map(string)` | `{}` | Additional resource tags |

## Outputs

| Name | Description |
|---|---|
| `kms_key_arn` | KMS key ARN used for all data encryption |
| `rds_cluster_endpoint` | Aurora writer endpoint (null if disabled) |
| `rds_reader_endpoint` | Aurora reader endpoint (null if disabled) |
| `redis_primary_endpoint` | Redis primary endpoint (null if disabled) |
| `dynamodb_table_names` | Map of table key to table name |
| `s3_bucket_ids` | Map of bucket key to bucket ID |
