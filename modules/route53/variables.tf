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

variable "zone_name" {
  description = "DNS zone name (e.g. 'example.com'). Used to look up or create the hosted zone."
  type        = string
}

variable "create_zone" {
  description = "Create a new Route 53 hosted zone. If false, looks up an existing zone by zone_name."
  type        = bool
  default     = false
}

variable "private_zone" {
  description = "Create a private hosted zone (requires vpc_id)."
  type        = bool
  default     = false
}

variable "vpc_id" {
  description = "VPC ID for private hosted zones."
  type        = string
  default     = null
}

variable "records" {
  description = "Map of DNS records to create. Key is a short identifier."
  type = map(object({
    name    = string
    type    = string # A | AAAA | CNAME | TXT | MX | NS
    ttl     = optional(number, 300)
    records = optional(list(string), null)  # For non-alias records
    alias = optional(object({
      name                   = string
      zone_id                = string
      evaluate_target_health = optional(bool, true)
    }), null)
  }))
  default = {}
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags."
}
