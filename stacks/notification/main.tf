##
## Stack: notification
## SNS fan-out → SQS queues + Lambda subscribers.
##

terraform {
  required_version = ">= 1.7.0"
  required_providers { aws = { source = "hashicorp/aws", version = ">= 5.0" } }
}

provider "aws" { region = var.region }

# Create one SQS queue per subscriber domain
module "subscriber_queues" {
  for_each    = var.sqs_subscribers
  source      = "../../modules/sqs"
  project     = var.project
  environment = var.environment
  region      = var.region
  queue_name  = "${var.topic_name}-${each.key}"
  dlq_enabled = true
  kms_key_arn = var.kms_key_arn
  tags        = var.tags
}

module "sns_topic" {
  source      = "../../modules/sns"
  project     = var.project
  environment = var.environment
  region      = var.region
  topic_name  = var.topic_name
  kms_key_arn = var.kms_key_arn
  allowed_publisher_arns = var.allowed_publisher_arns
  subscriptions = concat(
    [for k, q in module.subscriber_queues : {
      protocol             = "sqs"
      endpoint             = q.queue_arn
      raw_message_delivery = true
    }],
    [for arn in var.lambda_subscriber_arns : { protocol = "lambda", endpoint = arn }],
    [for email in var.email_subscribers : { protocol = "email", endpoint = email }]
  )
  tags = var.tags
}

# Allow SNS to write to each SQS subscriber
resource "aws_sqs_queue_policy" "sns_publish" {
  for_each  = module.subscriber_queues
  queue_url = each.value.queue_id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "sns.amazonaws.com" }
      Action    = "sqs:SendMessage"
      Resource  = each.value.queue_arn
      Condition = { ArnEquals = { "aws:SourceArn" = module.sns_topic.topic_arn } }
    }]
  })
}
