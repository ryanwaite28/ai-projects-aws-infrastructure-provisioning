output "event_bus_arn"       { value = module.event_bus.bus_arn }
output "event_bus_name"      { value = module.event_bus.bus_name }
output "consumer_lambda_arns" { value = { for k, v in module.consumer_lambdas : k => v.function_arn } }
