# Data layer for dev — single RDS instance, single Redis node.
# Substitute real subnet and security group IDs.

module "data" {
  source = "../../"

  project     = "myapp"
  environment = "dev"
  region      = "us-east-1"

  db_subnet_ids      = ["subnet-aaa", "subnet-bbb"]
  sg_rds_ids         = ["sg-rds-id"]
  sg_elasticache_ids = ["sg-redis-id"]

  rds_enabled            = true
  rds_engine             = "aurora-postgresql"
  rds_instance_class     = "db.t4g.medium"
  rds_instance_count     = 1
  rds_database_name      = "appdb"
  rds_deletion_protection = false
  rds_skip_final_snapshot = true  # OK in dev

  elasticache_enabled       = true
  elasticache_node_type     = "cache.t4g.small"
  elasticache_cluster_count = 1

  dynamodb_tables = {
    sessions = { hash_key = "session_id" }
  }

  tags = { Team = "data" }
}

output "rds_cluster_endpoint"  { value = module.data.rds_cluster_endpoint }
output "redis_primary_endpoint" { value = module.data.redis_primary_endpoint }
