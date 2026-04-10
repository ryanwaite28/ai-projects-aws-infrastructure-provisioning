# Stack: `notification`

Deploys an SNS topic with fan-out to SQS subscriber queues, Lambda functions, and/or email addresses. Use this for any publish/subscribe notification pattern.

## What it creates

- SNS topic (standard)
- Optional KMS encryption
- SQS subscriber queues (one per entry in `sqs_subscribers`) with SNS subscription
- Lambda subscriptions (for existing Lambda ARNs)
- Email subscriptions

## Usage

```hcl
module "order_notifications" {
  source = "../../stacks/notification"

  project     = "myapp"
  environment = "prod"
  region      = "us-east-1"
  topic_name  = "order-events"

  sqs_subscribers = {
    fulfillment = {}   # creates a queue named fulfillment and subscribes it
    analytics   = {}
  }

  email_subscribers = ["ops@example.com"]

  allowed_publisher_arns = [
    module.api_service.task_role_arn
  ]

  kms_key_arn = module.platform.platform_kms_key_arn
  tags = { Team = "platform" }
}
```

## Required Inputs

| Name | Type | Description |
|---|---|---|
| `project` | `string` | Project name prefix |
| `environment` | `string` | Deployment environment |
| `region` | `string` | AWS region |
| `topic_name` | `string` | Short topic name |

## Optional Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `allowed_publisher_arns` | `list(string)` | `[]` | IAM principals allowed to publish to the topic |
| `sqs_subscribers` | `map(any)` | `{}` | SQS subscriber configs. One queue created per key |
| `lambda_subscriber_arns` | `list(string)` | `[]` | Existing Lambda ARNs to subscribe |
| `email_subscribers` | `list(string)` | `[]` | Email addresses to subscribe |
| `kms_key_arn` | `string` | `null` | KMS key for topic encryption |
| `tags` | `map(string)` | `{}` | Additional resource tags |

## Outputs

| Name | Description |
|---|---|
| `topic_arn` | SNS topic ARN |
| `topic_name` | SNS topic name |
| `queue_arns` | Map of subscriber name to SQS queue ARN |
