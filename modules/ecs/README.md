# Module: `ecs`

Creates an ECS Fargate cluster and/or service with task definition, CloudWatch log group, auto-scaling, optional ALB integration, EFS volume support, and deployment circuit breaker.

Full name pattern: `{project}-{environment}-{region_short}-ecs-{cluster_name}`

## Usage

### Full cluster + service

```hcl
module "api_service" {
  source = "../../modules/ecs"

  project      = "myapp"
  environment  = "prod"
  region       = "us-east-1"
  cluster_name = "main"
  service_name = "api"

  vpc_id             = module.network.vpc_id
  subnet_ids         = module.network.private_subnet_ids
  security_group_ids = [aws_security_group.api.id]

  task_cpu    = 512
  task_memory = 1024

  task_execution_role_arn = module.execution_role.role_arn
  task_role_arn           = module.task_role.role_arn

  container_definitions = jsonencode([
    {
      name      = "app"
      image     = "${module.ecr.repository_url}:latest"
      portMappings = [{ containerPort = 8080 }]
      environment = [
        { name = "PORT", value = "8080" }
      ]
      secrets = [
        { name = "DB_PASSWORD", valueFrom = module.db_secret.secret_arn }
      ]
    }
  ])

  target_group_arn = module.alb.target_group_arns["api"]
  container_name   = "app"
  container_port   = 8080

  autoscaling_enabled      = true
  autoscaling_min_capacity = 2
  autoscaling_max_capacity = 20
  autoscaling_cpu_target   = 70

  tags = { Team = "backend" }
}
```

### Cluster only (for stacks/platform)

```hcl
module "ecs_cluster" {
  source = "../../modules/ecs"
  # ...
  cluster_only = true
}
```

### Deploy service into existing cluster

```hcl
module "worker" {
  source = "../../modules/ecs"
  # ...
  cluster_arn  = module.ecs_cluster.cluster_arn   # skip cluster creation
  service_name = "worker"
}
```

## Required Inputs

| Name | Type | Description |
|---|---|---|
| `project` | `string` | Project name prefix |
| `environment` | `string` | Deployment environment |
| `region` | `string` | AWS region |

## Optional Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `cluster_name` | `string` | `"main"` | Short cluster name |
| `cluster_only` | `bool` | `false` | Create cluster only, skip service/task resources |
| `container_insights_enabled` | `bool` | `true` | Enable CloudWatch Container Insights |
| `execute_command_enabled` | `bool` | `true` | Enable ECS Exec for interactive debugging |
| `service_name` | `string` | `null` | Short service name (required when `cluster_only = false`) |
| `cluster_arn` | `string` | `null` | Existing cluster ARN. When set, skips cluster creation |
| `desired_count` | `number` | `2` | Desired running task count |
| `deployment_minimum_healthy_percent` | `number` | `100` | Minimum healthy % during deployments |
| `deployment_maximum_percent` | `number` | `200` | Maximum % of tasks during rolling deployments |
| `enable_deployment_circuit_breaker` | `bool` | `true` | Enable circuit breaker with auto-rollback |
| `vpc_id` | `string` | `null` | VPC ID for service security group |
| `subnet_ids` | `list(string)` | `[]` | Subnet IDs for ECS tasks |
| `security_group_ids` | `list(string)` | `[]` | Additional security group IDs |
| `assign_public_ip` | `bool` | `false` | Assign public IP to tasks |
| `task_cpu` | `number` | `512` | CPU units (256, 512, 1024, 2048, 4096) |
| `task_memory` | `number` | `1024` | Memory in MiB |
| `task_execution_role_arn` | `string` | `null` | Task execution role (ECR pull, Secrets, Logs) |
| `task_role_arn` | `string` | `null` | Task role (application AWS API access) |
| `container_definitions` | `string` | `"[]"` | JSON-encoded container definitions |
| `volumes` | `list(object)` | `[]` | Volume configurations (EFS, host path) |
| `target_group_arn` | `string` | `null` | ALB target group ARN for load balancing |
| `container_name` | `string` | `"app"` | Container name for ALB registration |
| `container_port` | `number` | `8080` | Port the container listens on |
| `autoscaling_enabled` | `bool` | `true` | Enable Application Auto Scaling |
| `autoscaling_min_capacity` | `number` | `1` | Minimum task count |
| `autoscaling_max_capacity` | `number` | `10` | Maximum task count |
| `autoscaling_cpu_target` | `number` | `70` | Target CPU % for auto-scaling |
| `autoscaling_memory_target` | `number` | `80` | Target memory % for auto-scaling |
| `log_retention_days` | `number` | `30` | CloudWatch log retention in days |
| `tags` | `map(string)` | `{}` | Additional resource tags |

## Outputs

| Name | Description |
|---|---|
| `cluster_id` | ECS cluster ID |
| `cluster_arn` | ECS cluster ARN |
| `cluster_name` | ECS cluster name |
| `service_id` | ECS service ARN/ID |
| `service_name` | ECS service name |
| `task_definition_arn` | Task definition ARN |
| `task_definition_family` | Task definition family name |
| `service_security_group_id` | Security group ID for ECS tasks |
| `log_group_name` | CloudWatch log group name |
| `log_group_arn` | CloudWatch log group ARN |
