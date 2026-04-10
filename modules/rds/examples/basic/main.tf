# Aurora PostgreSQL cluster with 2 instances.
# Substitute real subnet and security group IDs.

module "db" {
  source = "../../"

  project            = "myapp"
  environment        = "dev"
  region             = "us-east-1"
  cluster_identifier = "primary"
  database_name      = "appdb"

  subnet_ids             = ["subnet-aaa", "subnet-bbb"]
  vpc_security_group_ids = ["sg-0a1b2c3d4e"]

  engine         = "aurora-postgresql"
  engine_version = "15.4"
  instance_count = 1           # writer only for dev
  instance_class = "db.t4g.medium"

  deletion_protection = false
  skip_final_snapshot = true   # OK in dev

  tags = { Team = "data" }
}

output "cluster_endpoint"     { value = module.db.cluster_endpoint }
output "master_user_secret_arn" { value = module.db.master_user_secret_arn }
