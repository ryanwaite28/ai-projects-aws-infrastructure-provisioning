output "file_system_id" {
  value       = aws_efs_file_system.this.id
  description = "EFS file system ID."
}

output "file_system_arn" {
  value       = aws_efs_file_system.this.arn
  description = "EFS file system ARN."
}

output "dns_name" {
  value       = aws_efs_file_system.this.dns_name
  description = "DNS name for mount targets."
}

output "security_group_id" {
  value       = aws_security_group.efs.id
  description = "Security group ID for NFS access."
}

output "mount_target_ids" {
  value       = aws_efs_mount_target.this[*].id
  description = "IDs of the mount targets."
}

output "access_point_ids" {
  value       = { for k, v in aws_efs_access_point.this : k => v.id }
  description = "Map of access point key to ID."
}

output "access_point_arns" {
  value       = { for k, v in aws_efs_access_point.this : k => v.arn }
  description = "Map of access point key to ARN."
}
