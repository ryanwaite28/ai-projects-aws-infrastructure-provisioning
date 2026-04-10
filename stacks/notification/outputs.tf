output "topic_arn"       { value = module.sns_topic.topic_arn }
output "topic_name"      { value = module.sns_topic.topic_name }
output "queue_arns"      { value = { for k, v in module.subscriber_queues : k => v.queue_arn } }
