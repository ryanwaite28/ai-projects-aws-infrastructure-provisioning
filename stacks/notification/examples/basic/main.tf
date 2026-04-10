module "order_notifications" {
  source = "../../"

  project     = "myapp"
  environment = "dev"
  region      = "us-east-1"
  topic_name  = "order-events"

  sqs_subscribers = {
    fulfillment = {}
    analytics   = {}
  }

  email_subscribers = ["dev-team@example.com"]

  tags = { Team = "platform" }
}

output "topic_arn"   { value = module.order_notifications.topic_arn }
output "queue_arns"  { value = module.order_notifications.queue_arns }
