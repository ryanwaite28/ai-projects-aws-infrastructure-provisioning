# Basic data pipeline: Kinesis → Firehose → S3 with dynamic date partitioning.

module "events_pipeline" {
  source = "../../"

  project     = "myapp"
  environment = "dev"
  region      = "us-east-1"
  name        = "events"

  kinesis_on_demand       = true
  kinesis_retention_hours = 24

  dynamic_partitioning       = true
  buffering_size_mb          = 64
  buffering_interval_seconds = 300

  tags = { Team = "data" }
}

output "kinesis_stream_arn" { value = module.events_pipeline.kinesis_stream_arn }
output "firehose_stream_arn" { value = module.events_pipeline.firehose_stream_arn }
output "s3_bucket_name"      { value = module.events_pipeline.s3_bucket_name }
