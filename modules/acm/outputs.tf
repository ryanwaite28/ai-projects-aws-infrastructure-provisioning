output "certificate_arn" {
  value       = aws_acm_certificate.this.arn
  description = "ARN of the ACM certificate."
}

output "certificate_domain" {
  value       = aws_acm_certificate.this.domain_name
  description = "Primary domain name on the certificate."
}

output "certificate_status" {
  value       = aws_acm_certificate.this.status
  description = "Current validation status of the certificate."
}
