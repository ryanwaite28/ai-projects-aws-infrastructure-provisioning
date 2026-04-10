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

  single_nat_gateway = true  # cost-saving for dev

  tags = { Team = "platform" }
}

output "vpc_id"             { value = module.network.vpc_id }
output "private_subnet_ids" { value = module.network.private_subnet_ids }
output "db_subnet_ids"      { value = module.network.db_subnet_ids }
