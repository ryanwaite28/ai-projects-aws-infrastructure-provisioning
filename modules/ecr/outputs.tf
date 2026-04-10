output "repository_url" {
  description = "Full URL of the ECR repository (used in docker push/pull and ECS task definitions)."
  value       = aws_ecr_repository.this.repository_url
}

output "repository_arn" {
  description = "ARN of the ECR repository."
  value       = aws_ecr_repository.this.arn
}

output "repository_name" {
  description = "Name of the ECR repository."
  value       = aws_ecr_repository.this.name
}

output "registry_id" {
  description = "AWS account ID of the ECR registry (same as the account ID)."
  value       = aws_ecr_repository.this.registry_id
}
