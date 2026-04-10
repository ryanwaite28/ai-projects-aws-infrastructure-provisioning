# Redis replication group with 2 nodes.
# Substitute real subnet and security group IDs.

module "cache" {
  source = "../../"

  project     = "myapp"
  environment = "dev"
  region      = "us-east-1"
  cluster_id  = "session"

  node_type          = "cache.t4g.small"
  num_cache_clusters = 1  # single node for dev

  subnet_ids         = ["subnet-aaa", "subnet-bbb"]
  security_group_ids = ["sg-0a1b2c3d4e"]

  automatic_failover_enabled = false  # requires num_cache_clusters >= 2
  multi_az_enabled           = false

  snapshot_retention_limit = 1

  tags = { Team = "backend" }
}

output "primary_endpoint" { value = module.cache.primary_endpoint }
output "port"             { value = module.cache.port }
