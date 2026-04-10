project     = "myapp"
environment = "prod"
region      = "us-east-1"

vpc_cidr             = "10.30.0.0/16"
azs                  = ["us-east-1a", "us-east-1b", "us-east-1c"]
public_subnet_cidrs  = ["10.30.0.0/24", "10.30.1.0/24", "10.30.2.0/24"]
private_subnet_cidrs = ["10.30.10.0/24", "10.30.11.0/24", "10.30.12.0/24"]
db_subnet_cidrs      = ["10.30.20.0/24", "10.30.21.0/24", "10.30.22.0/24"]

# Required — must be set before deploying prod.
domain  = "example.com"
zone_id = "Z1234567890GHI"

alert_emails = ["oncall@example.com"]

github_oidc_provider_arn = "arn:aws:iam::ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
github_repo_subject      = "repo:your-org/your-app-repo:*"

tags = {
  Team       = "platform"
  CostCenter = "engineering"
}
