##
## Stack: scheduled-job
## EventBridge Scheduler → Lambda or ECS RunTask.
##

terraform {
  required_version = ">= 1.7.0"
  required_providers { aws = { source = "hashicorp/aws", version = ">= 5.0" } }
}

provider "aws" { region = var.region }

module "lambda" {
  count         = var.target_type == "lambda" ? 1 : 0
  source        = "../../modules/lambda"
  project       = var.project
  environment   = var.environment
  region        = var.region
  function_name = var.name
  runtime       = var.lambda_runtime
  handler       = var.lambda_handler
  s3_bucket     = var.lambda_s3_bucket
  s3_key        = var.lambda_s3_key
  memory_size   = var.lambda_memory_size
  timeout       = var.lambda_timeout
  environment_variables = var.environment_variables
  vpc_config    = var.vpc_config
  tags          = var.tags
}

module "eventbridge" {
  source      = "../../modules/eventbridge"
  project     = var.project
  environment = var.environment
  region      = var.region
  bus_name    = var.name
  use_default_bus = true
  rules = { for idx, schedule in var.schedules :
    "${var.name}-schedule-${idx}" => {
      schedule_expression = schedule.expression
      description         = lookup(schedule, "description", "")
      targets = var.target_type == "lambda" ? [{
        id  = "lambda-target"
        arn = module.lambda[0].function_arn
      }] : [{
        id       = "ecs-target"
        arn      = var.ecs_cluster_arn
        role_arn = aws_iam_role.scheduler[0].arn
        ecs_target = {
          task_definition_arn = var.ecs_task_definition_arn
          cluster_arn         = var.ecs_cluster_arn
          subnet_ids          = var.ecs_subnet_ids
          security_group_ids  = var.ecs_security_group_ids
        }
      }]
    }
  }
  tags = var.tags
}

resource "aws_lambda_permission" "scheduler" {
  count         = var.target_type == "lambda" ? 1 : 0
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda[0].function_name
  principal     = "scheduler.amazonaws.com"
}

resource "aws_iam_role" "scheduler" {
  count = var.target_type == "ecs" ? 1 : 0
  name  = "${var.project}-${var.environment}-role-scheduler-${var.name}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Effect = "Allow", Action = "sts:AssumeRole", Principal = { Service = "scheduler.amazonaws.com" } }]
  })
}

resource "aws_iam_role_policy" "scheduler_ecs" {
  count = var.target_type == "ecs" ? 1 : 0
  role  = aws_iam_role.scheduler[0].id
  name  = "run-task"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      { Effect = "Allow", Action = ["ecs:RunTask"], Resource = var.ecs_task_definition_arn },
      # iam:PassRole on * is required: EventBridge Scheduler must pass both the task execution
      # role and the task role to ECS at runtime. Those ARNs are not known until apply time,
      # so wildcard scope is necessary here. Scope is limited by the permission boundary.
      { Effect = "Allow", Action = ["iam:PassRole"], Resource = "*" }
    ]
  })
}
