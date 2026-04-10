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

variable "bus_name" {
  description = "Short name. Full: {project}-{environment}-{region_short}-bus-{bus_name}. Use 'default' to use the default event bus."
  type        = string
  default     = "main"
}

variable "use_default_bus" {
  description = "Use the account's default event bus instead of creating a custom one."
  type        = bool
  default     = false
}

variable "kms_key_arn" {
  description = "KMS key ARN for event bus encryption."
  type        = string
  default     = null
}

variable "rules" {
  description = "Map of EventBridge rule configurations. Key is the rule short name."
  type = map(object({
    description         = optional(string, "")
    schedule_expression = optional(string, null)   # rate(5 minutes) | cron(0 12 * * ? *)
    event_pattern       = optional(string, null)   # JSON event pattern string
    state               = optional(string, "ENABLED")
    targets = list(object({
      id                 = string
      arn                = string
      role_arn           = optional(string, null)
      input              = optional(string, null)  # static JSON input
      input_path         = optional(string, null)  # JSONPath to extract from event
      dead_letter_arn    = optional(string, null)
      ecs_target = optional(object({
        task_definition_arn     = string
        cluster_arn             = string
        launch_type             = optional(string, "FARGATE")
        task_count              = optional(number, 1)
        subnet_ids              = optional(list(string), [])
        security_group_ids      = optional(list(string), [])
        assign_public_ip        = optional(bool, false)
      }), null)
    }))
  }))
  default = {}
}

variable "allowed_publisher_arns" {
  description = "IAM principal ARNs allowed to put events onto this bus."
  type        = list(string)
  default     = []
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags."
}
