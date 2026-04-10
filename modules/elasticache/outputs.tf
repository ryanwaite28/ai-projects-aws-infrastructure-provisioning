output "primary_endpoint" {
  value       = aws_elasticache_replication_group.this.primary_endpoint_address
  description = "Primary (writer) endpoint."
}

output "reader_endpoint" {
  value       = aws_elasticache_replication_group.this.reader_endpoint_address
  description = "Reader endpoint."
}

output "port" {
  value       = aws_elasticache_replication_group.this.port
  description = "Redis port."
}

output "replication_group_id" {
  value       = aws_elasticache_replication_group.this.id
  description = "Replication group ID."
}

output "arn" {
  value       = aws_elasticache_replication_group.this.arn
  description = "Replication group ARN."
}

output "subnet_group_name" {
  value       = aws_elasticache_subnet_group.this.name
  description = "Subnet group name."
}
