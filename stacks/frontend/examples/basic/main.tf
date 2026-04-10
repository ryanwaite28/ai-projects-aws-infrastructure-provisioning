# Basic frontend deployment: S3 + CloudFront + ACM + Route 53.
# Substitute real zone_id and domain values.

module "frontend" {
  source = "../../"

  project     = "myapp"
  environment = "dev"
  region      = "us-east-1"

  name        = "dashboard"
  domain_name = "app.example.com"
  zone_name   = "example.com"
  zone_id     = "Z1234567890ABC"

  price_class = "PriceClass_100"

  tags = { Team = "frontend" }
}

output "s3_bucket_name"             { value = module.frontend.s3_bucket_name }
output "cloudfront_distribution_id" { value = module.frontend.cloudfront_distribution_id }
output "cloudfront_domain_name"     { value = module.frontend.cloudfront_domain_name }
