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
  description = "Short name for this frontend deployment."
}

variable "domain_name" {
  type        = string
  description = "Full domain name (e.g. app.example.com)."
}

variable "subject_alternative_names" {
  type    = list(string)
  default = []
}

variable "zone_name" {
  type        = string
  description = "Route 53 zone apex (e.g. example.com)."
}

variable "zone_id" {
  type        = string
  description = "Route 53 hosted zone ID."
}

variable "price_class" {
  type    = string
  default = "PriceClass_100"
}

variable "tags" {
  type    = map(string)
  default = {}
}
