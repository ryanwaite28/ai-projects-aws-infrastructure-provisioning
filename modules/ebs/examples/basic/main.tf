module "data_volume" {
  source = "../../"

  project           = "myapp"
  environment       = "dev"
  region            = "us-east-1"
  volume_name       = "app-data"
  availability_zone = "us-east-1a"

  size_gb     = 20
  volume_type = "gp3"

  tags = { Team = "backend" }
}

output "volume_id" { value = module.data_volume.volume_id }
