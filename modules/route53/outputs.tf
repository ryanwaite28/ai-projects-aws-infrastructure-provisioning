output "zone_id" {
  value       = local.zone_id
  description = "Route 53 hosted zone ID."
}

output "zone_name" {
  value       = var.zone_name
  description = "Route 53 zone name."
}

output "name_servers" {
  value       = var.create_zone ? aws_route53_zone.this[0].name_servers : []
  description = "Name servers (only populated for newly created zones)."
}

output "record_fqdns" {
  value       = { for k, v in aws_route53_record.this : k => v.fqdn }
  description = "Map of record key to FQDN."
}
