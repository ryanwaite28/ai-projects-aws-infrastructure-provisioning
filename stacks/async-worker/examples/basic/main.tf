# Async ECS worker. Substitute real VPC/subnet/cluster values.

module "order_worker" {
  source = "../../"

  project     = "myapp"
  environment = "dev"
  region      = "us-east-1"
  name        = "order-worker"

  container_image = "public.ecr.aws/docker/library/alpine:latest"  # replaced on first real deploy

  vpc_id                  = "vpc-0a1b2c3d4e5f"
  private_subnet_ids      = ["subnet-aaa", "subnet-bbb"]
  ecs_cluster_arn         = "arn:aws:ecs:us-east-1:123456789012:cluster/myapp-dev-use1-ecs-main"
  task_execution_role_arn = "arn:aws:iam::123456789012:role/myapp-dev-use1-role-ecs-task-execution"

  task_cpu    = 256
  task_memory = 512

  autoscaling_min            = 0
  autoscaling_max            = 5
  target_messages_per_task   = 10
  visibility_timeout_seconds = 120

  environment_variables = {
    LOG_LEVEL = "DEBUG"
  }

  tags = { Team = "backend" }
}

output "queue_url"    { value = module.order_worker.queue_url }
output "ecr_repo_url" { value = module.order_worker.ecr_repo_url }
