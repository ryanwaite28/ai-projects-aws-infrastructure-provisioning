##
## Stack: ecs-cluster
## Shared ECS cluster with public and private ALBs.
## BFF and microservice stacks attach to this cluster.
##

provider "aws" { region = var.region }

locals {
  region_short = {
    "us-east-1" = "use1", "us-east-2" = "use2", "us-west-1" = "usw1", "us-west-2" = "usw2",
    "eu-west-1" = "euw1", "eu-west-2" = "euw2", "eu-central-1" = "euc1",
    "ap-southeast-1" = "apse1", "ap-southeast-2" = "apse2", "ap-northeast-1" = "apne1"
  }
  rs          = lookup(local.region_short, var.region, replace(var.region, "-", ""))
  name_prefix = "${var.project}-${var.environment}-${local.rs}"
}

# ── Security Groups ───────────────────────────────────────────────────────────

resource "aws_security_group" "public_alb" {
  name        = "${local.name_prefix}-sg-public-alb"
  description = "Public ALB: allow inbound HTTPS/HTTP from internet."
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS"
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP redirect"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${local.name_prefix}-sg-public-alb", ManagedBy = "terraform" })
}

resource "aws_security_group" "private_alb" {
  name        = "${local.name_prefix}-sg-private-alb"
  description = "Private ALB: allow inbound HTTPS from VPC."
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "HTTPS from VPC"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${local.name_prefix}-sg-private-alb", ManagedBy = "terraform" })
}

resource "aws_security_group" "ecs_tasks" {
  name        = "${local.name_prefix}-sg-ecs-tasks"
  description = "ECS tasks: allow inbound from ALBs on container port range."
  vpc_id      = var.vpc_id

  ingress {
    from_port                = 1024
    to_port                  = 65535
    protocol                 = "tcp"
    security_groups          = [aws_security_group.public_alb.id, aws_security_group.private_alb.id]
    description              = "From ALBs"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${local.name_prefix}-sg-ecs-tasks", ManagedBy = "terraform" })
}

# ── WAF ───────────────────────────────────────────────────────────────────────

module "waf" {
  source      = "../../modules/waf"
  project     = var.project
  environment = var.environment
  region      = var.region
  name        = "public-alb"
  scope       = "REGIONAL"
  rate_limit_rules = [{ name = "rate-limit-global", priority = 1, limit = var.waf_rate_limit }]
  tags        = var.tags
}

# ── ACM Certificate ───────────────────────────────────────────────────────────

module "acm" {
  source      = "../../modules/acm"
  project     = var.project
  environment = var.environment
  region      = var.region
  domain_name = "*.${var.domain}"
  zone_id     = var.zone_id
  tags        = var.tags
}

# ── ECS Cluster ───────────────────────────────────────────────────────────────

module "ecs_cluster" {
  source      = "../../modules/ecs"
  project     = var.project
  environment = var.environment
  region      = var.region
  cluster_name              = var.cluster_name
  cluster_only              = true
  container_insights_enabled = var.container_insights_enabled
  execute_command_enabled   = var.execute_command_enabled
  tags                      = var.tags
}

# ── Public ALB ────────────────────────────────────────────────────────────────

module "public_alb" {
  source      = "../../modules/alb"
  project     = var.project
  environment = var.environment
  region      = var.region
  name        = "public"
  internal    = false
  vpc_id      = var.vpc_id
  subnet_ids  = var.public_subnet_ids
  security_group_ids          = [aws_security_group.public_alb.id]
  certificate_arn             = module.acm.certificate_arn
  enable_http_to_https_redirect = true
  waf_acl_arn                 = module.waf.web_acl_arn
  enable_access_logs          = var.alb_access_log_bucket != null
  access_logs_bucket          = var.alb_access_log_bucket
  tags                        = var.tags
}

# ── Private ALB ───────────────────────────────────────────────────────────────

module "private_alb" {
  source      = "../../modules/alb"
  project     = var.project
  environment = var.environment
  region      = var.region
  name        = "private"
  internal    = true
  vpc_id      = var.vpc_id
  subnet_ids  = var.private_subnet_ids
  security_group_ids            = [aws_security_group.private_alb.id]
  certificate_arn               = module.acm.certificate_arn
  enable_http_to_https_redirect = false
  enable_access_logs            = var.alb_access_log_bucket != null
  access_logs_bucket            = var.alb_access_log_bucket
  tags                          = var.tags
}
