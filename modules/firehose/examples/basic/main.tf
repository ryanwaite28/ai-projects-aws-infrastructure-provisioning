# Firehose with Direct PUT source and S3 destination.
# Replace s3_bucket_arn with a real bucket ARN.

module "logs_firehose" {
  source = "../../"

  project      = "myapp"
  environment  = "dev"
  region       = "us-east-1"
  stream_name  = "app-logs"
  s3_bucket_arn = "arn:aws:s3:::myapp-dev-use1-logs"

  buffering_size_mb          = 5
  buffering_interval_seconds = 60
  s3_compression_format      = "GZIP"

  cloudwatch_logging_enabled = true

  tags = { Team = "platform" }
}

output "stream_arn"  { value = module.logs_firehose.stream_arn }
output "stream_name" { value = module.logs_firehose.stream_name }
