# Stack: `serverless`

Deploys a serverless workload: a Lambda function wired to an SQS queue for event-driven processing, with optional DynamoDB state storage and EventBridge schedules.

## What it creates

- Lambda function + execution role + CloudWatch log group
- SQS queue + DLQ (Lambda event source mapping)
- Optional DynamoDB table for state/results
- Optional EventBridge schedule rules targeting the Lambda
- Optional VPC config for private resource access

## Usage

```hcl
module "order_processor" {
  source = "../../stacks/serverless"

  project     = "myapp"
  environment = "prod"
  region      = "us-east-1"
  name        = "order-processor"

  lambda_runtime = "python3.12"
  lambda_handler = "handler.process"
  lambda_s3_bucket = "myapp-prod-use1-s3-lambda-artifacts"
  lambda_s3_key    = "lambda/order-processor/abc1234.zip"
  lambda_memory_size = 512
  lambda_timeout     = 60

  dynamodb_table_name = "order-results"
  dynamodb_hash_key   = "order_id"

  lambda_environment_variables = {
    LOG_LEVEL = "INFO"
    TABLE_ARN = "arn:aws:dynamodb:..."  # injected after first apply
  }

  kms_key_arn = module.platform.platform_kms_key_arn
  tags = { Team = "backend" }
}
```

### With a schedule

```hcl
module "daily_report" {
  source = "../../stacks/serverless"
  # ...
  schedule_expressions = ["cron(0 8 * * ? *)"]
}
```

## Required Inputs

| Name | Type | Description |
|---|---|---|
| `project` | `string` | Project name prefix |
| `environment` | `string` | Deployment environment |
| `region` | `string` | AWS region |
| `name` | `string` | Short workload name |

## Optional Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `lambda_runtime` | `string` | `"python3.12"` | Lambda runtime |
| `lambda_handler` | `string` | `"handler.main"` | Handler entrypoint |
| `lambda_s3_bucket` | `string` | `null` | S3 bucket for deployment package |
| `lambda_s3_key` | `string` | `null` | S3 key for deployment package |
| `lambda_memory_size` | `number` | `512` | Memory in MiB |
| `lambda_timeout` | `number` | `60` | Timeout in seconds |
| `lambda_environment_variables` | `map(string)` | `{}` | Lambda environment variables |
| `dynamodb_table_name` | `string` | `null` | Create a DynamoDB table with this name |
| `dynamodb_hash_key` | `string` | `"id"` | DynamoDB partition key |
| `schedule_expressions` | `list(string)` | `[]` | EventBridge schedule expressions |
| `kms_key_arn` | `string` | `null` | KMS key for SQS and Lambda encryption |
| `vpc_config` | `object` | `null` | `{ subnet_ids, security_group_ids }` for VPC Lambda |
| `tags` | `map(string)` | `{}` | Additional resource tags |

## Outputs

| Name | Description |
|---|---|
| `lambda_arn` | Lambda function ARN |
| `lambda_name` | Lambda function name |
| `queue_url` | SQS queue URL |
| `dlq_url` | Dead-letter queue URL |
| `dynamodb_table` | DynamoDB table name (null if not created) |
