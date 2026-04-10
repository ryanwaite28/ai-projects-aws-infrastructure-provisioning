output "oidc_provider_arn" {
  value       = aws_iam_openid_connect_provider.github.arn
  description = "ARN of the GitHub Actions OIDC provider"
}

output "role_arns" {
  value       = { for env, role in aws_iam_role.github_actions : env => role.arn }
  description = "Map of environment → IAM role ARN. Store each as a GitHub Actions secret."
}
