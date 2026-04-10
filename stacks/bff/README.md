# Stack: `bff`

Deploys a Backend For Frontend (BFF) or public-facing API service on the shared ECS Fargate cluster. Registers a path-based listener rule on the **public ALB** and wires up an ECR repository, IAM task role, and CloudWatch log group.

Use this stack for user-facing or client-facing services. For internal service-to-service APIs, use `stacks/microservice` instead.

## What it creates

- ECR repository for the service image
- IAM task role (with optional Secrets Manager read access)
- ALB target group on the public ALB
- ALB listener rule (path-based routing)
- ECS Fargate service + task definition
- CloudWatch log group
- Application Auto Scaling (CPU + memory targets)

## Usage

```hcl
module "web_bff" {
  source = "../../stacks/bff"

  project     = "myapp"
  environment = "prod"
  region      = "us-east-1"

  service_name    = "web-bff"
  container_image = "123456789012.dkr.ecr.us-east-1.amazonaws.com/myapp/prod/web-bff:abc1234"
  container_port  = 8080
  path_pattern    = "/api/*"
  listener_priority = 10

  ssm_prefix = "/myapp/prod/infra"  # reads VPC/cluster/role from platform SSM outputs

  task_cpu    = 512
  task_memory = 1024
  desired_count = 2

  secret_arns = [
    "arn:aws:secretsmanager:us-east-1:123456789012:secret:myapp/prod/api-key"
  ]

  environment_variables = {
    LOG_LEVEL = "INFO"
    PORT      = "8080"
  }

  tags = { Team = "frontend" }
}
```

### Passing infrastructure directly (without SSM)

```hcl
module "web_bff" {
  source = "../../stacks/bff"
  # ...
  ssm_prefix              = null
  vpc_id                  = module.platform.vpc_id
  private_subnet_ids      = module.platform.private_subnet_ids
  ecs_cluster_arn         = module.platform.ecs_cluster_arn
  public_alb_listener_arn = module.platform.public_alb_listener_arn
  sg_ecs_tasks_id         = module.platform.sg_ecs_tasks_id
  task_execution_role_arn = module.platform.ecs_task_execution_role_arn
}
```

## Required Inputs

| Name | Type | Description |
|---|---|---|
| `project` | `string` | Project name prefix |
| `environment` | `string` | Deployment environment |
| `region` | `string` | AWS region |
| `service_name` | `string` | Short service name (e.g. `web-bff`) |
| `container_image` | `string` | Full ECR image URI including tag |
| `path_pattern` | `string` | ALB path pattern (e.g. `/api/*`) |
| `listener_priority` | `number` | Listener rule priority — must be unique across all services |

## Optional Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `container_port` | `number` | `8080` | Port the container listens on |
| `task_cpu` | `number` | `512` | Fargate task CPU units |
| `task_memory` | `number` | `1024` | Fargate task memory in MiB |
| `desired_count` | `number` | `2` | Desired running task count |
| `autoscaling_min` | `number` | `1` | Minimum task count |
| `autoscaling_max` | `number` | `10` | Maximum task count |
| `health_check_path` | `string` | `"/health"` | ALB health check path |
| `environment_variables` | `map(string)` | `{}` | Container environment variables |
| `secret_arns` | `list(string)` | `[]` | Secrets Manager ARNs injected as env vars |
| `ssm_prefix` | `string` | `null` | Platform SSM prefix. When set, reads all infra values from SSM |
| `vpc_id` | `string` | `null` | VPC ID (used when `ssm_prefix` is null) |
| `private_subnet_ids` | `list(string)` | `null` | Private subnet IDs for ECS tasks |
| `ecs_cluster_arn` | `string` | `null` | ECS cluster ARN |
| `public_alb_listener_arn` | `string` | `null` | Public ALB HTTPS listener ARN |
| `sg_ecs_tasks_id` | `string` | `null` | ECS tasks security group ID |
| `task_execution_role_arn` | `string` | `null` | ECS task execution role ARN |
| `tags` | `map(string)` | `{}` | Additional resource tags |

## Outputs

| Name | Description |
|---|---|
| `ecr_repository_url` | ECR repository URL (use in `deploy-bff.yml` as `ecr_repository`) |
| `ecs_service_name` | ECS service name (use in `deploy-bff.yml` as `service_name`) |
| `task_role_arn` | IAM task role ARN |
| `target_group_arn` | ALB target group ARN |
| `log_group_name` | CloudWatch log group name |

## Deployment

After provisioning this stack with `tf-apply.yml`, deploy new image versions using:

```yaml
uses: your-org/infra-modules/.github/workflows/deploy-bff.yml@main
with:
  ecr_repository:     myapp/prod/web-bff
  stack_directory:    stacks/bff
  backend_config_file: config/backend-prod.hcl
  var_file:           environments/prod/web-bff.tfvars
```
