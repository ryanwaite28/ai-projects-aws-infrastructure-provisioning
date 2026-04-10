##
## Stack: frontend
## S3 + CloudFront + OAC + WAF + ACM + Route53 for SPA/static hosting.
##

terraform {
  required_version = ">= 1.7.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
      configuration_aliases = [aws.us_east_1]
    }
  }
}

provider "aws"           { region = var.region }
provider "aws" "us_east_1" { region = "us-east-1" }

module "s3_site" {
  source        = "../../modules/s3"
  project       = var.project
  environment   = var.environment
  region        = var.region
  bucket_suffix = "${var.name}-site"
  versioning_enabled = false
  tags          = var.tags
}

module "acm_us_east_1" {
  source      = "../../modules/acm"
  project     = var.project
  environment = var.environment
  region      = "us-east-1"
  domain_name = var.domain_name
  subject_alternative_names = var.subject_alternative_names
  zone_id     = var.zone_id
  tags        = var.tags
  providers   = { aws = aws.us_east_1 }
}

module "waf_us_east_1" {
  source      = "../../modules/waf"
  project     = var.project
  environment = var.environment
  region      = "us-east-1"
  name        = "${var.name}-cf"
  scope       = "CLOUDFRONT"
  tags        = var.tags
  providers   = { aws = aws.us_east_1 }
}

module "cloudfront" {
  source  = "../../modules/cloudfront"
  project = var.project
  environment = var.environment
  region  = var.region
  name    = var.name
  aliases = [var.domain_name]
  acm_certificate_arn = module.acm_us_east_1.certificate_arn
  waf_web_acl_id      = module.waf_us_east_1.web_acl_arn
  price_class         = var.price_class

  origins = {
    s3 = {
      domain_name  = module.s3_site.bucket_domain_name
      origin_id    = "s3-site"
      s3_oac_enabled = true
    }
  }

  default_cache_behavior = {
    target_origin_id = "s3-site"
    compress         = true
  }

  custom_error_responses = [
    { error_code = 404, response_code = 200, response_page_path = "/index.html" },
    { error_code = 403, response_code = 200, response_page_path = "/index.html" },
  ]

  tags = var.tags
}

# Grant CloudFront OAC permission to read from S3
resource "aws_s3_bucket_policy" "oac" {
  bucket = module.s3_site.bucket_id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AllowCloudFrontOAC"
      Effect = "Allow"
      Principal = { Service = "cloudfront.amazonaws.com" }
      Action   = "s3:GetObject"
      Resource = "${module.s3_site.bucket_arn}/*"
      Condition = { StringEquals = { "AWS:SourceArn" = module.cloudfront.distribution_arn } }
    }]
  })
}

module "route53" {
  source      = "../../modules/route53"
  project     = var.project
  environment = var.environment
  region      = var.region
  zone_name   = var.zone_name
  records = {
    site = {
      name = var.domain_name
      type = "A"
      alias = {
        name    = module.cloudfront.domain_name
        zone_id = module.cloudfront.hosted_zone_id
      }
    }
  }
  tags = var.tags
}
