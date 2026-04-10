# Module: `rds`

Creates an Aurora cluster (PostgreSQL or MySQL) with managed password rotation, enhanced monitoring, and Performance Insights. Supports Aurora Serverless v2.

Full name pattern: `{project}-{environment}-{region_short}-{cluster_identifier}`

## Usage

```hcl
module "db" {
  source = "../../modules/rds"

  project            = "myapp"
  environment        = "prod"
  region             = "us-east-1"
  cluster_identifier = "primary"
  database_name      = "appdb"
  subnet_ids         = module.network.db_subnet_ids
  vpc_security_group_ids = [aws_security_group.rds.id]

  engine         = "aurora-postgresql"
  engine_version = "15.4"
  instance_count = 2
  instance_class = "db.r8g.large"

  deletion_protection     = true
  skip_final_snapshot     = false

  tags = { Team = "data" }
}
```

### Aurora Serverless v2

```hcl
module "db" {
  source = "../../modules/rds"
  # ...
  serverless_v2     = true
  serverless_min_acu = 0.5
  serverless_max_acu = 32
  instance_class    = "db.serverless"
}
```

## Required Inputs

| Name | Type | Description |
|---|---|---|
| `project` | `string` | Project name prefix |
| `environment` | `string` | Deployment environment |
| `region` | `string` | AWS region |
| `cluster_identifier` | `string` | Short cluster identifier |
| `database_name` | `string` | Initial database name |
| `subnet_ids` | `list(string)` | DB subnet IDs (use isolated subnets) |
| `vpc_security_group_ids` | `list(string)` | Security group IDs |

## Optional Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `engine` | `string` | `"aurora-postgresql"` | `aurora-postgresql`, `aurora-mysql`, `postgres`, `mysql` |
| `engine_version` | `string` | `"15.4"` | Engine version |
| `instance_class` | `string` | `"db.r8g.large"` | DB instance class |
| `serverless_v2` | `bool` | `false` | Use Aurora Serverless v2 |
| `serverless_min_acu` | `number` | `0.5` | Serverless v2 minimum ACUs |
| `serverless_max_acu` | `number` | `16` | Serverless v2 maximum ACUs |
| `instance_count` | `number` | `2` | Number of instances (1 = writer only) |
| `master_username` | `string` | `"dbadmin"` | Master username |
| `master_password_secret_arn` | `string` | `null` | Secrets Manager ARN for password (null = RDS manages) |
| `backup_retention_period` | `number` | `7` | Backup retention days |
| `deletion_protection` | `bool` | `true` | Prevent accidental deletion |
| `skip_final_snapshot` | `bool` | `false` | Skip final snapshot on destroy (set `true` only in dev) |
| `kms_key_arn` | `string` | `null` | KMS key for storage encryption |
| `performance_insights_enabled` | `bool` | `true` | Enable Performance Insights |
| `monitoring_interval` | `number` | `60` | Enhanced Monitoring interval in seconds |
| `apply_immediately` | `bool` | `false` | Apply changes immediately |
| `tags` | `map(string)` | `{}` | Additional resource tags |

## Outputs

| Name | Description |
|---|---|
| `cluster_id` | RDS cluster ID |
| `cluster_arn` | RDS cluster ARN |
| `cluster_endpoint` | Writer endpoint |
| `reader_endpoint` | Reader endpoint |
| `port` | Database port |
| `database_name` | Database name |
| `master_user_secret_arn` | Secrets Manager ARN for the auto-managed password |
| `subnet_group_name` | DB subnet group name |
