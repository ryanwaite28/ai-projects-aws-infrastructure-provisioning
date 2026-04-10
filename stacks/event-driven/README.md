# Stack: `event-driven`

Deploys an EventBridge custom event bus with rules that route events to Lambda consumer functions. Each consumer gets its own Lambda function + execution role + log group.

## What it creates

- EventBridge custom event bus
- EventBridge rules (pattern-based or schedule-based)
- Lambda consumer functions (one per entry in `consumers`)
- Lambda resource-based policies allowing EventBridge invocation
- Optional VPC config per consumer

## Usage

```hcl
module "order_events" {
  source = "../../stacks/event-driven"

  project     = "myapp"
  environment = "prod"
  region      = "us-east-1"
  bus_name    = "orders"

  event_rules = {
    order-placed = {
      description   = "Route order.placed events"
      event_pattern = jsonencode({
        source      = ["myapp.orders"]
        detail-type = ["order.placed"]
      })
      targets = [
        { id = "processor", arn = "CONSUMER_ARN_PLACEHOLDER" }
      ]
    }
  }

  consumers = {
    processor = {
      runtime  = "python3.12"
      handler  = "handler.process"
      s3_bucket = "myapp-prod-use1-s3-lambda-artifacts"
      s3_key    = "lambda/order-processor/latest.zip"
      memory_size = 512
      timeout     = 60
      environment_variables = {
        LOG_LEVEL = "INFO"
      }
    }
  }

  allowed_publisher_arns = [
    module.api.task_role_arn
  ]

  tags = { Team = "backend" }
}
```

## Required Inputs

| Name | Type | Description |
|---|---|---|
| `project` | `string` | Project name prefix |
| `environment` | `string` | Deployment environment |
| `region` | `string` | AWS region |
| `bus_name` | `string` | Short event bus name |

## Optional Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `allowed_publisher_arns` | `list(string)` | `[]` | IAM principal ARNs allowed to put events on this bus |
| `event_rules` | `any` | `{}` | Map of EventBridge rule configurations (see `modules/eventbridge`) |
| `consumers` | `map(object)` | `{}` | Lambda consumer functions keyed by short name |
| `tags` | `map(string)` | `{}` | Additional resource tags |

### Consumer object schema

| Field | Type | Default | Description |
|---|---|---|---|
| `runtime` | `string` | required | Lambda runtime |
| `handler` | `string` | required | Handler entrypoint |
| `s3_bucket` | `string` | `null` | S3 bucket for deployment package |
| `s3_key` | `string` | `null` | S3 key for deployment package |
| `memory_size` | `number` | `512` | Memory in MiB |
| `timeout` | `number` | `60` | Timeout in seconds |
| `environment_variables` | `map(string)` | `{}` | Environment variables |
| `vpc_config` | `object` | `null` | `{ subnet_ids, security_group_ids }` |

## Outputs

| Name | Description |
|---|---|
| `event_bus_arn` | Event bus ARN |
| `event_bus_name` | Event bus name |
| `consumer_lambda_arns` | Map of consumer name to Lambda ARN |
