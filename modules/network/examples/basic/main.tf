module "network" {
  source = "../../"

  project     = "myapp"
  environment = "dev"
  region      = "us-east-1"

  vpc_cidr             = "10.0.0.0/16"
  azs                  = ["us-east-1a", "us-east-1b"]
  public_subnet_cidrs  = ["10.0.0.0/24", "10.0.1.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]
  db_subnet_cidrs      = ["10.0.20.0/24", "10.0.21.0/24"]

  enable_nat_gateway  = true
  single_nat_gateway  = true # cost-saving for dev

  enable_vpce_s3       = true
  enable_vpce_dynamodb = true
  interface_endpoints  = ["ecr.api", "ecr.dkr", "secretsmanager", "ssm", "logs"]

  enable_flow_logs        = true
  flow_log_retention_days = 14

  tags = { Team = "platform" }
}

output "vpc_id"             { value = module.network.vpc_id }
output "public_subnet_ids"  { value = module.network.public_subnet_ids }
output "private_subnet_ids" { value = module.network.private_subnet_ids }
output "db_subnet_ids"      { value = module.network.db_subnet_ids }
