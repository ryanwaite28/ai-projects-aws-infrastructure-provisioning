##
## Module: route53
## Creates or looks up a Route 53 hosted zone and manages DNS records.
##

locals {
  default_tags = merge({
    Project = var.project, Environment = var.environment, Region = var.region, ManagedBy = "terraform"
  }, var.tags)
}

data "aws_route53_zone" "existing" {
  count        = var.create_zone ? 0 : 1
  name         = var.zone_name
  private_zone = var.private_zone
}

resource "aws_route53_zone" "this" {
  count = var.create_zone ? 1 : 0
  name  = var.zone_name

  dynamic "vpc" {
    for_each = var.private_zone && var.vpc_id != null ? [1] : []
    content {
      vpc_id = var.vpc_id
    }
  }

  tags = merge(local.default_tags, { Name = var.zone_name })
}

locals {
  zone_id = var.create_zone ? aws_route53_zone.this[0].zone_id : data.aws_route53_zone.existing[0].zone_id
}

resource "aws_route53_record" "this" {
  for_each = var.records
  zone_id  = local.zone_id
  name     = each.value.name
  type     = each.value.type
  ttl      = each.value.alias == null ? each.value.ttl : null
  records  = each.value.alias == null ? each.value.records : null

  dynamic "alias" {
    for_each = each.value.alias != null ? [each.value.alias] : []
    content {
      name                   = alias.value.name
      zone_id                = alias.value.zone_id
      evaluate_target_health = alias.value.evaluate_target_health
    }
  }
}
