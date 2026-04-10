# Module: `sns`

Creates an SNS topic (standard or FIFO) with subscriptions and a resource-based access policy.

Full name pattern: `{project}-{environment}-{region_short}-{topic_name}[.fifo]`

## Usage

```hcl
module "notifications_topic" {
  source = "../../modules/sns"

  project     = "myapp"
  environment = "prod"
  region      = "us-east-1"
  topic_name  = "order-notifications"

  subscriptions = [
    {
      protocol = "sqs"
      endpoint = module.orders_queue.queue_arn
      raw_message_delivery = true
    },
    {
      protocol = "email"
      endpoint = "ops@example.com"
    }
  ]

  allowed_service_principals = ["events.amazonaws.com"]

  tags = { Team = "platform" }
}
```

## Required Inputs

| Name | Type | Description |
|---|---|---|
| `project` | `string` | Project name prefix |
| `environment` | `string` | Deployment environment |
| `region` | `string` | AWS region |
| `topic_name` | `string` | Short name for the topic |

## Optional Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `fifo` | `bool` | `false` | Create a FIFO topic |
| `content_based_deduplication` | `bool` | `false` | FIFO deduplication |
| `kms_key_arn` | `string` | `null` | KMS key for SSE |
| `subscriptions` | `list(object)` | `[]` | Subscription list. Each: `protocol`, `endpoint`, optional `filter_policy`, `raw_message_delivery`, `redrive_policy_dlq_arn` |
| `allowed_publisher_arns` | `list(string)` | `[]` | IAM principals allowed to Publish |
| `allowed_service_principals` | `list(string)` | `[]` | AWS service principals allowed to Publish (e.g. `cloudwatch.amazonaws.com`) |
| `topic_policy_statements` | `any` | `[]` | Additional IAM policy statements for the topic policy |
| `tags` | `map(string)` | `{}` | Additional resource tags |

## Outputs

| Name | Description |
|---|---|
| `topic_arn` | Topic ARN |
| `topic_name` | Topic name |
| `topic_id` | Topic ID (same as ARN) |
