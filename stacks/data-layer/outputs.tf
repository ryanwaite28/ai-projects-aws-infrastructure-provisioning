output "kms_key_arn"          { value = module.kms.key_arn }
output "rds_cluster_endpoint" { value = var.rds_enabled ? module.rds[0].cluster_endpoint : null }
output "rds_reader_endpoint"  { value = var.rds_enabled ? module.rds[0].reader_endpoint : null }
output "redis_primary_endpoint" { value = var.elasticache_enabled ? module.elasticache[0].primary_endpoint : null }
output "dynamodb_table_names" { value = { for k, v in module.dynamodb_tables : k => v.table_name } }
output "s3_bucket_ids"        { value = { for k, v in module.s3_buckets : k => v.bucket_id } }
