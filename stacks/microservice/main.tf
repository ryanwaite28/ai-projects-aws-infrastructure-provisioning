##
## Stack: microservice
## Deploys an internal microservice on the shared ECS cluster.
## Registers a path-based listener rule on the PRIVATE ALB only.
##

terraform {
  required_version = ">= 1.7.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = ">= 5.0" }
  }
}

provider "aws" { region = var.region }

locals {
  use_ssm = var.ssm_prefix != null

  vpc_id                   = local.use_ssm ? data.aws_ssm_parameter.vpc_id[0].value : var.vpc_id
  private_subnet_ids       = local.use_ssm ? split(",", data.aws_ssm_parameter.private_subnet_ids[0].value) : var.private_subnet_ids
  ecs_cluster_arn          = local.use_ssm ? data.aws_ssm_parameter.ecs_cluster_arn[0].value : var.ecs_cluster_arn
  private_alb_listener_arn = local.use_ssm ? data.aws_ssm_parameter.private_alb_listener_arn[0].value : var.private_alb_listener_arn
  sg_ecs_tasks_id          = local.use_ssm ? data.aws_ssm_parameter.sg_ecs_tasks_id[0].value : var.sg_ecs_tasks_id
  task_execution_role_arn  = local.use_ssm ? data.aws_ssm_parameter.task_execution_role_arn[0].value : var.task_execution_role_arn
}

data "aws_ssm_parameter" "vpc_id" {
  count = local.use_ssm ? 1 : 0
  name  = "${var.ssm_prefix}/vpc_id"
}

data "aws_ssm_parameter" "private_subnet_ids" {
  count = local.use_ssm ? 1 : 0
  name  = "${var.ssm_prefix}/private_subnet_ids"
}

data "aws_ssm_parameter" "ecs_cluster_arn" {
  count = local.use_ssm ? 1 : 0
  name  = "${var.ssm_prefix}/ecs_cluster_arn"
}

data "aws_ssm_parameter" "private_alb_listener_arn" {
  count = local.use_ssm ? 1 : 0
  name  = "${var.ssm_prefix}/private_alb_listener_arn"
}

data "aws_ssm_parameter" "sg_ecs_tasks_id" {
  count = local.use_ssm ? 1 : 0
  name  = "${var.ssm_prefix}/sg_ecs_tasks_id"
}

data "aws_ssm_parameter" "task_execution_role_arn" {
  count = local.use_ssm ? 1 : 0
  name  = "${var.ssm_prefix}/ecs_task_execution_role_arn"
}

module "ecr" {
  source          = "../../modules/ecr"
  project         = var.project
  environment     = var.environment
  region          = var.region
  repository_name = var.service_name
  tags            = var.tags
}

module "task_role" {
  source      = "../../modules/iam"
  project     = var.project
  environment = var.environment
  region      = var.region
  role_name   = "${var.service_name}-task"
  trusted_service_principals = ["ecs-tasks.amazonaws.com"]
  inline_policies = length(var.secret_arns) > 0 ? {
    read-secrets = jsonencode({
      Version = "2012-10-17"
      Statement = [{ Effect = "Allow", Action = ["secretsmanager:GetSecretValue"], Resource = var.secret_arns }]
    })
  } : {}
  tags = var.tags
}

resource "aws_lb_target_group" "this" {
  name         = "${var.project}-${var.environment}-tg-${var.service_name}"
  port         = var.container_port
  protocol     = "HTTP"
  vpc_id       = local.vpc_id
  target_type  = "ip"
  deregistration_delay = 30

  health_check {
    path                = var.health_check_path
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
    matcher             = "200"
  }

  tags = merge(var.tags, { Name = "${var.project}-${var.environment}-tg-${var.service_name}" })
  lifecycle { create_before_destroy = true }
}

resource "aws_lb_listener_rule" "this" {
  listener_arn = local.private_alb_listener_arn
  priority     = var.listener_priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }

  condition {
    path_pattern {
      values = [var.path_pattern]
    }
  }
}

module "ecs_service" {
  source      = "../../modules/ecs"
  project     = var.project
  environment = var.environment
  region      = var.region

  cluster_arn             = local.ecs_cluster_arn
  service_name            = var.service_name
  task_cpu                = var.task_cpu
  task_memory             = var.task_memory
  task_execution_role_arn = local.task_execution_role_arn
  task_role_arn           = module.task_role.role_arn
  desired_count           = var.desired_count
  autoscaling_min_capacity = var.autoscaling_min
  autoscaling_max_capacity = var.autoscaling_max
  autoscaling_enabled     = true
  subnet_ids              = local.private_subnet_ids
  security_group_ids      = [local.sg_ecs_tasks_id]
  vpc_id                  = local.vpc_id
  target_group_arn        = aws_lb_target_group.this.arn
  container_name          = "app"
  container_port          = var.container_port

  container_definitions = jsonencode([{
    name  = "app"
    image = var.container_image
    portMappings = [{ containerPort = var.container_port, protocol = "tcp" }]
    environment = [for k, v in var.environment_variables : { name = k, value = v }]
    secrets     = [for arn in var.secret_arns : { name = basename(arn), valueFrom = arn }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = "/ecs/${var.project}-${var.environment}-${var.service_name}"
        awslogs-region        = var.region
        awslogs-stream-prefix = "ecs"
      }
    }
  }])

  tags = var.tags
}
