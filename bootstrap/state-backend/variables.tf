variable "project" {
  type        = string
  description = "Project name for tagging"
}

variable "region" {
  type        = string
  description = "AWS region to create resources in"
}

variable "bucket_name" {
  type        = string
  description = "S3 bucket name for Terraform state (globally unique)"
}

variable "lock_table_name" {
  type        = string
  description = "DynamoDB table name for state locking"
}

variable "tags" {
  type    = map(string)
  default = {}
}
