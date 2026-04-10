module "events" {
  source = "../../"

  project     = "myapp"
  environment = "dev"
  region      = "us-east-1"
  bus_name    = "orders"

  rules = {
    order-placed = {
      description   = "Route order.placed events to processor Lambda"
      event_pattern = jsonencode({
        source      = ["myapp.orders"]
        detail-type = ["order.placed"]
      })
      targets = [
        {
          id  = "processor"
          arn = "arn:aws:lambda:us-east-1:123456789012:function:myapp-dev-use1-fn-order-processor"
        }
      ]
    }
  }

  tags = { Team = "backend" }
}

output "bus_arn"    { value = module.events.bus_arn }
output "rule_arns"  { value = module.events.rule_arns }
