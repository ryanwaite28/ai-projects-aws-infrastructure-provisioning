# Module: `lambda`

Creates a Lambda function with a CloudWatch log group, an auto-created execution role (or BYO), optional VPC config, and SQS event source mappings.

Full name pattern: `{project}-{environment}-{region_short}-fn-{function_name}`

## Usage

```hcl
module "processor" {
  source = "../../modules/lambda"

  project          = "myapp"
  environment      = "prod"
  region           = "us-east-1"
  function_name    = "order-processor"
  description      = "Processes order events from SQS"
  runtime          = "python3.12"
  handler          = "handler.process"
  s3_bucket        = "myapp-prod-use1-s3-lambda-artifacts"
  s3_key           = "lambda/order-processor/abc1234.zip"
  memory_size      = 512
  timeout          = 60

  environment_variables = {
    DB_SECRET_ARN = aws_secretsmanager_secret.db.arn
  }

  sqs_event_source_arns = [module.orders_queue.queue_arn]
  sqs_batch_size        = 10

  tags = { Team = "backend" }
}
```

## Required Inputs

| Name | Type | Description |
|---|---|---|
| `project` | `string` | Project name prefix |
| `environment` | `string` | Deployment environment |
| `region` | `string` | AWS region |
| `function_name` | `string` | Short function name |

## Optional Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `description` | `string` | `""` | Human-readable description |
| `package_type` | `string` | `"Zip"` | `Zip` or `Image` |
| `runtime` | `string` | `null` | Lambda runtime (e.g. `python3.12`, `nodejs20.x`) |
| `handler` | `string` | `null` | Handler entrypoint (e.g. `handler.process`) |
| `filename` | `string` | `null` | Local ZIP path (mutually exclusive with `s3_bucket`) |
| `s3_bucket` | `string` | `null` | S3 bucket containing the ZIP |
| `s3_key` | `string` | `null` | S3 key of the ZIP |
| `image_uri` | `string` | `null` | ECR image URI (Image package type) |
| `memory_size` | `number` | `512` | Memory in MiB |
| `timeout` | `number` | `30` | Timeout in seconds (max 900) |
| `reserved_concurrent_executions` | `number` | `-1` | Reserved concurrency (-1 = unreserved, 0 = throttled) |
| `environment_variables` | `map(string)` | `{}` | Environment variables |
| `kms_key_arn` | `string` | `null` | KMS key for env var encryption |
| `execution_role_arn` | `string` | `null` | BYO execution role ARN. If null, a role is auto-created |
| `execution_role_extra_policies` | `map(string)` | `{}` | Extra inline policies for the auto-created role |
| `vpc_config` | `object` | `null` | `{ subnet_ids, security_group_ids }` |
| `layers` | `list(string)` | `[]` | Lambda layer ARNs (max 5) |
| `architectures` | `list(string)` | `["x86_64"]` | `x86_64` or `arm64` |
| `sqs_event_source_arns` | `list(string)` | `[]` | SQS queue ARNs for event source mappings |
| `sqs_batch_size` | `number` | `10` | Messages per invocation |
| `sqs_maximum_batching_window_seconds` | `number` | `0` | Batching window |
| `log_retention_days` | `number` | `30` | CloudWatch log retention |
| `publish_version` | `bool` | `false` | Publish a new version on every deploy |
| `tags` | `map(string)` | `{}` | Additional resource tags |

## Outputs

| Name | Description |
|---|---|
| `function_arn` | Lambda function ARN |
| `function_name` | Lambda function name |
| `function_invoke_arn` | Invoke ARN (use with API Gateway integrations) |
| `execution_role_arn` | Execution role ARN |
| `execution_role_name` | Execution role name (null if BYO role) |
| `log_group_name` | CloudWatch log group name |
| `qualified_arn` | Qualified ARN including version |
