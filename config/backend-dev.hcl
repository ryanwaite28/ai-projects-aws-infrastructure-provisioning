# Terraform S3 backend configuration — dev environment
# Usage: terraform init -backend-config=config/backend-dev.hcl

bucket         = "myapp-terraform-state"
key            = "dev/terraform.tfstate"
region         = "us-east-1"
dynamodb_table = "myapp-terraform-locks"
encrypt        = true
