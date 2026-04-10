output "alb_id" {
  description = "ID of the ALB."
  value       = aws_lb.this.id
}

output "alb_arn" {
  description = "ARN of the ALB."
  value       = aws_lb.this.arn
}

output "alb_dns_name" {
  description = "DNS name of the ALB (use as a Route 53 alias target)."
  value       = aws_lb.this.dns_name
}

output "alb_zone_id" {
  description = "Hosted zone ID of the ALB (used for Route 53 alias records)."
  value       = aws_lb.this.zone_id
}

output "https_listener_arn" {
  description = "ARN of the HTTPS:443 listener."
  value       = var.certificate_arn != null ? aws_lb_listener.https[0].arn : null
}

output "http_listener_arn" {
  description = "ARN of the HTTP:80 listener (redirect)."
  value       = var.enable_http_to_https_redirect && var.certificate_arn != null ? aws_lb_listener.http_redirect[0].arn : null
}

output "target_group_arns" {
  description = "Map of target group key to ARN."
  value       = { for k, v in aws_lb_target_group.this : k => v.arn }
}

output "target_group_names" {
  description = "Map of target group key to name."
  value       = { for k, v in aws_lb_target_group.this : k => v.name }
}
