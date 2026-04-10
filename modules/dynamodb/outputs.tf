output "table_name" {
  value       = aws_dynamodb_table.this.name
  description = "DynamoDB table name."
}

output "table_arn" {
  value       = aws_dynamodb_table.this.arn
  description = "DynamoDB table ARN."
}

output "table_id" {
  value       = aws_dynamodb_table.this.id
  description = "DynamoDB table ID."
}

output "stream_arn" {
  value       = aws_dynamodb_table.this.stream_arn
  description = "DynamoDB Streams ARN (null if stream not enabled)."
}

output "stream_label" {
  value       = aws_dynamodb_table.this.stream_label
  description = "DynamoDB stream timestamp label."
}
