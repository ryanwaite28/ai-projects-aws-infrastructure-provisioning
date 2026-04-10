# SPA served from S3 via CloudFront with OAC.
# Replace bucket_domain_name and certificate_arn with real values.

module "cdn" {
  source = "../../"

  project     = "myapp"
  environment = "dev"
  region      = "us-east-1"
  name        = "frontend"

  aliases             = []  # add custom domain in prod
  acm_certificate_arn = null  # required for custom domains

  origins = {
    s3 = {
      domain_name    = "myapp-dev-use1-assets.s3.us-east-1.amazonaws.com"
      origin_id      = "s3-assets"
      s3_oac_enabled = true
    }
  }

  default_cache_behavior = {
    target_origin_id       = "s3-assets"
    viewer_protocol_policy = "redirect-to-https"
  }

  custom_error_responses = [
    { error_code = 404, response_code = 200, response_page_path = "/index.html" },
    { error_code = 403, response_code = 200, response_page_path = "/index.html" },
  ]

  price_class = "PriceClass_100"

  tags = { Team = "frontend" }
}

output "distribution_id" { value = module.cdn.distribution_id }
output "domain_name"      { value = module.cdn.domain_name }
