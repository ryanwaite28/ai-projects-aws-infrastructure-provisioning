output "ecr_repository_url"  { value = module.ecr.repository_url }
output "ecs_service_name"     { value = module.ecs_service.service_name }
output "task_role_arn"        { value = module.task_role.role_arn }
output "target_group_arn"     { value = aws_lb_target_group.this.arn }
output "log_group_name"       { value = module.ecs_service.log_group_name }
