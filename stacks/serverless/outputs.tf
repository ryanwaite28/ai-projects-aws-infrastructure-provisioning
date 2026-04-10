output "lambda_arn"        { value = module.lambda.function_arn }
output "lambda_name"       { value = module.lambda.function_name }
output "queue_url"         { value = module.sqs.queue_id }
output "dlq_url"           { value = module.sqs.dlq_id }
output "dynamodb_table"    { value = var.dynamodb_table_name != null ? module.dynamodb[0].table_name : null }
