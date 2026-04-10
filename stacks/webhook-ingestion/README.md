# Stack: `webhook-ingestion`

Deploys a durable webhook ingestion pipeline: API Gateway REST API → SQS queue → Lambda processor. The API Gateway layer handles authentication and rate limiting; SQS provides buffering and retry with a dead-letter queue; Lambda processes messages asynchronously.

## What it creates

- API Gateway REST API with a `/webhooks` POST endpoint
- API Gateway stage with throttling and optional WAF association
- SQS standard queue with DLQ
- Lambda function (processor) triggered from SQS via event source mapping
- IAM execution role for the processor Lambda
- Optional: API key, custom domain with ACM certificate, VPC networking for the Lambda

## Architecture

```
External → POST /webhooks → API Gateway → SQS Queue → Lambda Processor
                                              ↓ (after N failures)
                                           Dead-Letter Queue
```

## Usage

```hcl
module "stripe_webhooks" {
  source = "../../stacks/webhook-ingestion"

  project     = "myapp"
  environment = "prod"
  region      = "us-east-1"
  name        = "stripe"

  # API Gateway
  stage_name             = "v1"
  throttling_rate_limit  = 500
  throttling_burst_limit = 1000
  api_key_required       = true

  # SQS
  sqs_visibility_timeout_seconds = 360   # >= 6× processor_timeout
  dlq_max_receive_count          = 3

  # Processor Lambda
  processor_runtime  = "python3.12"
  processor_handler  = "handler.process"
  processor_s3_bucket = "myapp-prod-use1-s3-lambda-artifacts"
  processor_s3_key    = "lambda/stripe-processor/latest.zip"
  processor_timeout   = 60
  processor_memory_size = 512
  processor_sqs_batch_size = 10

  processor_environment_variables = {
    STRIPE_WEBHOOK_SECRET_ARN = aws_secretsmanager_secret.stripe.arn
  }

  kms_key_arn = module.platform.platform_kms_key_arn
  tags = { Team = "payments" }
}
```

### With custom domain

```hcl
module "webhooks" {
  source = "../../stacks/webhook-ingestion"
  # ...
  custom_domain_name            = "hooks.example.com"
  custom_domain_certificate_arn = module.acm.certificate_arn
}
```

### With VPC (processor needs database access)

```hcl
module "webhooks" {
  source = "../../stacks/webhook-ingestion"
  # ...
  vpc_config = {
    subnet_ids         = module.platform.private_subnet_ids
    security_group_ids = [module.platform.sg_lambda_id]
  }
}
```

## Required Inputs

| Name | Type | Description |
|---|---|---|
| `project` | `string` | Project name prefix |
| `environment` | `string` | Deployment environment |
| `region` | `string` | AWS region |
| `name` | `string` | Short identifier for this webhook endpoint (e.g. `stripe`, `github`) |

## Optional Inputs — API Gateway

| Name | Type | Default | Description |
|---|---|---|---|
| `stage_name` | `string` | `"v1"` | REST API stage name |
| `throttling_rate_limit` | `number` | `100` | Steady-state requests/second |
| `throttling_burst_limit` | `number` | `200` | Burst request rate |
| `api_key_required` | `bool` | `false` | Require `x-api-key` header |
| `waf_acl_arn` | `string` | `null` | WAFv2 Web ACL ARN to associate with the stage |
| `custom_domain_name` | `string` | `null` | Custom domain (e.g. `hooks.example.com`) |
| `custom_domain_certificate_arn` | `string` | `null` | ACM certificate for the custom domain (same region) |
| `log_retention_days` | `number` | `30` | CloudWatch log retention |

## Optional Inputs — SQS

| Name | Type | Default | Description |
|---|---|---|---|
| `sqs_visibility_timeout_seconds` | `number` | `300` | Visibility timeout (should be ≥ 6× Lambda timeout) |
| `sqs_message_retention_seconds` | `number` | `1209600` | Message retention (14 days) |
| `dlq_max_receive_count` | `number` | `3` | Failures before DLQ routing |

## Optional Inputs — Processor Lambda

| Name | Type | Default | Description |
|---|---|---|---|
| `processor_runtime` | `string` | `"python3.12"` | Lambda runtime |
| `processor_handler` | `string` | `"handler.process"` | Lambda handler entrypoint |
| `processor_s3_bucket` | `string` | `null` | S3 bucket for deployment package |
| `processor_s3_key` | `string` | `null` | S3 key for deployment package |
| `processor_memory_size` | `number` | `512` | Memory in MB |
| `processor_timeout` | `number` | `60` | Timeout in seconds |
| `processor_reserved_concurrency` | `number` | `-1` | Reserved concurrency (-1 = unreserved) |
| `processor_sqs_batch_size` | `number` | `10` | Messages per invocation |
| `processor_sqs_max_batching_window` | `number` | `5` | Seconds to accumulate messages (0–300) |
| `processor_environment_variables` | `map(string)` | `{}` | Environment variables |

## Optional Inputs — Shared

| Name | Type | Default | Description |
|---|---|---|---|
| `kms_key_arn` | `string` | `null` | KMS key for SQS + Lambda encryption |
| `vpc_config` | `object` | `null` | VPC subnet and security group IDs for the Lambda |
| `tags` | `map(string)` | `{}` | Additional resource tags |

## Outputs

| Name | Description |
|---|---|
| `api_id` | REST API ID |
| `api_endpoint` | Full POST endpoint URL — send webhook payloads here |
| `stage_invoke_url` | Stage base URL |
| `custom_domain_target` | DNS target for Route 53 alias (null if no custom domain) |
| `api_key_value` | API key value — sensitive, only set when `api_key_required = true` |
| `queue_url` | SQS queue URL |
| `queue_arn` | SQS queue ARN |
| `queue_name` | SQS queue name |
| `dlq_url` | Dead-letter queue URL |
| `dlq_arn` | Dead-letter queue ARN |
| `processor_lambda_arn` | Processor Lambda ARN |
| `processor_lambda_name` | Processor Lambda function name |
| `processor_lambda_role_arn` | Processor Lambda execution role ARN |

## Notes

- **Visibility timeout rule**: `sqs_visibility_timeout_seconds` must be at least 6× `processor_timeout`. The default pair (300s / 60s) satisfies this. If you increase `processor_timeout`, raise `sqs_visibility_timeout_seconds` proportionally.
- **API key security**: `api_key_value` is marked sensitive in Terraform state. After apply, retrieve it with `terraform output -raw api_key_value` and store it in Secrets Manager or share it with the webhook sender out-of-band.
- **DLQ monitoring**: Wire the `dlq_arn` to a CloudWatch alarm via the `monitoring` module to alert on processing failures.
- **Idempotency**: The processor Lambda should be idempotent — SQS delivers at-least-once, so duplicate messages are possible, especially during Lambda retries.
