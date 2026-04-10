module "ecs_task_role" {
  source = "../../"

  project     = "myapp"
  environment = "dev"
  region      = "us-east-1"
  role_name   = "api-task"
  role_description = "ECS task role for the API service"

  trusted_service_principals = ["ecs-tasks.amazonaws.com"]

  inline_policies = {
    secrets-read = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect   = "Allow"
          Action   = ["secretsmanager:GetSecretValue"]
          Resource = ["arn:aws:secretsmanager:us-east-1:*:secret:myapp/dev/*"]
        }
      ]
    })
  }

  tags = { Team = "backend" }
}

output "role_arn"  { value = module.ecs_task_role.role_arn }
output "role_name" { value = module.ecs_task_role.role_name }
