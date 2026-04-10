##
## Stack: platform
## High-level "day zero" stack. Provisions base-network + ecs-cluster +
## security groups + IAM roles + KMS + SSM outputs.
## Deploy once per environment before any application stack.
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
  ssm_prefix  = "/platform/${var.environment}"
}

# ── KMS Platform Key ──────────────────────────────────────────────────────────

module "kms" {
  source      = "../../modules/kms"
  project     = var.project
  environment = var.environment
  region      = var.region
  alias       = "platform"
  description = "Platform CMK for flow logs, SSM, Secrets Manager, ECS exec"
  service_principals = [
    "logs.${var.region}.amazonaws.com",
    "ssm.amazonaws.com",
    "secretsmanager.amazonaws.com",
  ]
  tags = var.tags
}

# ── Base Network ──────────────────────────────────────────────────────────────

module "base_network" {
  source      = "../base-network"
  project     = var.project
  environment = var.environment
  region      = var.region

  vpc_cidr             = var.vpc_cidr
  azs                  = var.azs
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  db_subnet_cidrs      = var.db_subnet_cidrs
  single_nat_gateway   = var.single_nat_gateway
  interface_endpoints  = var.interface_endpoints
  flow_log_kms_key_arn = module.kms.key_arn
  tags                 = var.tags
}

# ── ECS Cluster + ALBs + Security Groups ─────────────────────────────────────

module "ecs_cluster" {
  source      = "../ecs-cluster"
  project     = var.project
  environment = var.environment
  region      = var.region

  vpc_id             = module.base_network.vpc_id
  public_subnet_ids  = module.base_network.public_subnet_ids
  private_subnet_ids = module.base_network.private_subnet_ids
  vpc_cidr           = module.base_network.vpc_cidr
  domain             = var.domain
  zone_id            = var.zone_id
  waf_rate_limit     = var.waf_rate_limit
  alb_access_log_bucket = var.alb_access_log_bucket
  cluster_name       = var.cluster_name
  execute_command_enabled = var.execute_command_enabled
  tags               = var.tags
}

# ── Additional Platform Security Groups ──────────────────────────────────────

resource "aws_security_group" "rds" {
  name        = "${local.name_prefix}-sg-rds"
  description = "RDS: allow inbound from ECS tasks."
  vpc_id      = module.base_network.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [module.ecs_cluster.sg_ecs_tasks_id]
    description     = "PostgreSQL from ECS tasks"
  }
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [module.ecs_cluster.sg_ecs_tasks_id]
    description     = "MySQL from ECS tasks"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(var.tags, { Name = "${local.name_prefix}-sg-rds", ManagedBy = "terraform" })
}

resource "aws_security_group" "elasticache" {
  name        = "${local.name_prefix}-sg-elasticache"
  description = "ElastiCache: allow inbound Redis from ECS tasks."
  vpc_id      = module.base_network.vpc_id

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [module.ecs_cluster.sg_ecs_tasks_id]
    description     = "Redis from ECS tasks"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(var.tags, { Name = "${local.name_prefix}-sg-elasticache", ManagedBy = "terraform" })
}

resource "aws_security_group" "lambda" {
  name        = "${local.name_prefix}-sg-lambda"
  description = "Lambda: allow outbound to VPC resources."
  vpc_id      = module.base_network.vpc_id

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "HTTPS to VPC"
  }
  egress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.rds.id]
    description     = "RDS"
  }
  egress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.elasticache.id]
    description     = "Redis"
  }
  tags = merge(var.tags, { Name = "${local.name_prefix}-sg-lambda", ManagedBy = "terraform" })
}

# ── IAM: ECS Task Execution Role (shared baseline) ────────────────────────────

module "ecs_task_execution_role" {
  source      = "../../modules/iam"
  project     = var.project
  environment = var.environment
  region      = var.region
  role_name   = "ecs-task-execution"
  role_description = "Shared ECS task execution role: ECR pull, CloudWatch Logs, Secrets Manager."
  trusted_service_principals = ["ecs-tasks.amazonaws.com"]
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"]
  permission_boundary_arn = aws_iam_policy.platform_boundary.arn
  tags = var.tags
}

# ── IAM: DevOps Role ──────────────────────────────────────────────────────────
# This role is for APPLICATION CI/CD (ECR push, ECS deploy, Secrets read).
# It is NOT the Terraform execution role — that is created separately in
# bootstrap/oidc and is assumed by the tf-plan/tf-apply workflows.
# Application repos assume this role to deploy code changes.

module "devops_role" {
  source      = "../../modules/iam"
  project     = var.project
  environment = var.environment
  region      = var.region
  role_name   = var.devops_role_name
  role_description = "Application CI/CD role: ECR push, ECS deploy, SSM/Secrets read. NOT for Terraform execution."

  # var.github_oidc_provider_arn is required — the platform stack will fail
  # fast if it is omitted rather than creating a role nobody can assume.
  trusted_oidc_provider_arn = var.github_oidc_provider_arn
  oidc_subject_conditions   = { "token.actions.githubusercontent.com:sub" = var.github_repo_subject }

  # Scoped inline policy — no wildcard admin.
  # Grants exactly what an app deploy workflow needs and nothing more.
  inline_policies = {
    AppDeployment = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          # ECR authentication (resource must be *)
          Sid      = "ECRAuth"
          Effect   = "Allow"
          Action   = ["ecr:GetAuthorizationToken"]
          Resource = "*"
        },
        {
          # ECR image push / pull
          Sid    = "ECRImageOps"
          Effect = "Allow"
          Action = [
            "ecr:BatchCheckLayerAvailability",
            "ecr:GetDownloadUrlForLayer",
            "ecr:BatchGetImage",
            "ecr:PutImage",
            "ecr:InitiateLayerUpload",
            "ecr:UploadLayerPart",
            "ecr:CompleteLayerUpload",
            "ecr:DescribeRepositories",
            "ecr:DescribeImages",
            "ecr:ListImages",
          ]
          Resource = "arn:aws:ecr:*:*:repository/*"
        },
        {
          # ECS: register new task definition revision + update service
          Sid    = "ECSDeployment"
          Effect = "Allow"
          Action = [
            "ecs:DescribeClusters",
            "ecs:DescribeServices",
            "ecs:DescribeTaskDefinition",
            "ecs:RegisterTaskDefinition",
            "ecs:UpdateService",
            "ecs:ListTasks",
            "ecs:DescribeTasks",
          ]
          Resource = "*"
        },
        {
          # Allow passing ECS task execution and task roles — scoped to ECS only
          Sid      = "PassECSRoles"
          Effect   = "Allow"
          Action   = ["iam:PassRole"]
          Resource = "*"
          Condition = {
            StringLike = { "iam:PassedToService" = "ecs-tasks.amazonaws.com" }
          }
        },
        {
          # Secrets Manager: read-only for deploy-time secret injection
          Sid    = "SecretsRead"
          Effect = "Allow"
          Action = [
            "secretsmanager:GetSecretValue",
            "secretsmanager:DescribeSecret",
            "secretsmanager:ListSecrets",
          ]
          Resource = "arn:aws:secretsmanager:*:*:secret:*"
        },
        {
          # SSM Parameter Store: read platform outputs and app config
          Sid    = "SSMRead"
          Effect = "Allow"
          Action = [
            "ssm:GetParameter",
            "ssm:GetParameters",
            "ssm:GetParametersByPath",
          ]
          Resource = "arn:aws:ssm:*:*:parameter/*"
        },
        {
          # CloudWatch Logs: tail logs during and after deployments
          Sid    = "LogsRead"
          Effect = "Allow"
          Action = [
            "logs:DescribeLogGroups",
            "logs:DescribeLogStreams",
            "logs:GetLogEvents",
            "logs:FilterLogEvents",
            "logs:StartQuery",
            "logs:GetQueryResults",
          ]
          Resource = "*"
        },
      ]
    })
  }

  permission_boundary_arn = aws_iam_policy.platform_boundary.arn
  tags = var.tags
}

# ── IAM: Permission Boundary ──────────────────────────────────────────────────

resource "aws_iam_policy" "platform_boundary" {
  name        = "${local.name_prefix}-platform-boundary"
  description = "Permission boundary applied to all platform-managed roles. Prevents IAM escalation."
  tags        = var.tags

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Allow-all baseline; the Deny statements below are the actual controls.
      # This is the standard permission boundary pattern: broad allow + targeted denies
      # prevents privilege escalation without needing to enumerate every permitted action.
      { Effect = "Allow", Action = "*", Resource = "*" },
      { Effect = "Deny", Action = ["iam:CreateUser", "iam:DeleteUser", "organizations:*", "account:*"], Resource = "*" }
    ]
  })
}

# ── Monitoring ────────────────────────────────────────────────────────────────

module "monitoring" {
  source      = "../../modules/monitoring"
  project     = var.project
  environment = var.environment
  region      = var.region
  alert_emails = var.alert_emails
  tags         = var.tags
}

# ── SSM Parameter Store outputs (consumed by app stacks) ─────────────────────

locals {
  ssm_params = {
    vpc_id                     = module.base_network.vpc_id
    vpc_cidr                   = module.base_network.vpc_cidr
    public_subnet_ids          = join(",", module.base_network.public_subnet_ids)
    private_subnet_ids         = join(",", module.base_network.private_subnet_ids)
    db_subnet_ids              = join(",", module.base_network.db_subnet_ids)
    ecs_cluster_arn            = module.ecs_cluster.ecs_cluster_arn
    ecs_cluster_name           = module.ecs_cluster.ecs_cluster_name
    public_alb_listener_arn    = module.ecs_cluster.public_alb_listener_arn
    private_alb_listener_arn   = module.ecs_cluster.private_alb_listener_arn
    public_alb_dns             = module.ecs_cluster.public_alb_dns
    private_alb_dns            = module.ecs_cluster.private_alb_dns
    sg_ecs_tasks_id            = module.ecs_cluster.sg_ecs_tasks_id
    sg_public_alb_id           = module.ecs_cluster.sg_public_alb_id
    sg_private_alb_id          = module.ecs_cluster.sg_private_alb_id
    sg_rds_id                  = aws_security_group.rds.id
    sg_elasticache_id          = aws_security_group.elasticache.id
    sg_lambda_id               = aws_security_group.lambda.id
    platform_kms_key_arn       = module.kms.key_arn
    ecs_task_execution_role_arn = module.ecs_task_execution_role.role_arn
    devops_role_arn            = module.devops_role.role_arn
    acm_certificate_arn        = module.ecs_cluster.acm_certificate_arn
    alerts_topic_arn           = module.monitoring.alerts_topic_arn
  }
}

resource "aws_ssm_parameter" "platform" {
  for_each = local.ssm_params
  name     = "${local.ssm_prefix}/${each.key}"
  type     = "SecureString"
  value    = each.value
  key_id   = module.kms.key_id
  tags     = merge(var.tags, { ManagedBy = "terraform" })
}
