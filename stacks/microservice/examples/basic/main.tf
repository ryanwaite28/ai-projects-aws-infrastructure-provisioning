# Internal microservice reading infrastructure from platform SSM outputs.
# Provision the platform stack first, then apply this.

module "payments_svc" {
  source = "../../"

  project     = "myapp"
  environment = "dev"
  region      = "us-east-1"

  service_name      = "payments-svc"
  container_image   = "public.ecr.aws/docker/library/nginx:alpine"  # replaced by deploy-microservice.yml
  container_port    = 8080
  path_pattern      = "/payments/*"
  listener_priority = 20

  ssm_prefix = "/myapp/dev/infra"

  task_cpu      = 256
  task_memory   = 512
  desired_count = 1

  environment_variables = {
    LOG_LEVEL = "DEBUG"
  }

  tags = { Team = "payments" }
}

output "ecr_repository_url" { value = module.payments_svc.ecr_repository_url }
output "ecs_service_name"   { value = module.payments_svc.ecs_service_name }
