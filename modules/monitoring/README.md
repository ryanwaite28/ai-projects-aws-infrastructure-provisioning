# Module: `monitoring`

Creates a shared CloudWatch monitoring foundation: an SNS alerts topic, CloudWatch alarms, log groups, and an optional dashboard.

Full name pattern: `{project}-{environment}-{region_short}-alerts`

## Usage

```hcl
module "monitoring" {
  source = "../../modules/monitoring"

  project     = "myapp"
  environment = "prod"
  region      = "us-east-1"

  alert_emails = ["oncall@example.com", "ops@example.com"]

  log_groups = {
    api = {
      name              = "/myapp/prod/api"
      retention_in_days = 30
    }
    worker = {
      name              = "/myapp/prod/worker"
      retention_in_days = 14
    }
  }

  alarms = {
    api-5xx = {
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "HTTPCode_Target_5XX_Count"
      namespace           = "AWS/ApplicationELB"
      period              = 60
      statistic           = "Sum"
      threshold           = 10
      alarm_description   = "API 5xx errors > 10 per minute"
      dimensions = {
        LoadBalancer = module.alb.alb_arn_suffix
      }
    }
  }

  dashboard_name = "myapp-prod"
  dashboard_body = file("dashboards/main.json")

  tags = { Team = "platform" }
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
| `alert_emails` | `list(string)` | `[]` | Email addresses to subscribe to the SNS alerts topic |
| `log_groups` | `map(object)` | `{}` | CloudWatch log groups to create |
| `alarms` | `map(object)` | `{}` | CloudWatch metric alarms |
| `dashboard_name` | `string` | `null` | Short name for the CloudWatch dashboard. Null = no dashboard |
| `dashboard_body` | `string` | `null` | CloudWatch dashboard JSON body |
| `tags` | `map(string)` | `{}` | Additional resource tags |

### Alarm object schema

| Field | Type | Default | Description |
|---|---|---|---|
| `comparison_operator` | `string` | required | e.g. `GreaterThanThreshold` |
| `evaluation_periods` | `number` | required | Number of periods to evaluate |
| `metric_name` | `string` | required | CloudWatch metric name |
| `namespace` | `string` | required | CloudWatch namespace |
| `period` | `number` | required | Period in seconds |
| `statistic` | `string` | required | `Sum`, `Average`, `Maximum`, etc. |
| `threshold` | `number` | required | Alarm threshold value |
| `alarm_description` | `string` | `""` | Human-readable description |
| `dimensions` | `map(string)` | `{}` | Metric dimensions |
| `treat_missing_data` | `string` | `"notBreaching"` | Missing data treatment |
| `alarm_actions` | `list(string)` | `[]` | SNS topic ARNs to notify on alarm |
| `ok_actions` | `list(string)` | `[]` | SNS topic ARNs to notify on OK |
| `datapoints_to_alarm` | `number` | `null` | Datapoints within evaluation period to trigger alarm |

## Outputs

| Name | Description |
|---|---|
| `alerts_topic_arn` | ARN of the SNS alerts topic |
| `alerts_topic_name` | Name of the SNS alerts topic |
| `alarm_arns` | Map of alarm name to ARN |
| `log_group_names` | Map of log group key to name |
