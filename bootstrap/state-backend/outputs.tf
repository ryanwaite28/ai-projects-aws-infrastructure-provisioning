output "bucket_name"       { value = aws_s3_bucket.state.id }
output "bucket_arn"        { value = aws_s3_bucket.state.arn }
output "lock_table_name"   { value = aws_dynamodb_table.lock.id }
output "lock_table_arn"    { value = aws_dynamodb_table.lock.arn }
