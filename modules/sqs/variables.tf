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

variable "queue_name" {
  description = "Short name for the queue. Full name: {project}-{environment}-{region_short}-{queue_name}[.fifo]."
  type        = string
}

variable "fifo" {
  description = "Create a FIFO queue instead of a standard queue."
  type        = bool
  default     = false
}

variable "content_based_deduplication" {
  description = "Enable content-based deduplication (FIFO queues only)."
  type        = bool
  default     = true
}

variable "visibility_timeout_seconds" {
  description = "Visibility timeout for messages (seconds). Should be >= your consumer's processing time."
  type        = number
  default     = 30
}

variable "message_retention_seconds" {
  description = "Duration (seconds) that SQS retains a message. Max 1209600 (14 days)."
  type        = number
  default     = 345600 # 4 days
}

variable "max_message_size" {
  description = "Maximum message size in bytes (1024–262144)."
  type        = number
  default     = 262144
}

variable "delay_seconds" {
  description = "Delay in seconds before messages are available to consumers."
  type        = number
  default     = 0
}

variable "receive_wait_time_seconds" {
  description = "Long-poll wait time in seconds (0 = short polling, 1–20 = long polling)."
  type        = number
  default     = 20
}

variable "dlq_enabled" {
  description = "Create a dead-letter queue and configure a redrive policy."
  type        = bool
  default     = true
}

variable "max_receive_count" {
  description = "Number of times a message is received before being moved to the DLQ."
  type        = number
  default     = 5
}

variable "kms_key_arn" {
  description = "KMS key ARN for server-side encryption. Null uses SQS-managed keys."
  type        = string
  default     = null
}

variable "queue_policy_json" {
  description = "Additional queue policy JSON. Merged with allow-service statements."
  type        = string
  default     = null
}

variable "allowed_publisher_arns" {
  description = "List of IAM principal ARNs allowed to send messages (e.g. SNS topic ARNs, EventBridge ARNs)."
  type        = list(string)
  default     = []
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags."
}
