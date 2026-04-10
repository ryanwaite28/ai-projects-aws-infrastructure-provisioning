# BFF service reading infrastructure from platform SSM outputs.
# Provision the platform stack first, then apply this.

module "web_bff" {
  source = "../../"

  project     = "myapp"
  environment = "dev"
  region      = "us-east-1"

  service_name      = "web-bff"
  container_image   = "public.ecr.aws/docker/library/nginx:alpine"  # replaced by deploy-bff.yml on first real deploy
  container_port    = 8080
  path_pattern      = "/api/*"
  listener_priority = 10

  ssm_prefix = "/myapp/dev/infra"

  task_cpu      = 256
  task_memory   = 512
  desired_count = 1

  environment_variables = {
    LOG_LEVEL = "DEBUG"
    PORT      = "8080"
  }

  tags = { Team = "frontend" }
}

output "ecr_repository_url" { value = module.web_bff.ecr_repository_url }
output "ecs_service_name"   { value = module.web_bff.ecs_service_name }
