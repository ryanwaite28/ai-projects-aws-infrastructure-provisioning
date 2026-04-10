# Terraform S3 backend configuration — qa environment
# Usage: terraform init -backend-config=config/backend-qa.hcl

bucket         = "myapp-terraform-state"
key            = "qa/terraform.tfstate"
region         = "us-east-1"
dynamodb_table = "myapp-terraform-locks"
encrypt        = true
