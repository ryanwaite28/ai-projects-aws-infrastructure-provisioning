module "api_repo" {
  source = "../../"

  project         = "myapp"
  environment     = "dev"
  region          = "us-east-1"
  repository_name = "api"

  image_tag_mutability = "MUTABLE"  # use IMMUTABLE in prod
  scan_on_push         = true
  keep_image_count     = 5
  untagged_expiry_days = 7

  tags = { Team = "platform" }
}

output "repository_url" { value = module.api_repo.repository_url }
output "repository_arn" { value = module.api_repo.repository_arn }
