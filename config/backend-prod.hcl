# Terraform S3 backend configuration — prod environment
# Usage: terraform init -backend-config=config/backend-prod.hcl

bucket         = "myapp-terraform-state"
key            = "prod/terraform.tfstate"
region         = "us-east-1"
dynamodb_table = "myapp-terraform-locks"
encrypt        = true
