output "bus_arn" {
  value       = var.use_default_bus ? "arn:aws:events:${var.region}:*:event-bus/default" : aws_cloudwatch_event_bus.this[0].arn
  description = "Event bus ARN."
}

output "bus_name" {
  value       = local.bus_name
  description = "Event bus name."
}

output "rule_arns" {
  value       = { for k, v in aws_cloudwatch_event_rule.this : k => v.arn }
  description = "Map of rule name to ARN."
}
