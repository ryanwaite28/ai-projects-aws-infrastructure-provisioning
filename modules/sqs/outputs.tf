output "queue_id" {
  value       = aws_sqs_queue.this.id
  description = "URL of the SQS queue."
}

output "queue_arn" {
  value       = aws_sqs_queue.this.arn
  description = "ARN of the SQS queue."
}

output "queue_name" {
  value       = aws_sqs_queue.this.name
  description = "Name of the SQS queue."
}

output "dlq_id" {
  value       = var.dlq_enabled ? aws_sqs_queue.dlq[0].id : null
  description = "URL of the DLQ."
}

output "dlq_arn" {
  value       = var.dlq_enabled ? aws_sqs_queue.dlq[0].arn : null
  description = "ARN of the DLQ."
}
