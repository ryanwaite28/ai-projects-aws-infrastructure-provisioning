##
## Module: ecs
## Creates an ECS cluster and/or a Fargate service with task definition,
## auto-scaling, and CloudWatch logging.
##

locals {
  region_short = {
    "us-east-1" = "use1", "us-east-2" = "use2", "us-west-1" = "usw1", "us-west-2" = "usw2",
    "eu-west-1" = "euw1", "eu-west-2" = "euw2", "eu-central-1" = "euc1",
    "ap-southeast-1" = "apse1", "ap-southeast-2" = "apse2", "ap-northeast-1" = "apne1"
  }
  rs          = lookup(local.region_short, var.region, replace(var.region, "-", ""))
  name_prefix = "${var.project}-${var.environment}-${local.rs}"

  create_cluster = var.cluster_arn == null
  effective_cluster_arn = local.create_cluster ? (
    var.cluster_only ? aws_ecs_cluster.this[0].arn : aws_ecs_cluster.this[0].arn
  ) : var.cluster_arn

  default_tags = merge({
    Project     = var.project
    Environment = var.environment
    Region      = var.region
    ManagedBy   = "terraform"
  }, var.tags)
}

# ── Cluster ───────────────────────────────────────────────────────────────────

resource "aws_ecs_cluster" "this" {
  count = local.create_cluster ? 1 : 0
  name  = "${local.name_prefix}-ecs-${var.cluster_name}"

  setting {
    name  = "containerInsights"
    value = var.container_insights_enabled ? "enabled" : "disabled"
  }

  configuration {
    execute_command_configuration {
      logging = "DEFAULT"
    }
  }

  tags = merge(local.default_tags, { Name = "${local.name_prefix}-ecs-${var.cluster_name}" })
}

resource "aws_ecs_cluster_capacity_providers" "this" {
  count              = local.create_cluster ? 1 : 0
  cluster_name       = aws_ecs_cluster.this[0].name
  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 1
    base              = 1
  }
}

# ── CloudWatch Log Group ──────────────────────────────────────────────────────

resource "aws_cloudwatch_log_group" "service" {
  count             = var.cluster_only ? 0 : 1
  name              = "/ecs/${local.name_prefix}-${var.service_name}"
  retention_in_days = var.log_retention_days
  tags              = local.default_tags
}

# ── Task Definition ───────────────────────────────────────────────────────────

resource "aws_ecs_task_definition" "this" {
  count                    = var.cluster_only ? 0 : 1
  family                   = "${local.name_prefix}-${var.service_name}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = var.task_execution_role_arn
  task_role_arn            = var.task_role_arn
  container_definitions    = var.container_definitions

  dynamic "volume" {
    for_each = var.volumes
    content {
      name      = volume.value.name
      host_path = volume.value.host_path

      dynamic "efs_volume_configuration" {
        for_each = volume.value.efs_volume_configuration != null ? [volume.value.efs_volume_configuration] : []
        content {
          file_system_id          = efs_volume_configuration.value.file_system_id
          root_directory          = efs_volume_configuration.value.root_directory
          transit_encryption      = efs_volume_configuration.value.iam_auth ? "ENABLED" : "DISABLED"
          transit_encryption_port = efs_volume_configuration.value.iam_auth ? 2049 : null

          dynamic "authorization_config" {
            for_each = efs_volume_configuration.value.access_point_id != null ? [1] : []
            content {
              access_point_id = efs_volume_configuration.value.access_point_id
              iam             = efs_volume_configuration.value.iam_auth ? "ENABLED" : "DISABLED"
            }
          }
        }
      }
    }
  }

  tags = merge(local.default_tags, { Name = "${local.name_prefix}-${var.service_name}-task" })
}

# ── Service ───────────────────────────────────────────────────────────────────

resource "aws_security_group" "service" {
  count       = var.cluster_only ? 0 : 1
  name        = "${local.name_prefix}-sg-ecs-${var.service_name}"
  description = "Security group for ECS service ${var.service_name}"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = merge(local.default_tags, { Name = "${local.name_prefix}-sg-ecs-${var.service_name}" })
}

resource "aws_ecs_service" "this" {
  count                              = var.cluster_only ? 0 : 1
  name                               = "${local.name_prefix}-svc-${var.service_name}"
  cluster                            = local.effective_cluster_arn
  task_definition                    = aws_ecs_task_definition.this[0].arn
  desired_count                      = var.desired_count
  launch_type                        = "FARGATE"
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  deployment_maximum_percent         = var.deployment_maximum_percent
  enable_execute_command             = var.execute_command_enabled

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = concat([aws_security_group.service[0].id], var.security_group_ids)
    assign_public_ip = var.assign_public_ip
  }

  dynamic "load_balancer" {
    for_each = var.target_group_arn != null ? [1] : []
    content {
      target_group_arn = var.target_group_arn
      container_name   = var.container_name
      container_port   = var.container_port
    }
  }

  deployment_circuit_breaker {
    enable   = var.enable_deployment_circuit_breaker
    rollback = var.enable_deployment_circuit_breaker
  }

  tags = merge(local.default_tags, { Name = "${local.name_prefix}-svc-${var.service_name}" })

  lifecycle {
    ignore_changes = [desired_count, task_definition]
  }
}

# ── Auto Scaling ──────────────────────────────────────────────────────────────

resource "aws_appautoscaling_target" "this" {
  count              = var.cluster_only || !var.autoscaling_enabled ? 0 : 1
  max_capacity       = var.autoscaling_max_capacity
  min_capacity       = var.autoscaling_min_capacity
  resource_id        = "service/${split("/", local.effective_cluster_arn)[1]}/${aws_ecs_service.this[0].name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "cpu" {
  count              = var.cluster_only || !var.autoscaling_enabled ? 0 : 1
  name               = "${local.name_prefix}-${var.service_name}-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.this[0].resource_id
  scalable_dimension = aws_appautoscaling_target.this[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.this[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = var.autoscaling_cpu_target
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

resource "aws_appautoscaling_policy" "memory" {
  count              = var.cluster_only || !var.autoscaling_enabled ? 0 : 1
  name               = "${local.name_prefix}-${var.service_name}-memory-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.this[0].resource_id
  scalable_dimension = aws_appautoscaling_target.this[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.this[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value       = var.autoscaling_memory_target
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}
