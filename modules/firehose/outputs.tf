output "stream_arn" {
  value       = aws_kinesis_firehose_delivery_stream.this.arn
  description = "Firehose delivery stream ARN."
}

output "stream_name" {
  value       = aws_kinesis_firehose_delivery_stream.this.name
  description = "Firehose stream name."
}

output "delivery_role_arn" {
  value       = aws_iam_role.firehose.arn
  description = "IAM role ARN used by Firehose for delivery."
}
