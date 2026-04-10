output "cluster_id" {
  value       = aws_rds_cluster.this.id
  description = "RDS cluster ID."
}

output "cluster_arn" {
  value       = aws_rds_cluster.this.arn
  description = "RDS cluster ARN."
}

output "cluster_endpoint" {
  value       = aws_rds_cluster.this.endpoint
  description = "Writer endpoint."
}

output "reader_endpoint" {
  value       = aws_rds_cluster.this.reader_endpoint
  description = "Reader endpoint."
}

output "port" {
  value       = aws_rds_cluster.this.port
  description = "Database port."
}

output "database_name" {
  value       = aws_rds_cluster.this.database_name
  description = "Database name."
}

output "master_user_secret_arn" {
  value       = aws_rds_cluster.this.master_user_secret[*].secret_arn
  description = "Secrets Manager ARN for the auto-generated master password."
}

output "subnet_group_name" {
  value       = aws_db_subnet_group.this.name
  description = "DB subnet group name."
}
