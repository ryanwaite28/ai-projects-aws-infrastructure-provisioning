# EFS file system with mount targets in two AZs.
# Substitute real VPC/subnet/security group IDs.

module "shared_fs" {
  source = "../../"

  project     = "myapp"
  environment = "dev"
  region      = "us-east-1"
  name        = "uploads"

  subnet_ids                 = ["subnet-aaa", "subnet-bbb"]
  vpc_id                     = "vpc-0a1b2c3d4e5f"
  allowed_security_group_ids = ["sg-0a1b2c3d4e"]

  throughput_mode = "elastic"
  enable_backup   = false  # enable in prod

  access_points = {
    api = {
      root_directory_path = "/uploads"
    }
  }

  tags = { Team = "backend" }
}

output "file_system_id"    { value = module.shared_fs.file_system_id }
output "dns_name"          { value = module.shared_fs.dns_name }
output "access_point_ids"  { value = module.shared_fs.access_point_ids }
