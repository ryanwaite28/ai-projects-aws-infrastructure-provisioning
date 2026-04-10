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

variable "alert_emails" {
  description = "Email addresses to subscribe to the SNS alert topic."
  type        = list(string)
  default     = []
}

variable "log_groups" {
  description = "Map of log group configurations to create. Key is the short name."
  type = map(object({
    name              = string
    retention_in_days = optional(number, 30)
    kms_key_arn       = optional(string, null)
  }))
  default = {}
}

variable "alarms" {
  description = "Map of CloudWatch alarm configurations."
  type = map(object({
    comparison_operator = string
    evaluation_periods  = number
    metric_name         = string
    namespace           = string
    period              = number
    statistic           = string
    threshold           = number
    alarm_description   = optional(string, "")
    dimensions          = optional(map(string), {})
    treat_missing_data  = optional(string, "notBreaching")
    alarm_actions       = optional(list(string), [])
    ok_actions          = optional(list(string), [])
    datapoints_to_alarm = optional(number, null)
  }))
  default = {}
}

variable "dashboard_name" {
  description = "Short name for the CloudWatch dashboard. Null = no dashboard."
  type        = string
  default     = null
}

variable "dashboard_body" {
  description = "CloudWatch dashboard JSON body."
  type        = string
  default     = null
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags."
}
