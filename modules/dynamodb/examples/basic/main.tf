module "sessions" {
  source = "../../"

  project     = "myapp"
  environment = "dev"
  region      = "us-east-1"
  table_name  = "sessions"
  hash_key    = "session_id"

  billing_mode           = "PAY_PER_REQUEST"
  ttl_attribute          = "expires_at"
  point_in_time_recovery = true

  tags = { Team = "backend" }
}

output "table_name" { value = module.sessions.table_name }
output "table_arn"  { value = module.sessions.table_arn }
