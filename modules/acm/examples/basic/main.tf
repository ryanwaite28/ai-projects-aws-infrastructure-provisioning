# Assumes an existing Route 53 hosted zone for the domain.
# ACM certificates for CloudFront must be created in us-east-1.

module "cert" {
  source = "../../"

  project     = "myapp"
  environment = "dev"
  region      = "us-east-1"

  domain_name               = "dev.example.com"
  subject_alternative_names = ["api.dev.example.com"]
  zone_id                   = "Z1234567890ABCDEFGHIJ"  # your hosted zone ID
  create_wildcard           = false
  wait_for_validation       = true

  tags = { Team = "platform" }
}

output "certificate_arn"    { value = module.cert.certificate_arn }
output "certificate_status" { value = module.cert.certificate_status }
