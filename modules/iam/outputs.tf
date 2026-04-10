output "role_name" {
  description = "Name of the IAM role."
  value       = aws_iam_role.this.name
}

output "role_arn" {
  description = "ARN of the IAM role."
  value       = aws_iam_role.this.arn
}

output "role_id" {
  description = "Unique ID of the IAM role."
  value       = aws_iam_role.this.unique_id
}

output "instance_profile_name" {
  description = "Name of the EC2 instance profile (only set when ec2.amazonaws.com is a trusted service)."
  value       = length(aws_iam_instance_profile.this) > 0 ? aws_iam_instance_profile.this[0].name : null
}

output "instance_profile_arn" {
  description = "ARN of the EC2 instance profile."
  value       = length(aws_iam_instance_profile.this) > 0 ? aws_iam_instance_profile.this[0].arn : null
}
