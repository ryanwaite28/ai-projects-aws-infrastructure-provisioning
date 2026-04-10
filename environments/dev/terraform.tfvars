project     = "myapp"
environment = "dev"
region      = "us-east-1"

vpc_cidr             = "10.10.0.0/16"
azs                  = ["us-east-1a", "us-east-1b", "us-east-1c"]
public_subnet_cidrs  = ["10.10.0.0/24", "10.10.1.0/24", "10.10.2.0/24"]
private_subnet_cidrs = ["10.10.10.0/24", "10.10.11.0/24", "10.10.12.0/24"]
db_subnet_cidrs      = ["10.10.20.0/24", "10.10.21.0/24", "10.10.22.0/24"]

# Set after Route 53 hosted zone is created (Step 4 of bootstrap runbook).
domain  = "dev.example.com"
zone_id = "Z1234567890ABC"

alert_emails = ["oncall-dev@example.com"]

# Set after bootstrap/oidc is applied (Step 7 of bootstrap runbook).
github_oidc_provider_arn = "arn:aws:iam::ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
github_repo_subject      = "repo:your-org/your-app-repo:*"

tags = {
  Team       = "platform"
  CostCenter = "engineering"
}
