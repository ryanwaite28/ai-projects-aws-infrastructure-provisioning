# Stack: `async-worker`

Deploys an ECS Fargate worker that processes messages from an SQS queue. Scales based on queue depth — tasks scale out when messages accumulate and scale in to zero when the queue is empty.

## What it creates

- SQS queue + DLQ
- ECR repository for the worker image
- ECS Fargate service (runs as a long-lived worker polling SQS)
- Application Auto Scaling based on `ApproximateNumberOfMessagesVisible`
- IAM task role with SQS consume permissions

## Usage

```hcl
module "order_worker" {
  source = "../../stacks/async-worker"

  project     = "myapp"
  environment = "prod"
  region      = "us-east-1"
  name        = "order-worker"

  container_image = "123456789012.dkr.ecr.us-east-1.amazonaws.com/myapp/prod/order-worker:abc1234"

  vpc_id                  = module.platform.vpc_id
  private_subnet_ids      = module.platform.private_subnet_ids
  ecs_cluster_arn         = module.platform.ecs_cluster_arn
  task_execution_role_arn = module.platform.ecs_task_execution_role_arn

  task_cpu    = 512
  task_memory = 1024

  visibility_timeout_seconds = 360  # >= 6× container processing time
  target_messages_per_task   = 10   # scale 1 task per 10 queued messages

  environment_variables = {
    LOG_LEVEL = "INFO"
  }

  kms_key_arn = module.platform.platform_kms_key_arn
  tags = { Team = "backend" }
}
```

## Required Inputs

| Name | Type | Description |
|---|---|---|
| `project` | `string` | Project name prefix |
| `environment` | `string` | Deployment environment |
| `region` | `string` | AWS region |
| `name` | `string` | Short worker name |
| `container_image` | `string` | Full ECR image URI including tag |
| `vpc_id` | `string` | VPC ID |
| `private_subnet_ids` | `list(string)` | Private subnet IDs for ECS tasks |
| `ecs_cluster_arn` | `string` | ECS cluster ARN |
| `task_execution_role_arn` | `string` | ECS task execution role ARN |

## Optional Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `task_cpu` | `number` | `512` | Fargate task CPU units |
| `task_memory` | `number` | `1024` | Fargate task memory in MiB |
| `desired_count` | `number` | `1` | Initial desired task count |
| `autoscaling_min` | `number` | `0` | Min tasks (0 = scale to zero when queue empty) |
| `autoscaling_max` | `number` | `20` | Max tasks |
| `target_messages_per_task` | `number` | `10` | Messages per task target for scaling |
| `visibility_timeout_seconds` | `number` | `120` | SQS visibility timeout. Keep ≥ 6× processing time |
| `environment_variables` | `map(string)` | `{}` | Container environment variables |
| `security_group_ids` | `list(string)` | `[]` | Additional security group IDs |
| `kms_key_arn` | `string` | `null` | KMS key for SQS encryption |
| `tags` | `map(string)` | `{}` | Additional resource tags |

## Outputs

| Name | Description |
|---|---|
| `queue_url` | SQS queue URL |
| `dlq_url` | Dead-letter queue URL |
| `ecr_repo_url` | ECR repository URL |
| `ecs_service_name` | ECS service name |
