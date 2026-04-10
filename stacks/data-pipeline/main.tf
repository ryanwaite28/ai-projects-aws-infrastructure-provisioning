##
## Stack: data-pipeline
## Kinesis Streams → Firehose → S3 with optional Lambda transformation.
##

terraform {
  required_version = ">= 1.7.0"
  required_providers { aws = { source = "hashicorp/aws", version = ">= 5.0" } }
}

provider "aws" { region = var.region }

module "s3_destination" {
  source        = "../../modules/s3"
  project       = var.project
  environment   = var.environment
  region        = var.region
  bucket_suffix = "${var.name}-pipeline-data"
  kms_key_arn   = var.kms_key_arn
  lifecycle_rules = [{
    id      = "expire-old-data"
    enabled = true
    transition_days = 30
    transition_storage_class = "STANDARD_IA"
    glacier_transition_days = 90
  }]
  tags = var.tags
}

module "kinesis" {
  source      = "../../modules/kinesis"
  project     = var.project
  environment = var.environment
  region      = var.region
  stream_name = var.name
  on_demand   = var.kinesis_on_demand
  shard_count = var.kinesis_shard_count
  retention_period_hours = var.kinesis_retention_hours
  kms_key_arn = var.kms_key_arn
  tags        = var.tags
}

module "transformer_lambda" {
  count         = var.enable_transformation ? 1 : 0
  source        = "../../modules/lambda"
  project       = var.project
  environment   = var.environment
  region        = var.region
  function_name = "${var.name}-transformer"
  runtime       = var.lambda_runtime
  handler       = var.lambda_handler
  s3_bucket     = var.lambda_s3_bucket
  s3_key        = var.lambda_s3_key
  memory_size   = 1024
  timeout       = 60
  kms_key_arn   = var.kms_key_arn
  tags          = var.tags
}

module "firehose" {
  source        = "../../modules/firehose"
  project       = var.project
  environment   = var.environment
  region        = var.region
  stream_name   = var.name
  source_kinesis_stream_arn     = module.kinesis.stream_arn
  s3_bucket_arn                 = module.s3_destination.bucket_arn
  dynamic_partitioning_enabled  = var.dynamic_partitioning
  transformation_lambda_arn     = var.enable_transformation ? module.transformer_lambda[0].function_arn : null
  kms_key_arn                   = var.kms_key_arn
  buffering_size_mb             = var.buffering_size_mb
  buffering_interval_seconds    = var.buffering_interval_seconds
  tags                          = var.tags
}
