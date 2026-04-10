output "distribution_id" {
  value       = aws_cloudfront_distribution.this.id
  description = "CloudFront distribution ID."
}

output "distribution_arn" {
  value       = aws_cloudfront_distribution.this.arn
  description = "CloudFront distribution ARN."
}

output "domain_name" {
  value       = aws_cloudfront_distribution.this.domain_name
  description = "CloudFront domain name (e.g. d111111abcdef8.cloudfront.net)."
}

output "hosted_zone_id" {
  value       = aws_cloudfront_distribution.this.hosted_zone_id
  description = "Route 53 hosted zone ID for alias records."
}

output "oac_ids" {
  value       = { for k, v in aws_cloudfront_origin_access_control.s3 : k => v.id }
  description = "Map of origin key to OAC ID."
}
