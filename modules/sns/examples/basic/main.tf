module "notifications" {
  source = "../../"

  project     = "myapp"
  environment = "dev"
  region      = "us-east-1"
  topic_name  = "order-notifications"

  subscriptions = [
    {
      protocol             = "sqs"
      endpoint             = "arn:aws:sqs:us-east-1:123456789012:myapp-dev-use1-orders"
      raw_message_delivery = true
    }
  ]

  tags = { Team = "backend" }
}

output "topic_arn" { value = module.notifications.topic_arn }
