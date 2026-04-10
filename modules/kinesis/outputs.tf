output "stream_arn" {
  value       = aws_kinesis_stream.this.arn
  description = "Kinesis stream ARN."
}

output "stream_name" {
  value       = aws_kinesis_stream.this.name
  description = "Kinesis stream name."
}

output "consumer_arns" {
  value       = { for k, v in aws_kinesis_stream_consumer.this : k => v.arn }
  description = "Map of consumer name to ARN."
}
