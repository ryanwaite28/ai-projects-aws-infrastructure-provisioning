# Stack: `data-pipeline`

Deploys a streaming data pipeline: Kinesis Data Stream → Kinesis Firehose → S3, with optional Lambda transformation between Firehose and S3. Supports dynamic S3 partitioning by date.

## What it creates

- Kinesis Data Stream (on-demand or provisioned)
- S3 destination bucket (with Hive-style date partitioning prefix)
- Kinesis Firehose delivery stream (Kinesis → S3)
- Optional Lambda transformer function

## Usage

```hcl
module "events_pipeline" {
  source = "../../stacks/data-pipeline"

  project     = "myapp"
  environment = "prod"
  region      = "us-east-1"
  name        = "events"

  kinesis_on_demand      = true
  kinesis_retention_hours = 48

  buffering_size_mb          = 64
  buffering_interval_seconds = 300
  dynamic_partitioning       = true

  kms_key_arn = module.platform.platform_kms_key_arn
  tags = { Team = "data" }
}
```

### With Lambda transformation

```hcl
module "pipeline" {
  source = "../../stacks/data-pipeline"
  # ...
  enable_transformation = true
  lambda_runtime        = "python3.12"
  lambda_handler        = "transformer.handler"
  lambda_s3_bucket      = "myapp-prod-use1-s3-lambda-artifacts"
  lambda_s3_key         = "lambda/transformer/latest.zip"
}
```

## Required Inputs

| Name | Type | Description |
|---|---|---|
| `project` | `string` | Project name prefix |
| `environment` | `string` | Deployment environment |
| `region` | `string` | AWS region |
| `name` | `string` | Short pipeline name |

## Optional Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `kinesis_on_demand` | `bool` | `true` | On-demand capacity (false = provisioned) |
| `kinesis_shard_count` | `number` | `1` | Shards (provisioned mode only) |
| `kinesis_retention_hours` | `number` | `24` | Stream retention (24–8760 hours) |
| `dynamic_partitioning` | `bool` | `true` | Enable Firehose dynamic partitioning |
| `buffering_size_mb` | `number` | `64` | Firehose buffer size in MB (1–128) |
| `buffering_interval_seconds` | `number` | `300` | Firehose buffer interval (60–900) |
| `enable_transformation` | `bool` | `false` | Enable Lambda record transformation |
| `lambda_runtime` | `string` | `"python3.12"` | Transformer Lambda runtime |
| `lambda_handler` | `string` | `"transformer.handler"` | Transformer handler |
| `lambda_s3_bucket` | `string` | `null` | S3 bucket for transformer package |
| `lambda_s3_key` | `string` | `null` | S3 key for transformer package |
| `kms_key_arn` | `string` | `null` | KMS key for Kinesis + S3 encryption |
| `tags` | `map(string)` | `{}` | Additional resource tags |

## Outputs

| Name | Description |
|---|---|
| `kinesis_stream_arn` | Kinesis Data Stream ARN |
| `firehose_stream_arn` | Firehose delivery stream ARN |
| `s3_bucket_name` | Destination S3 bucket name |
| `transformer_lambda_arn` | Transformer Lambda ARN (null if disabled) |
