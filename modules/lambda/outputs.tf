output "function_arn" {
  value       = aws_lambda_function.this.arn
  description = "ARN of the Lambda function."
}

output "function_name" {
  value       = aws_lambda_function.this.function_name
  description = "Name of the Lambda function."
}

output "function_invoke_arn" {
  value       = aws_lambda_function.this.invoke_arn
  description = "Invoke ARN (used in API Gateway integrations)."
}

output "execution_role_arn" {
  value       = local.create_role ? aws_iam_role.execution[0].arn : var.execution_role_arn
  description = "ARN of the Lambda execution role."
}

output "execution_role_name" {
  value       = local.create_role ? aws_iam_role.execution[0].name : null
  description = "Name of the auto-created execution role."
}

output "log_group_name" {
  value       = aws_cloudwatch_log_group.this.name
  description = "CloudWatch log group name."
}

output "qualified_arn" {
  value       = aws_lambda_function.this.qualified_arn
  description = "Qualified ARN including version."
}
