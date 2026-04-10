# Module: `kinesis`

Creates a Kinesis Data Stream with configurable on-demand or provisioned capacity, optional KMS encryption, and enhanced fan-out consumers.

Full name pattern: `{project}-{environment}-{region_short}-kinesis-{stream_name}`

## Usage

```hcl
module "events_stream" {
  source = "../../modules/kinesis"

  project     = "myapp"
  environment = "prod"
  region      = "us-east-1"
  stream_name = "events"

  on_demand              = true
  retention_period_hours = 48
  kms_key_arn            = module.kms.key_arn

  enhanced_fan_out_consumers = ["processor", "analytics"]

  tags = { Team = "platform" }
}
```

### Provisioned mode

```hcl
module "stream" {
  source = "../../modules/kinesis"
  # ...
  on_demand   = false
  shard_count = 4
}
```

## Required Inputs

| Name | Type | Description |
|---|---|---|
| `project` | `string` | Project name prefix |
| `environment` | `string` | Deployment environment |
| `region` | `string` | AWS region |
| `stream_name` | `string` | Short stream name |

## Optional Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `on_demand` | `bool` | `true` | Use on-demand capacity mode |
| `shard_count` | `number` | `1` | Number of shards (PROVISIONED mode only) |
| `retention_period_hours` | `number` | `24` | Retention period in hours (24–8760) |
| `kms_key_arn` | `string` | `null` | KMS key ARN for server-side encryption |
| `enhanced_fan_out_consumers` | `list(string)` | `[]` | Consumer names to register for enhanced fan-out |
| `shard_level_metrics` | `list(string)` | all metrics | Shard-level CloudWatch metrics to enable |
| `tags` | `map(string)` | `{}` | Additional resource tags |

## Outputs

| Name | Description |
|---|---|
| `stream_arn` | Kinesis stream ARN |
| `stream_name` | Kinesis stream name |
| `consumer_arns` | Map of consumer name to ARN |
