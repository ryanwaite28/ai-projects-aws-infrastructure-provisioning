##
## Stack: base-network
## Foundation networking layer. Deploy first; all other stacks reference its outputs.
##

provider "aws" {
  region = var.region
}

module "network" {
  source = "../../modules/network"

  project     = var.project
  environment = var.environment
  region      = var.region

  vpc_cidr             = var.vpc_cidr
  azs                  = var.azs
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  db_subnet_cidrs      = var.db_subnet_cidrs

  enable_nat_gateway  = true
  single_nat_gateway  = var.single_nat_gateway
  enable_vpce_s3      = true
  enable_vpce_dynamodb = true
  interface_endpoints = var.interface_endpoints

  enable_flow_logs     = true
  flow_log_kms_key_arn = var.flow_log_kms_key_arn

  tags = var.tags
}
