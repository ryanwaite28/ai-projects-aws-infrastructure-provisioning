output "volume_id" {
  value       = aws_ebs_volume.this.id
  description = "EBS volume ID."
}

output "volume_arn" {
  value       = aws_ebs_volume.this.arn
  description = "EBS volume ARN."
}

output "volume_size_gb" {
  value       = aws_ebs_volume.this.size
  description = "Volume size in GiB."
}

output "availability_zone" {
  value       = aws_ebs_volume.this.availability_zone
  description = "AZ of the volume."
}
