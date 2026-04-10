##
## Stack: async-worker
## SQS work queue + ECS Fargate worker service with queue-depth autoscaling.
##

terraform {
  required_version = ">= 1.7.0"
  required_providers { aws = { source = "hashicorp/aws", version = ">= 5.0" } }
}

provider "aws" { region = var.region }

module "sqs" {
  source      = "../../modules/sqs"
  project     = var.project
  environment = var.environment
  region      = var.region
  queue_name  = "${var.name}-work"
  dlq_enabled = true
  visibility_timeout_seconds = var.visibility_timeout_seconds
  kms_key_arn = var.kms_key_arn
  tags        = var.tags
}

module "ecr" {
  source          = "../../modules/ecr"
  project         = var.project
  environment     = var.environment
  region          = var.region
  repository_name = var.name
  tags            = var.tags
}

module "task_role" {
  source      = "../../modules/iam"
  project     = var.project
  environment = var.environment
  region      = var.region
  role_name   = "${var.name}-worker-task"
  trusted_service_principals = ["ecs-tasks.amazonaws.com"]
  inline_policies = {
    sqs-consume = jsonencode({
      Version = "2012-10-17"
      Statement = [{ Effect = "Allow", Action = ["sqs:ReceiveMessage","sqs:DeleteMessage","sqs:GetQueueAttributes"], Resource = module.sqs.queue_arn }]
    })
  }
  tags = var.tags
}

module "ecs_worker" {
  source      = "../../modules/ecs"
  project     = var.project
  environment = var.environment
  region      = var.region
  cluster_arn             = var.ecs_cluster_arn
  service_name            = var.name
  task_cpu                = var.task_cpu
  task_memory             = var.task_memory
  task_execution_role_arn = var.task_execution_role_arn
  task_role_arn           = module.task_role.role_arn
  desired_count           = var.desired_count
  autoscaling_min_capacity = var.autoscaling_min
  autoscaling_max_capacity = var.autoscaling_max
  autoscaling_enabled     = true
  subnet_ids              = var.private_subnet_ids
  security_group_ids      = var.security_group_ids
  vpc_id                  = var.vpc_id
  container_definitions = jsonencode([{
    name  = "worker"
    image = var.container_image
    environment = concat(
      [{ name = "QUEUE_URL", value = module.sqs.queue_id }],
      [for k, v in var.environment_variables : { name = k, value = v }]
    )
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = "/ecs/${var.project}-${var.environment}-${var.name}-worker"
        awslogs-region        = var.region
        awslogs-stream-prefix = "ecs"
      }
    }
  }])
  tags = var.tags
}

# Scale worker tasks on queue depth
resource "aws_appautoscaling_policy" "queue_depth" {
  name               = "${var.project}-${var.environment}-${var.name}-queue-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = "service/${split("/", var.ecs_cluster_arn)[1]}/${module.ecs_worker.service_name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  target_tracking_scaling_policy_configuration {
    customized_metric_specification {
      metric_name = "ApproximateNumberOfMessagesVisible"
      namespace   = "AWS/SQS"
      dimensions  { name = "QueueName", value = module.sqs.queue_name }
      statistic   = "Average"
      unit        = "Count"
    }
    target_value       = var.target_messages_per_task
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }

  depends_on = [module.ecs_worker]
}
