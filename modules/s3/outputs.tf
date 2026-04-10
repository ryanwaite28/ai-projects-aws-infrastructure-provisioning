output "bucket_id" {
  description = "Name/ID of the S3 bucket."
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "ARN of the S3 bucket."
  value       = aws_s3_bucket.this.arn
}

output "bucket_domain_name" {
  description = "Bucket-regional domain name (used as a CloudFront origin)."
  value       = aws_s3_bucket.this.bucket_regional_domain_name
}

output "bucket_regional_domain_name" {
  description = "Regional domain name of the bucket."
  value       = aws_s3_bucket.this.bucket_regional_domain_name
}

output "replication_role_arn" {
  description = "ARN of the replication IAM role. Null if replication is disabled."
  value       = var.replication_enabled ? aws_iam_role.replication[0].arn : null
}
