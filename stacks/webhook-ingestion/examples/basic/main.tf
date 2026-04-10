# Basic webhook ingestion pipeline: API Gateway → SQS → Lambda processor.
# Demonstrates Stripe webhook receiver. Substitute real S3 bucket/key for the processor package.

module "stripe_webhooks" {
  source = "../../"

  project     = "myapp"
  environment = "dev"
  region      = "us-east-1"
  name        = "stripe"

  # API Gateway
  stage_name             = "v1"
  throttling_rate_limit  = 100
  throttling_burst_limit = 200
  api_key_required       = true

  # SQS — visibility timeout must be >= 6× processor_timeout
  sqs_visibility_timeout_seconds = 360
  dlq_max_receive_count          = 3

  # Processor Lambda
  processor_runtime     = "python3.12"
  processor_handler     = "handler.process"
  processor_s3_bucket   = "myapp-dev-use1-s3-lambda-artifacts"
  processor_s3_key      = "lambda/stripe-processor/latest.zip"
  processor_timeout     = 60
  processor_memory_size = 512

  processor_environment_variables = {
    ENVIRONMENT = "dev"
  }

  tags = { Team = "payments" }
}

output "api_endpoint"            { value = module.stripe_webhooks.api_endpoint }
output "processor_lambda_name"   { value = module.stripe_webhooks.processor_lambda_name }
output "dlq_url"                 { value = module.stripe_webhooks.dlq_url }
