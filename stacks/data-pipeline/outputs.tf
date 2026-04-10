output "kinesis_stream_arn"  { value = module.kinesis.stream_arn }
output "firehose_stream_arn" { value = module.firehose.stream_arn }
output "s3_bucket_name"      { value = module.s3_destination.bucket_id }
output "transformer_lambda_arn" { value = var.enable_transformation ? module.transformer_lambda[0].function_arn : null }
