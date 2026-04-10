module "monitoring" {
  source = "../../"

  project     = "myapp"
  environment = "dev"
  region      = "us-east-1"

  alert_emails = ["dev-oncall@example.com"]

  log_groups = {
    api = {
      name              = "/myapp/dev/api"
      retention_in_days = 7
    }
  }

  alarms = {
    high-error-rate = {
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "Errors"
      namespace           = "AWS/Lambda"
      period              = 60
      statistic           = "Sum"
      threshold           = 5
      alarm_description   = "Lambda error count > 5 per minute"
      dimensions = {
        FunctionName = "myapp-dev-use1-fn-api"
      }
    }
  }

  tags = { Team = "platform" }
}

output "alerts_topic_arn" { value = module.monitoring.alerts_topic_arn }
