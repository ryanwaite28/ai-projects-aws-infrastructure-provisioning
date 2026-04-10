# Module: `sqs`

Creates an SQS queue (standard or FIFO) with an optional dead-letter queue, encryption, and publisher IAM policy.

Full name pattern: `{project}-{environment}-{region_short}-{queue_name}[.fifo]`

## Usage

```hcl
module "orders_queue" {
  source = "../../modules/sqs"   # or git::https://github.com/your-org/infra.git//modules/sqs?ref=v1.0.0

  project     = "myapp"
  environment = "prod"
  region      = "us-east-1"
  queue_name  = "order-events"

  visibility_timeout_seconds = 300
  dlq_enabled                = true
  max_receive_count          = 3

  tags = { Team = "platform" }
}
```

## Required Inputs

| Name | Type | Description |
|---|---|---|
| `project` | `string` | Project name prefix |
| `environment` | `string` | Deployment environment |
| `region` | `string` | AWS region |
| `queue_name` | `string` | Short name for the queue |

## Optional Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `fifo` | `bool` | `false` | Create a FIFO queue |
| `content_based_deduplication` | `bool` | `true` | Enable content-based deduplication (FIFO only) |
| `visibility_timeout_seconds` | `number` | `30` | Message visibility timeout. Set to ≥6× your consumer's processing time |
| `message_retention_seconds` | `number` | `345600` | Message retention (4 days). Max 1209600 (14 days) |
| `max_message_size` | `number` | `262144` | Max message size in bytes |
| `delay_seconds` | `number` | `0` | Delivery delay |
| `receive_wait_time_seconds` | `number` | `20` | Long-poll wait time (0 = short polling) |
| `dlq_enabled` | `bool` | `true` | Create a dead-letter queue |
| `max_receive_count` | `number` | `5` | Receives before moving to DLQ |
| `kms_key_arn` | `string` | `null` | KMS key for SSE |
| `queue_policy_json` | `string` | `null` | Custom queue policy JSON (overrides allowed_publisher_arns) |
| `allowed_publisher_arns` | `list(string)` | `[]` | IAM principal ARNs allowed to SendMessage |
| `tags` | `map(string)` | `{}` | Additional resource tags |

## Outputs

| Name | Description |
|---|---|
| `queue_id` | Queue URL |
| `queue_arn` | Queue ARN |
| `queue_name` | Queue name |
| `dlq_id` | DLQ URL (null if disabled) |
| `dlq_arn` | DLQ ARN (null if disabled) |
