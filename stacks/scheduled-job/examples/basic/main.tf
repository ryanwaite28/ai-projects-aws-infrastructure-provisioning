module "daily_report" {
  source = "../../"

  project     = "myapp"
  environment = "dev"
  region      = "us-east-1"
  name        = "daily-report"

  target_type    = "lambda"
  lambda_runtime = "python3.12"
  lambda_handler = "report.run"
  lambda_timeout = 120

  # Set once the artifact bucket and package exist:
  # lambda_s3_bucket = "myapp-dev-use1-s3-lambda-artifacts"
  # lambda_s3_key    = "lambda/daily-report/latest.zip"

  schedules = [
    { expression = "cron(0 8 * * ? *)", description = "Run every day at 08:00 UTC" }
  ]

  environment_variables = {
    LOG_LEVEL = "DEBUG"
  }

  tags = { Team = "data" }
}

output "lambda_arn" { value = module.daily_report.lambda_arn }
output "rule_arns"  { value = module.daily_report.rule_arns }
