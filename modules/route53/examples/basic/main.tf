# Looks up an existing hosted zone and creates A alias + CNAME records.
# Replace zone_name, alb_dns_name, and alb_zone_id with real values.

module "dns" {
  source = "../../"

  project     = "myapp"
  environment = "dev"
  region      = "us-east-1"
  zone_name   = "example.com"
  create_zone = false

  records = {
    app = {
      name = "dev.example.com"
      type = "A"
      alias = {
        name    = "my-alb-123456.us-east-1.elb.amazonaws.com"
        zone_id = "Z35SXDOTRQ7X7K"
      }
    }
  }

  tags = { Team = "platform" }
}

output "zone_id"      { value = module.dns.zone_id }
output "record_fqdns" { value = module.dns.record_fqdns }
