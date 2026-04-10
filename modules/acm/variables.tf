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

variable "domain_name" {
  description = "Primary domain name for the certificate (e.g. 'app.example.com' or '*.example.com')."
  type        = string
}

variable "subject_alternative_names" {
  description = "Additional domain names to include in the certificate."
  type        = list(string)
  default     = []
}

variable "zone_id" {
  description = "Route 53 hosted zone ID for DNS validation record creation."
  type        = string
}

variable "create_wildcard" {
  description = "Automatically add '*.{domain_name}' as a SAN (for apex domains)."
  type        = bool
  default     = false
}

variable "wait_for_validation" {
  description = "Block until the certificate is validated and issued."
  type        = bool
  default     = true
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags."
}
