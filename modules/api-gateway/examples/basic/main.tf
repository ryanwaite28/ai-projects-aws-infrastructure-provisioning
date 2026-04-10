# HTTP API with a Lambda integration.
# Replace function_invoke_arn with your Lambda's invoke ARN.

module "api" {
  source = "../../"

  project     = "myapp"
  environment = "dev"
  region      = "us-east-1"
  api_name    = "public"
  api_type    = "HTTP"
  description = "Public HTTP API"

  cors_configuration = {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST", "OPTIONS"]
    allow_headers = ["Content-Type", "Authorization"]
  }

  routes = {
    "GET /items" = {
      integration_uri = "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:123456789012:function:myapp-dev-list-items/invocations"
    }
  }

  log_retention_days = 7

  tags = { Team = "backend" }
}

output "api_endpoint"    { value = module.api.api_endpoint }
output "stage_invoke_url" { value = module.api.stage_invoke_url }
