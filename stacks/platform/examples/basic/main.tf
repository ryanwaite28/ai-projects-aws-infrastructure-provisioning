# Full platform stack for a dev environment.
# Replace zone_id and github_oidc_provider_arn with real values.

data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

module "platform" {
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

  domain  = "dev.example.com"
  zone_id = "Z1234567890ABCDEF"

  github_oidc_provider_arn = data.aws_iam_openid_connect_provider.github.arn
  github_repo_subject      = "repo:your-org/your-app-repo:*"

  alert_emails = ["dev-alerts@example.com"]
  tags         = { Team = "platform" }
}

output "ssm_prefix"           { value = module.platform.ssm_prefix }
output "ecs_cluster_arn"      { value = module.platform.ecs_cluster_arn }
output "public_alb_dns"       { value = module.platform.public_alb_dns }
output "devops_role_arn"       { value = module.platform.devops_role_arn }
output "platform_kms_key_arn" { value = module.platform.platform_kms_key_arn }
