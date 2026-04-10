module "processor" {
  source = "../../"

  project       = "myapp"
  environment   = "dev"
  region        = "us-east-1"
  function_name = "order-processor"
  description   = "Processes order events from SQS"
  runtime       = "python3.12"
  handler       = "handler.process"

  # Deploy from S3 (recommended for CI pipelines)
  s3_bucket = "myapp-dev-use1-s3-lambda-artifacts"
  s3_key    = "lambda/order-processor/latest.zip"

  memory_size = 256
  timeout     = 30

  environment_variables = {
    LOG_LEVEL = "INFO"
  }

  log_retention_days = 7

  tags = { Team = "backend" }
}

output "function_arn"  { value = module.processor.function_arn }
output "function_name" { value = module.processor.function_name }
