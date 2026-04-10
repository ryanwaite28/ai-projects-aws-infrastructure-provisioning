output "queue_url"        { value = module.sqs.queue_id }
output "dlq_url"          { value = module.sqs.dlq_id }
output "ecr_repo_url"     { value = module.ecr.repository_url }
output "ecs_service_name" { value = module.ecs_worker.service_name }
