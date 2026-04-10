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

variable "function_name" {
  description = "Short name for the function. Full name: {project}-{environment}-{region_short}-fn-{function_name}."
  type        = string
}

variable "description" {
  description = "Human-readable description of the Lambda function."
  type        = string
  default     = ""
}

variable "package_type" {
  description = "Lambda deployment package type: Zip or Image."
  type        = string
  default     = "Zip"
  validation {
    condition     = contains(["Zip", "Image"], var.package_type)
    error_message = "package_type must be Zip or Image."
  }
}

variable "runtime" {
  description = "Lambda runtime identifier (e.g. python3.12, nodejs20.x, java21). Required for Zip packages."
  type        = string
  default     = null
}

variable "handler" {
  description = "Function handler entrypoint (e.g. index.handler). Required for Zip packages."
  type        = string
  default     = null
}

variable "filename" {
  description = "Path to the deployment ZIP file. Mutually exclusive with s3_bucket/image_uri."
  type        = string
  default     = null
}

variable "s3_bucket" {
  description = "S3 bucket containing the deployment ZIP. Mutually exclusive with filename."
  type        = string
  default     = null
}

variable "s3_key" {
  description = "S3 key of the deployment ZIP."
  type        = string
  default     = null
}

variable "image_uri" {
  description = "ECR image URI for container image deployments."
  type        = string
  default     = null
}

variable "memory_size" {
  description = "Memory allocated to the function in MiB (128–10240)."
  type        = number
  default     = 512
}

variable "timeout" {
  description = "Function timeout in seconds (max 900)."
  type        = number
  default     = 30
}

variable "reserved_concurrent_executions" {
  description = "Reserved concurrency for this function. -1 = unreserved, 0 = throttled."
  type        = number
  default     = -1
}

variable "environment_variables" {
  description = "Map of environment variables for the function."
  type        = map(string)
  default     = {}
}

variable "kms_key_arn" {
  description = "KMS key ARN to encrypt environment variables."
  type        = string
  default     = null
}

variable "execution_role_arn" {
  description = "ARN of an existing IAM role to use as the Lambda execution role. If null, a default role is created."
  type        = string
  default     = null
}

variable "execution_role_extra_policies" {
  description = "Map of extra inline policy name → JSON to attach to the auto-created execution role."
  type        = map(string)
  default     = {}
}

variable "vpc_config" {
  description = "VPC configuration. When set, deploys Lambda into the VPC."
  type = object({
    subnet_ids         = list(string)
    security_group_ids = list(string)
  })
  default = null
}

variable "layers" {
  description = "List of Lambda layer ARNs to attach (max 5)."
  type        = list(string)
  default     = []
}

variable "architectures" {
  description = "Instruction set architecture: x86_64 or arm64."
  type        = list(string)
  default     = ["x86_64"]
}

variable "sqs_event_source_arns" {
  description = "List of SQS queue ARNs to use as event sources."
  type        = list(string)
  default     = []
}

variable "sqs_batch_size" {
  description = "Batch size for SQS event source mappings."
  type        = number
  default     = 10
}

variable "sqs_maximum_batching_window_seconds" {
  description = "Maximum batching window in seconds for SQS event sources."
  type        = number
  default     = 0
}

variable "log_retention_days" {
  description = "CloudWatch log group retention in days."
  type        = number
  default     = 30
}

variable "publish_version" {
  description = "Publish a new Lambda version on every deployment."
  type        = bool
  default     = false
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags."
}
