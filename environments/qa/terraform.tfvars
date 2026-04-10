project     = "myapp"
environment = "qa"
region      = "us-east-1"

vpc_cidr             = "10.20.0.0/16"
azs                  = ["us-east-1a", "us-east-1b", "us-east-1c"]
public_subnet_cidrs  = ["10.20.0.0/24", "10.20.1.0/24", "10.20.2.0/24"]
private_subnet_cidrs = ["10.20.10.0/24", "10.20.11.0/24", "10.20.12.0/24"]
db_subnet_cidrs      = ["10.20.20.0/24", "10.20.21.0/24", "10.20.22.0/24"]

domain  = "qa.example.com"
zone_id = "Z1234567890DEF"

alert_emails = ["oncall-qa@example.com"]

github_oidc_provider_arn = "arn:aws:iam::ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
github_repo_subject      = "repo:your-org/your-app-repo:*"

tags = {
  Team       = "platform"
  CostCenter = "engineering"
}
