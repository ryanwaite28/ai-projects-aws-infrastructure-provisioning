module "kms" {
  source = "../../"

  project     = "myapp"
  environment = "dev"
  region      = "us-east-1"
  alias       = "main"
  description = "Primary encryption key"

  enable_key_rotation  = true
  deletion_window_in_days = 30

  admin_principal_arns = [
    # "arn:aws:iam::123456789012:role/DevOpsRole"
  ]

  service_principals = [
    "logs.amazonaws.com",
    "secretsmanager.amazonaws.com",
  ]

  tags = { Team = "platform" }
}

output "key_arn"    { value = module.kms.key_arn }
output "alias_name" { value = module.kms.alias_name }
