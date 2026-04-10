module "orders_queue" {
  source = "../../"

  project    = "myapp"
  environment = "dev"
  region     = "us-east-1"
  queue_name = "orders"

  visibility_timeout_seconds = 300
  message_retention_seconds  = 86400
  create_dlq                 = true
  max_receive_count          = 3

  tags = { Team = "backend" }
}

output "queue_url" { value = module.orders_queue.queue_url }
output "queue_arn" { value = module.orders_queue.queue_arn }
output "dlq_arn"   { value = module.orders_queue.dlq_arn }
