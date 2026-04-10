output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.this.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC."
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  description = "List of public subnet IDs (one per AZ)."
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs (one per AZ)."
  value       = aws_subnet.private[*].id
}

output "db_subnet_ids" {
  description = "List of isolated/DB subnet IDs (one per AZ)."
  value       = aws_subnet.db[*].id
}

output "public_route_table_id" {
  description = "ID of the shared public route table."
  value       = aws_route_table.public.id
}

output "private_route_table_ids" {
  description = "IDs of the per-AZ private route tables."
  value       = aws_route_table.private[*].id
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway."
  value       = aws_internet_gateway.this.id
}

output "nat_gateway_ids" {
  description = "IDs of the NAT Gateways."
  value       = aws_nat_gateway.this[*].id
}

output "nat_public_ips" {
  description = "Elastic IP addresses assigned to the NAT Gateways."
  value       = aws_eip.nat[*].public_ip
}

output "vpce_security_group_id" {
  description = "Security group ID attached to all Interface VPC Endpoints."
  value       = length(var.interface_endpoints) > 0 ? aws_security_group.vpce[0].id : null
}

output "interface_endpoint_ids" {
  description = "Map of AWS service name to Interface VPC Endpoint ID."
  value       = { for k, v in aws_vpc_endpoint.interface : k => v.id }
}

output "vpce_s3_id" {
  description = "ID of the S3 Gateway VPC Endpoint."
  value       = var.enable_vpce_s3 ? aws_vpc_endpoint.s3[0].id : null
}

output "vpce_dynamodb_id" {
  description = "ID of the DynamoDB Gateway VPC Endpoint."
  value       = var.enable_vpce_dynamodb ? aws_vpc_endpoint.dynamodb[0].id : null
}

output "flow_log_log_group_arn" {
  description = "ARN of the CloudWatch Log Group receiving VPC Flow Logs."
  value       = var.enable_flow_logs ? aws_cloudwatch_log_group.flow_logs[0].arn : null
}
