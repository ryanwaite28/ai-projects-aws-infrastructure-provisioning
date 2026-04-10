# Module: `firehose`

Creates a Kinesis Data Firehose delivery stream with S3 destination, dynamic partitioning, optional Lambda transformation, and CloudWatch error logging.

Full name pattern: `{project}-{environment}-{region_short}-firehose-{stream_name}`

## Usage

```hcl
module "logs_firehose" {
  source = "../../modules/firehose"

  project      = "myapp"
  environment  = "prod"
  region       = "us-east-1"
  stream_name  = "app-logs"
  s3_bucket_arn = module.logs_bucket.bucket_arn

  source_kinesis_stream_arn = module.events_stream.stream_arn
  transformation_lambda_arn = module.transformer.function_arn

  buffering_size_mb          = 64
  buffering_interval_seconds = 300
  kms_key_arn                = module.kms.key_arn

  tags = { Team = "platform" }
}
```

## Required Inputs

| Name | Type | Description |
|---|---|---|
| `project` | `string` | Project name prefix |
| `environment` | `string` | Deployment environment |
| `region` | `string` | AWS region |
| `stream_name` | `string` | Short stream name |
| `s3_bucket_arn` | `string` | Destination S3 bucket ARN |

## Optional Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `source_kinesis_stream_arn` | `string` | `null` | Kinesis Data Stream as source. If null, Direct PUT is used |
| `destination` | `string` | `"s3"` | Delivery destination: `s3`, `redshift`, `opensearch`, `http_endpoint` |
| `s3_prefix` | `string` | hive-style date prefix | S3 key prefix (supports dynamic partitioning expressions) |
| `s3_error_prefix` | `string` | error prefix | S3 prefix for delivery errors |
| `buffering_size_mb` | `number` | `64` | Buffer size in MB before delivery (1–128) |
| `buffering_interval_seconds` | `number` | `300` | Buffer interval in seconds (60–900) |
| `s3_compression_format` | `string` | `"GZIP"` | Compression: `UNCOMPRESSED`, `GZIP`, `ZIP`, `Snappy` |
| `dynamic_partitioning_enabled` | `bool` | `true` | Enable dynamic partitioning |
| `transformation_lambda_arn` | `string` | `null` | Lambda ARN for record transformation |
| `transformation_buffer_size_mb` | `number` | `3` | Buffer size for Lambda transformation (1–3) |
| `transformation_buffer_interval_seconds` | `number` | `60` | Buffer interval for Lambda transformation (60–900) |
| `kms_key_arn` | `string` | `null` | KMS key ARN for server-side encryption |
| `cloudwatch_logging_enabled` | `bool` | `true` | Enable CloudWatch error logging |
| `tags` | `map(string)` | `{}` | Additional resource tags |

## Outputs

| Name | Description |
|---|---|
| `stream_arn` | Firehose delivery stream ARN |
| `stream_name` | Firehose stream name |
| `delivery_role_arn` | IAM role ARN used by Firehose for delivery |
