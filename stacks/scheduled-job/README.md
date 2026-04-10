# Stack: `scheduled-job`

Deploys a scheduled job triggered by EventBridge Scheduler. Supports either a **Lambda** target (default, serverless) or an **ECS** target (for jobs requiring more memory/CPU or longer runtimes).

## What it creates

- EventBridge Scheduler rule(s) with schedule expression(s)
- **Lambda target:** Lambda function + execution role + log group
- **ECS target:** IAM scheduler role with `ecs:RunTask` + `iam:PassRole` permissions
- Supports multiple schedules per job (e.g. hourly + daily)

## Usage

### Lambda-based scheduled job

```hcl
module "daily_report" {
  source = "../../stacks/scheduled-job"

  project     = "myapp"
  environment = "prod"
  region      = "us-east-1"
  name        = "daily-report"

  target_type    = "lambda"
  lambda_runtime = "python3.12"
  lambda_handler = "report.run"
  lambda_s3_bucket = "myapp-prod-use1-s3-lambda-artifacts"
  lambda_s3_key    = "lambda/daily-report/latest.zip"
  lambda_timeout   = 300

  schedules = [
    { expression = "cron(0 8 * * ? *)", description = "Run every day at 08:00 UTC" }
  ]

  environment_variables = {
    REPORT_BUCKET = "myapp-prod-reports"
  }

  tags = { Team = "data" }
}
```

### ECS-based scheduled job

```hcl
module "heavy_etl" {
  source = "../../stacks/scheduled-job"
  # ...
  target_type             = "ecs"
  ecs_cluster_arn         = module.platform.ecs_cluster_arn
  ecs_task_definition_arn = aws_ecs_task_definition.etl.arn
  ecs_subnet_ids          = module.platform.private_subnet_ids
  ecs_security_group_ids  = [module.platform.sg_ecs_tasks_id]

  schedules = [
    { expression = "rate(1 hour)", description = "Hourly ETL" }
  ]
}
```

## Required Inputs

| Name | Type | Description |
|---|---|---|
| `project` | `string` | Project name prefix |
| `environment` | `string` | Deployment environment |
| `region` | `string` | AWS region |
| `name` | `string` | Short job name |
| `schedules` | `list(object)` | Schedule expressions (`rate()` or `cron()`) |

## Optional Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `target_type` | `string` | `"lambda"` | `lambda` or `ecs` |
| `lambda_runtime` | `string` | `"python3.12"` | Lambda runtime |
| `lambda_handler` | `string` | `"job.run"` | Lambda handler |
| `lambda_s3_bucket` | `string` | `null` | S3 bucket for Lambda package |
| `lambda_s3_key` | `string` | `null` | S3 key for Lambda package |
| `lambda_memory_size` | `number` | `512` | Lambda memory in MiB |
| `lambda_timeout` | `number` | `300` | Lambda timeout in seconds |
| `environment_variables` | `map(string)` | `{}` | Lambda environment variables |
| `vpc_config` | `object` | `null` | `{ subnet_ids, security_group_ids }` for VPC Lambda |
| `ecs_cluster_arn` | `string` | `null` | ECS cluster ARN (ECS target only) |
| `ecs_task_definition_arn` | `string` | `null` | ECS task definition ARN (ECS target only) |
| `ecs_subnet_ids` | `list(string)` | `[]` | Subnet IDs for ECS task launch |
| `ecs_security_group_ids` | `list(string)` | `[]` | Security group IDs for ECS task |
| `tags` | `map(string)` | `{}` | Additional resource tags |

## Outputs

| Name | Description |
|---|---|
| `lambda_arn` | Lambda ARN (null for ECS target) |
| `rule_arns` | Map of schedule name to EventBridge rule ARN |
