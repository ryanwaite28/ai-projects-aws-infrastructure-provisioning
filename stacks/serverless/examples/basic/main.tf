module "order_processor" {
  source = "../../"

  project     = "myapp"
  environment = "dev"
  region      = "us-east-1"
  name        = "order-processor"

  lambda_runtime     = "python3.12"
  lambda_handler     = "handler.process"
  lambda_memory_size = 256
  lambda_timeout     = 30

  # Set after first tf-apply once the S3 artifact bucket exists:
  # lambda_s3_bucket = "myapp-dev-use1-s3-lambda-artifacts"
  # lambda_s3_key    = "lambda/order-processor/latest.zip"

  dynamodb_table_name = "order-results"
  dynamodb_hash_key   = "order_id"

  lambda_environment_variables = {
    LOG_LEVEL = "DEBUG"
  }

  tags = { Team = "backend" }
}

output "lambda_arn"  { value = module.order_processor.lambda_arn }
output "queue_url"   { value = module.order_processor.queue_url }
