output "api_id" {
  value       = var.api_type == "HTTP" ? aws_apigatewayv2_api.this[0].id : null
  description = "API Gateway ID."
}

output "api_endpoint" {
  value       = var.api_type == "HTTP" ? aws_apigatewayv2_api.this[0].api_endpoint : null
  description = "Default API endpoint URL."
}

output "stage_invoke_url" {
  value       = var.api_type == "HTTP" ? aws_apigatewayv2_stage.this[0].invoke_url : null
  description = "Stage invoke URL."
}

output "stage_arn" {
  value       = var.api_type == "HTTP" ? aws_apigatewayv2_stage.this[0].arn : null
  description = "Stage ARN."
}

output "custom_domain_name" {
  value       = var.custom_domain_name != null ? aws_apigatewayv2_domain_name.this[0].domain_name : null
  description = "Custom domain name."
}

output "custom_domain_target" {
  value       = var.custom_domain_name != null ? aws_apigatewayv2_domain_name.this[0].domain_name_configuration[0].target_domain_name : null
  description = "Target DNS name for Route 53 alias."
}

output "custom_domain_zone_id" {
  value       = var.custom_domain_name != null ? aws_apigatewayv2_domain_name.this[0].domain_name_configuration[0].hosted_zone_id : null
  description = "Hosted zone ID for Route 53 alias."
}

output "vpc_link_id" {
  value       = local.use_vpc_link ? aws_apigatewayv2_vpc_link.this[0].id : null
  description = "VPC Link ID."
}
