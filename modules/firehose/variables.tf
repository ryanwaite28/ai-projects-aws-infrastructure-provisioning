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

variable "stream_name" {
  description = "Short name. Full: {project}-{environment}-{region_short}-firehose-{stream_name}."
  type        = string
}

variable "source_kinesis_stream_arn" {
  description = "ARN of a Kinesis Data Stream as the source. If null, Direct PUT is used."
  type        = string
  default     = null
}

variable "destination" {
  description = "Firehose destination: s3 | redshift | opensearch | http_endpoint."
  type        = string
  default     = "s3"
}

variable "s3_bucket_arn" {
  description = "Destination S3 bucket ARN."
  type        = string
}

variable "s3_prefix" {
  description = "S3 object key prefix. Supports dynamic partitioning expressions."
  type        = string
  default     = "data/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/"
}

variable "s3_error_prefix" {
  description = "S3 key prefix for delivery errors."
  type        = string
  default     = "errors/!{firehose:error-output-type}/year=!{timestamp:yyyy}/month=!{timestamp:MM}/"
}

variable "buffering_size_mb" {
  description = "Buffer size in MB before delivery (1–128)."
  type        = number
  default     = 64
}

variable "buffering_interval_seconds" {
  description = "Buffer interval in seconds before delivery (60–900)."
  type        = number
  default     = 300
}

variable "s3_compression_format" {
  description = "Compression format for S3 delivery: UNCOMPRESSED | GZIP | ZIP | Snappy."
  type        = string
  default     = "GZIP"
}

variable "dynamic_partitioning_enabled" {
  description = "Enable dynamic partitioning (requires s3_prefix with partitioning expressions)."
  type        = bool
  default     = true
}

variable "transformation_lambda_arn" {
  description = "Lambda function ARN for record transformation. Null = no transformation."
  type        = string
  default     = null
}

variable "transformation_buffer_size_mb" {
  description = "Buffer size for Lambda transformation (1–3)."
  type        = number
  default     = 3
}

variable "transformation_buffer_interval_seconds" {
  description = "Buffer interval for Lambda transformation (60–900)."
  type        = number
  default     = 60
}

variable "kms_key_arn" {
  description = "KMS key ARN for server-side encryption."
  type        = string
  default     = null
}

variable "cloudwatch_logging_enabled" {
  description = "Enable CloudWatch error logging for delivery failures."
  type        = bool
  default     = true
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags."
}
