# Stack: `microservice`

Deploys an internal microservice on the shared ECS Fargate cluster. Registers a path-based listener rule on the **private ALB** — intended for service-to-service traffic that should not be reachable from the public internet.

For public/user-facing services, use `stacks/bff` instead.

## What it creates

- ECR repository for the service image
- IAM task role (with optional Secrets Manager read access)
- ALB target group on the private ALB
- ALB listener rule (path-based routing on the private listener)
- ECS Fargate service + task definition
- CloudWatch log group
- Application Auto Scaling

## Usage

```hcl
module "payments_svc" {
  source = "../../stacks/microservice"

  project     = "myapp"
  environment = "prod"
  region      = "us-east-1"

  service_name    = "payments-svc"
  container_image = "123456789012.dkr.ecr.us-east-1.amazonaws.com/myapp/prod/payments-svc:abc1234"
  container_port  = 8080
  path_pattern    = "/payments/*"
  listener_priority = 20

  ssm_prefix = "/myapp/prod/infra"

  task_cpu    = 1024
  task_memory = 2048
  desired_count = 2

  secret_arns = [
    "arn:aws:secretsmanager:us-east-1:123456789012:secret:myapp/prod/stripe-key"
  ]

  environment_variables = {
    LOG_LEVEL        = "INFO"
    STRIPE_ENDPOINT  = "https://api.stripe.com"
  }

  tags = { Team = "payments" }
}
```

## Required Inputs

| Name | Type | Description |
|---|---|---|
| `project` | `string` | Project name prefix |
| `environment` | `string` | Deployment environment |
| `region` | `string` | AWS region |
| `service_name` | `string` | Short service name (e.g. `payments-svc`) |
| `container_image` | `string` | Full ECR image URI including tag |
| `path_pattern` | `string` | Private ALB path pattern (e.g. `/payments/*`) |
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
| `private_alb_listener_arn` | `string` | `null` | Private ALB HTTPS listener ARN |
| `sg_ecs_tasks_id` | `string` | `null` | ECS tasks security group ID |
| `task_execution_role_arn` | `string` | `null` | ECS task execution role ARN |
| `tags` | `map(string)` | `{}` | Additional resource tags |

## Outputs

| Name | Description |
|---|---|
| `ecr_repository_url` | ECR repository URL (use in `deploy-microservice.yml` as `ecr_repository`) |
| `ecs_service_name` | ECS service name |
| `task_role_arn` | IAM task role ARN |
| `target_group_arn` | ALB target group ARN |
| `log_group_name` | CloudWatch log group name |

## Deployment

After provisioning this stack with `tf-apply.yml`, deploy new image versions using:

```yaml
uses: your-org/infra-modules/.github/workflows/deploy-microservice.yml@main
with:
  ecr_repository:      myapp/prod/payments-svc
  stack_directory:     stacks/microservice
  backend_config_file: config/backend-prod.hcl
  var_file:            environments/prod/payments-svc.tfvars
```
