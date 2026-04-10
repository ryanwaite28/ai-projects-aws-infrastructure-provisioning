variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "region" {
  type = string
}

variable "name" {
  type        = string
  description = "Short identifier for this webhook endpoint (e.g. 'stripe', 'github', 'events')."
}

# ── API Gateway ───────────────────────────────────────────────────────────────

variable "stage_name" {
  type        = string
  default     = "v1"
  description = "REST API stage name."
}

variable "throttling_rate_limit" {
  type        = number
  default     = 100
  description = "Steady-state request rate limit (requests/second) on the stage."
}

variable "throttling_burst_limit" {
  type        = number
  default     = 200
  description = "Burst request rate limit on the stage."
}

variable "api_key_required" {
  type        = bool
  default     = false
  description = "Require an x-api-key header on the webhook endpoint."
}

variable "waf_acl_arn" {
  type        = string
  default     = null
  description = "WAFv2 Web ACL ARN to associate with the API stage. Optional."
}

variable "custom_domain_name" {
  type        = string
  default     = null
  description = "Custom domain name (e.g. hooks.example.com). Requires custom_domain_certificate_arn."
}

variable "custom_domain_certificate_arn" {
  type        = string
  default     = null
  description = "ACM certificate ARN (must be in the same region) for the custom domain."
}

variable "log_retention_days" {
  type        = number
  default     = 30
}

# ── SQS ───────────────────────────────────────────────────────────────────────

variable "sqs_visibility_timeout_seconds" {
  type        = number
  default     = 300
  description = "SQS visibility timeout. Should be >= 6× the processor Lambda timeout."
}

variable "sqs_message_retention_seconds" {
  type        = number
  default     = 1209600 # 14 days
}

variable "dlq_max_receive_count" {
  type        = number
  default     = 3
  description = "Number of receive attempts before a message is moved to the DLQ."
}

# ── Processor Lambda ──────────────────────────────────────────────────────────

variable "processor_runtime" {
  type        = string
  default     = "python3.12"
  description = "Lambda runtime identifier (e.g. python3.12, nodejs20.x, java21)."
}

variable "processor_handler" {
  type        = string
  default     = "handler.process"
  description = "Lambda handler entrypoint (e.g. handler.process)."
}

variable "processor_s3_bucket" {
  type        = string
  default     = null
  description = "S3 bucket containing the deployment package. Set after initial deploy."
}

variable "processor_s3_key" {
  type        = string
  default     = null
  description = "S3 key of the deployment package."
}

variable "processor_memory_size" {
  type        = number
  default     = 512
}

variable "processor_timeout" {
  type        = number
  default     = 60
  description = "Processor Lambda timeout in seconds. Keep well below sqs_visibility_timeout / 6."
}

variable "processor_reserved_concurrency" {
  type        = number
  default     = -1
  description = "Reserved concurrency for the processor. -1 = unreserved."
}

variable "processor_sqs_batch_size" {
  type        = number
  default     = 10
  description = "Number of SQS messages per Lambda invocation (1–10000)."
}

variable "processor_sqs_max_batching_window" {
  type        = number
  default     = 5
  description = "Seconds Lambda waits to accumulate messages before invoking (0–300)."
}

variable "processor_environment_variables" {
  type    = map(string)
  default = {}
}

# ── Shared ────────────────────────────────────────────────────────────────────

variable "kms_key_arn" {
  type        = string
  default     = null
  description = "KMS key ARN for SQS encryption and Lambda environment variable encryption."
}

variable "vpc_config" {
  type = object({
    subnet_ids         = list(string)
    security_group_ids = list(string)
  })
  default     = null
  description = "Deploy the processor Lambda into a VPC. Optional."
}

variable "tags" {
  type    = map(string)
  default = {}
}
