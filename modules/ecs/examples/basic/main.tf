# Creates an ECS cluster and a simple Fargate service.
# Substitute real VPC/subnet/security group IDs and ECR image URL.

module "api_service" {
  source = "../../"

  project      = "myapp"
  environment  = "dev"
  region       = "us-east-1"
  cluster_name = "main"
  service_name = "api"

  vpc_id     = "vpc-0a1b2c3d4e5f"
  subnet_ids = ["subnet-aaa", "subnet-bbb"]

  task_cpu    = 256
  task_memory = 512

  desired_count = 1

  container_definitions = jsonencode([
    {
      name  = "app"
      image = "123456789012.dkr.ecr.us-east-1.amazonaws.com/myapp/dev/api:latest"
      portMappings = [{ containerPort = 8080 }]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/myapp/dev/api"
          awslogs-region        = "us-east-1"
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])

  autoscaling_enabled      = false
  log_retention_days       = 7

  tags = { Team = "backend" }
}

output "cluster_arn"  { value = module.api_service.cluster_arn }
output "service_name" { value = module.api_service.service_name }
