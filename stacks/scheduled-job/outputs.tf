output "lambda_arn"    { value = var.target_type == "lambda" ? module.lambda[0].function_arn : null }
output "rule_arns"     { value = module.eventbridge.rule_arns }
