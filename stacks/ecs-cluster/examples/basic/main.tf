# Requires base-network outputs. Substitute real values.

module "cluster" {
  source = "../../"

  project     = "myapp"
  environment = "dev"
  region      = "us-east-1"

  vpc_id             = "vpc-0a1b2c3d4e5f"
  vpc_cidr           = "10.0.0.0/16"
  public_subnet_ids  = ["subnet-aaa", "subnet-bbb"]
  private_subnet_ids = ["subnet-ccc", "subnet-ddd"]

  domain  = "example.com"
  zone_id = "Z1234567890ABCDEF"

  waf_rate_limit = 2000

  tags = { Team = "platform" }
}

output "ecs_cluster_arn"         { value = module.cluster.ecs_cluster_arn }
output "public_alb_dns"          { value = module.cluster.public_alb_dns }
output "public_alb_listener_arn" { value = module.cluster.public_alb_listener_arn }
output "sg_ecs_tasks_id"         { value = module.cluster.sg_ecs_tasks_id }
