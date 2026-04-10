module "order_events" {
  source = "../../"

  project     = "myapp"
  environment = "dev"
  region      = "us-east-1"
  bus_name    = "orders"

  consumers = {
    processor = {
      runtime     = "python3.12"
      handler     = "handler.process"
      memory_size = 256
      timeout     = 30
      environment_variables = {
        LOG_LEVEL = "DEBUG"
      }
    }
  }

  event_rules = {
    order-placed = {
      description   = "Route order.placed events to processor"
      event_pattern = jsonencode({
        source      = ["myapp.orders"]
        detail-type = ["order.placed"]
      })
      targets = [
        # ARN will be wired after first apply — use a placeholder or
        # reference module.order_events.consumer_lambda_arns["processor"]
        # in a subsequent apply.
      ]
    }
  }

  tags = { Team = "backend" }
}

output "event_bus_arn"        { value = module.order_events.event_bus_arn }
output "consumer_lambda_arns" { value = module.order_events.consumer_lambda_arns }
