##
## Stack: data-layer
## RDS Aurora + ElastiCache + DynamoDB tables + S3 buckets.
##

terraform {
  required_version = ">= 1.7.0"
  required_providers { aws = { source = "hashicorp/aws", version = ">= 5.0" } }
}

provider "aws" { region = var.region }

module "kms" {
  source      = "../../modules/kms"
  project     = var.project
  environment = var.environment
  region      = var.region
  alias       = "data-layer"
  description = "Data layer CMK for RDS, ElastiCache, DynamoDB"
  tags        = var.tags
}

module "rds" {
  count       = var.rds_enabled ? 1 : 0
  source      = "../../modules/rds"
  project     = var.project
  environment = var.environment
  region      = var.region
  cluster_identifier         = "main"
  engine                     = var.rds_engine
  engine_version             = var.rds_engine_version
  instance_class             = var.rds_instance_class
  serverless_v2              = var.rds_serverless_v2
  instance_count             = var.rds_instance_count
  database_name              = var.rds_database_name
  subnet_ids                 = var.db_subnet_ids
  vpc_security_group_ids     = var.sg_rds_ids
  kms_key_arn                = module.kms.key_arn
  deletion_protection        = var.rds_deletion_protection
  skip_final_snapshot        = var.rds_skip_final_snapshot
  tags                       = var.tags
}

module "elasticache" {
  count       = var.elasticache_enabled ? 1 : 0
  source      = "../../modules/elasticache"
  project     = var.project
  environment = var.environment
  region      = var.region
  cluster_id         = "main"
  node_type          = var.elasticache_node_type
  num_cache_clusters = var.elasticache_cluster_count
  subnet_ids         = var.db_subnet_ids
  security_group_ids = var.sg_elasticache_ids
  kms_key_arn        = module.kms.key_arn
  tags               = var.tags
}

module "dynamodb_tables" {
  for_each    = var.dynamodb_tables
  source      = "../../modules/dynamodb"
  project     = var.project
  environment = var.environment
  region      = var.region
  table_name  = each.key
  hash_key    = each.value.hash_key
  range_key   = lookup(each.value, "range_key", null)
  billing_mode = lookup(each.value, "billing_mode", "PAY_PER_REQUEST")
  kms_key_arn = module.kms.key_arn
  tags        = var.tags
}

module "s3_buckets" {
  for_each      = var.s3_buckets
  source        = "../../modules/s3"
  project       = var.project
  environment   = var.environment
  region        = var.region
  bucket_suffix = each.key
  kms_key_arn   = module.kms.key_arn
  versioning_enabled = lookup(each.value, "versioning", false)
  tags          = var.tags
}
