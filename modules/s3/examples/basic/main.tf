module "uploads" {
  source = "../../"

  project       = "myapp"
  environment   = "dev"
  region        = "us-east-1"
  bucket_suffix = "uploads"

  versioning_enabled = true

  lifecycle_rules = [
    {
      id                                 = "expire-old-versions"
      enabled                            = true
      noncurrent_version_expiration_days = 30
    }
  ]

  tags = { Team = "backend" }
}

output "bucket_id"  { value = module.uploads.bucket_id }
output "bucket_arn" { value = module.uploads.bucket_arn }
