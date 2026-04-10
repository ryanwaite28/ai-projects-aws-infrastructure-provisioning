variable "project" {
  type        = string
  description = "Project name prefix."
}

variable "environment" {
  type        = string
  description = "Deployment environment."
}

variable "region" {
  type        = string
  description = "AWS region."
}

variable "topic_name" {
  description = "Short name for the SNS topic. Full name: {project}-{environment}-{region_short}-{topic_name}[.fifo]."
  type        = string
}

variable "fifo" {
  description = "Create a FIFO topic."
  type        = bool
  default     = false
}

variable "content_based_deduplication" {
  description = "Enable content-based deduplication (FIFO topics only)."
  type        = bool
  default     = false
}

variable "kms_key_arn" {
  description = "KMS key ARN for server-side encryption."
  type        = string
  default     = null
}

variable "subscriptions" {
  description = "List of subscription configurations."
  type = list(object({
    protocol               = string        # sqs | lambda | email | https | sms
    endpoint               = string        # ARN, URL, or email address
    filter_policy          = optional(string, null)   # JSON filter policy
    raw_message_delivery   = optional(bool, false)    # SQS/HTTP only
    redrive_policy_dlq_arn = optional(string, null)
  }))
  default = []
}

variable "topic_policy_statements" {
  description = "Additional IAM policy statements for the SNS topic resource policy."
  type        = any
  default     = []
}

variable "allowed_publisher_arns" {
  description = "IAM principal ARNs allowed to publish to this topic."
  type        = list(string)
  default     = []
}

variable "allowed_service_principals" {
  description = "AWS service principals allowed to publish (e.g. 'cloudwatch.amazonaws.com')."
  type        = list(string)
  default     = []
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags."
}
