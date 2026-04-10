output "alerts_topic_arn" {
  value       = aws_sns_topic.alerts.arn
  description = "ARN of the SNS alerts topic."
}

output "alerts_topic_name" {
  value       = aws_sns_topic.alerts.name
  description = "Name of the SNS alerts topic."
}

output "alarm_arns" {
  value       = { for k, v in aws_cloudwatch_metric_alarm.this : k => v.arn }
  description = "Map of alarm name to ARN."
}

output "log_group_names" {
  value       = { for k, v in aws_cloudwatch_log_group.this : k => v.name }
  description = "Map of log group key to name."
}
