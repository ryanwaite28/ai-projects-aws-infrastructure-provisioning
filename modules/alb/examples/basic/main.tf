# Requires a VPC, subnets, a security group, and an ACM certificate.
# Substitute with real resource IDs/ARNs.

module "alb" {
  source = "../../"

  project     = "myapp"
  environment = "dev"
  region      = "us-east-1"
  name        = "public"

  internal           = false
  vpc_id             = "vpc-0a1b2c3d4e5f"
  subnet_ids         = ["subnet-aaa", "subnet-bbb"]
  certificate_arn    = "arn:aws:acm:us-east-1:123456789012:certificate/abc123"

  target_groups = {
    api = {
      port        = 8080
      target_type = "ip"
      health_check = {
        path    = "/health"
        matcher = "200"
      }
    }
  }

  tags = { Team = "platform" }
}

output "alb_dns_name"       { value = module.alb.alb_dns_name }
output "target_group_arns"  { value = module.alb.target_group_arns }
