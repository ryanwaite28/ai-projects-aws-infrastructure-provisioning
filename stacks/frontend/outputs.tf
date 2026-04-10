output "s3_bucket_name"          { value = module.s3_site.bucket_id }
output "s3_bucket_arn"           { value = module.s3_site.bucket_arn }
output "cloudfront_distribution_id" { value = module.cloudfront.distribution_id }
output "cloudfront_domain_name"  { value = module.cloudfront.domain_name }
output "acm_certificate_arn"     { value = module.acm_us_east_1.certificate_arn }
