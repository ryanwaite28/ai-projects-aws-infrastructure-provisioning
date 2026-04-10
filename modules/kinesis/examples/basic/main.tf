module "events_stream" {
  source = "../../"

  project     = "myapp"
  environment = "dev"
  region      = "us-east-1"
  stream_name = "events"

  on_demand              = true
  retention_period_hours = 24

  tags = { Team = "platform" }
}

output "stream_arn"  { value = module.events_stream.stream_arn }
output "stream_name" { value = module.events_stream.stream_name }
