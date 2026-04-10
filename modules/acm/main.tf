##
## Module: acm
## Creates an ACM certificate with Route 53 DNS validation.
## Call this module twice (with a provider alias for us-east-1) when you need
## both a regional cert (ALB) and a CloudFront cert (must be in us-east-1).
##

locals {
  region_short = {
    "us-east-1" = "use1", "us-east-2" = "use2", "us-west-1" = "usw1", "us-west-2" = "usw2",
    "eu-west-1" = "euw1", "eu-west-2" = "euw2", "eu-central-1" = "euc1",
    "ap-southeast-1" = "apse1", "ap-southeast-2" = "apse2", "ap-northeast-1" = "apne1"
  }
  rs = lookup(local.region_short, var.region, replace(var.region, "-", ""))

  all_sans = concat(
    var.subject_alternative_names,
    var.create_wildcard ? ["*.${var.domain_name}"] : []
  )

  default_tags = merge({
    Project = var.project, Environment = var.environment, Region = var.region, ManagedBy = "terraform"
  }, var.tags)
}

resource "aws_acm_certificate" "this" {
  domain_name               = var.domain_name
  subject_alternative_names = local.all_sans
  validation_method         = "DNS"
  tags                      = merge(local.default_tags, { Name = "${var.project}-${var.environment}-${local.rs}-cert-${replace(var.domain_name, "*.", "wildcard.")}" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "validation" {
  for_each = {
    for dvo in aws_acm_certificate.this.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }

  zone_id         = var.zone_id
  name            = each.value.name
  type            = each.value.type
  records         = [each.value.record]
  ttl             = 60
  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "this" {
  count                   = var.wait_for_validation ? 1 : 0
  certificate_arn         = aws_acm_certificate.this.arn
  validation_record_fqdns = [for record in aws_route53_record.validation : record.fqdn]
}
