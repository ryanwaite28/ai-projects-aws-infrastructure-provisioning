# API Gateway
output "api_id" {
  value       = aws_api_gateway_rest_api.this.id
  description = "REST API ID."
}

output "api_endpoint" {
  value       = "${aws_api_gateway_stage.this.invoke_url}/webhooks"
  description = "Full POST endpoint URL. Send webhook payloads to this URL."
}

output "stage_invoke_url" {
  value       = aws_api_gateway_stage.this.invoke_url
  description = "Stage base URL."
}

output "custom_domain_target" {
  value       = var.custom_domain_name != null ? aws_api_gateway_domain_name.this[0].regional_domain_name : null
  description = "Target DNS name for a Route 53 alias record on the custom domain."
}

output "api_key_value" {
  value       = var.api_key_required ? aws_api_gateway_api_key.this[0].value : null
  description = "API key value (only set when api_key_required = true). Store securely."
  sensitive   = true
}

# SQS
output "queue_url" {
  value       = module.sqs.queue_id
  description = "SQS queue URL."
}

output "queue_arn" {
  value       = module.sqs.queue_arn
  description = "SQS queue ARN."
}

output "queue_name" {
  value       = module.sqs.queue_name
  description = "SQS queue name."
}

output "dlq_url" {
  value       = module.sqs.dlq_id
  description = "Dead-letter queue URL."
}

output "dlq_arn" {
  value       = module.sqs.dlq_arn
  description = "Dead-letter queue ARN."
}

# Processor Lambda
output "processor_lambda_arn" {
  value       = module.processor_lambda.function_arn
  description = "Processor Lambda ARN. Reference this in deploy-webhook-ingestion.yml."
}

output "processor_lambda_name" {
  value       = module.processor_lambda.function_name
  description = "Processor Lambda function name. Use as function_name input in the deploy workflow."
}

output "processor_lambda_role_arn" {
  value       = module.processor_lambda.execution_role_arn
  description = "Processor Lambda execution role ARN."
}
