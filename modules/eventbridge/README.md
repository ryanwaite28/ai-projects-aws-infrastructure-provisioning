# Module: `eventbridge`

Creates an EventBridge custom event bus (or uses the default bus) with rules, targets, and optional KMS encryption.

Full name pattern: `{project}-{environment}-{region_short}-bus-{bus_name}`

## Usage

```hcl
module "events" {
  source = "../../modules/eventbridge"

  project     = "myapp"
  environment = "prod"
  region      = "us-east-1"
  bus_name    = "orders"

  rules = {
    order-placed = {
      description   = "Route order.placed events to processor Lambda"
      event_pattern = jsonencode({
        source      = ["myapp.orders"]
        detail-type = ["order.placed"]
      })
      targets = [
        {
          id  = "processor"
          arn = module.processor.function_arn
        }
      ]
    }

    daily-report = {
      description         = "Trigger daily report Lambda"
      schedule_expression = "cron(0 8 * * ? *)"
      targets = [
        {
          id  = "report-lambda"
          arn = module.report.function_arn
        }
      ]
    }
  }

  tags = { Team = "backend" }
}
```

## Required Inputs

| Name | Type | Description |
|---|---|---|
| `project` | `string` | Project name prefix |
| `environment` | `string` | Deployment environment |
| `region` | `string` | AWS region |

## Optional Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `bus_name` | `string` | `"main"` | Short name for the custom event bus |
| `use_default_bus` | `bool` | `false` | Use the account's default event bus instead of creating one |
| `kms_key_arn` | `string` | `null` | KMS key ARN for event bus encryption |
| `rules` | `map(object)` | `{}` | Map of EventBridge rule configurations. Key is the rule short name |
| `allowed_publisher_arns` | `list(string)` | `[]` | IAM principal ARNs allowed to put events onto this bus |
| `tags` | `map(string)` | `{}` | Additional resource tags |

### Rule object schema

| Field | Type | Default | Description |
|---|---|---|---|
| `description` | `string` | `""` | Rule description |
| `schedule_expression` | `string` | `null` | Schedule: `rate(5 minutes)` or `cron(0 12 * * ? *)` |
| `event_pattern` | `string` | `null` | JSON event pattern string |
| `state` | `string` | `"ENABLED"` | Rule state |
| `targets` | `list(object)` | required | Target configurations |

### Target object schema

| Field | Type | Description |
|---|---|---|
| `id` | `string` | Unique target ID |
| `arn` | `string` | Target resource ARN |
| `role_arn` | `string` | IAM role ARN for EventBridge to invoke the target |
| `input` | `string` | Static JSON input to pass to target |
| `input_path` | `string` | JSONPath to extract from the event |
| `dead_letter_arn` | `string` | SQS DLQ ARN for failed invocations |
| `ecs_target` | `object` | ECS task configuration (Fargate launch) |

## Outputs

| Name | Description |
|---|---|
| `bus_arn` | Event bus ARN |
| `bus_name` | Event bus name |
| `rule_arns` | Map of rule name to ARN |
