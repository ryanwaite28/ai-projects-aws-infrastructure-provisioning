output "cluster_id" {
  description = "ID of the ECS cluster (null if cluster_arn was provided)."
  value       = local.create_cluster ? aws_ecs_cluster.this[0].id : null
}

output "cluster_arn" {
  description = "ARN of the ECS cluster (created or provided)."
  value       = local.effective_cluster_arn
}

output "cluster_name" {
  description = "Name of the ECS cluster."
  value       = local.create_cluster ? aws_ecs_cluster.this[0].name : null
}

output "service_id" {
  description = "ARN/ID of the ECS service."
  value       = var.cluster_only ? null : aws_ecs_service.this[0].id
}

output "service_name" {
  description = "Name of the ECS service."
  value       = var.cluster_only ? null : aws_ecs_service.this[0].name
}

output "task_definition_arn" {
  description = "ARN of the ECS task definition."
  value       = var.cluster_only ? null : aws_ecs_task_definition.this[0].arn
}

output "task_definition_family" {
  description = "Family name of the ECS task definition."
  value       = var.cluster_only ? null : aws_ecs_task_definition.this[0].family
}

output "service_security_group_id" {
  description = "ID of the security group attached to the ECS service tasks."
  value       = var.cluster_only ? null : aws_security_group.service[0].id
}

output "log_group_name" {
  description = "CloudWatch log group name for the service."
  value       = var.cluster_only ? null : aws_cloudwatch_log_group.service[0].name
}

output "log_group_arn" {
  description = "ARN of the CloudWatch log group."
  value       = var.cluster_only ? null : aws_cloudwatch_log_group.service[0].arn
}
