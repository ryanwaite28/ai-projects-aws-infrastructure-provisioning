# Network
output "vpc_id"                   { value = module.base_network.vpc_id }
output "vpc_cidr"                  { value = module.base_network.vpc_cidr }
output "public_subnet_ids"         { value = module.base_network.public_subnet_ids }
output "private_subnet_ids"        { value = module.base_network.private_subnet_ids }
output "db_subnet_ids"             { value = module.base_network.db_subnet_ids }

# ECS / ALBs
output "ecs_cluster_arn"           { value = module.ecs_cluster.ecs_cluster_arn }
output "ecs_cluster_name"          { value = module.ecs_cluster.ecs_cluster_name }
output "public_alb_arn"            { value = module.ecs_cluster.public_alb_arn }
output "public_alb_dns"            { value = module.ecs_cluster.public_alb_dns }
output "public_alb_listener_arn"   { value = module.ecs_cluster.public_alb_listener_arn }
output "private_alb_arn"           { value = module.ecs_cluster.private_alb_arn }
output "private_alb_dns"           { value = module.ecs_cluster.private_alb_dns }
output "private_alb_listener_arn"  { value = module.ecs_cluster.private_alb_listener_arn }

# Security Groups
output "sg_public_alb_id"          { value = module.ecs_cluster.sg_public_alb_id }
output "sg_private_alb_id"         { value = module.ecs_cluster.sg_private_alb_id }
output "sg_ecs_tasks_id"           { value = module.ecs_cluster.sg_ecs_tasks_id }
output "sg_rds_id"                 { value = aws_security_group.rds.id }
output "sg_elasticache_id"         { value = aws_security_group.elasticache.id }
output "sg_lambda_id"              { value = aws_security_group.lambda.id }

# IAM / KMS
output "platform_kms_key_arn"             { value = module.kms.key_arn }
output "ecs_task_execution_role_arn"       { value = module.ecs_task_execution_role.role_arn }
output "devops_role_arn"                   { value = module.devops_role.role_arn }
output "platform_boundary_policy_arn"      { value = aws_iam_policy.platform_boundary.arn }

# TLS
output "acm_certificate_arn"       { value = module.ecs_cluster.acm_certificate_arn }

# Monitoring
output "alerts_topic_arn"          { value = module.monitoring.alerts_topic_arn }

# SSM parameter paths (for app stacks to reference)
output "ssm_prefix" {
  value       = local.ssm_prefix
  description = "SSM prefix: read any platform output via data.aws_ssm_parameter.{name} using path = '{ssm_prefix}/{name}'."
}
