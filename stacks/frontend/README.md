# Stack: `frontend`

Deploys a production-ready static frontend: S3 origin + CloudFront CDN + ACM TLS certificate (us-east-1) + Route 53 alias record. Suitable for SPAs, static sites, and marketing pages.

## What it creates

- S3 bucket (origin, private — no public access, served via CloudFront OAC)
- CloudFront distribution (HTTPS only, gzip + brotli compression, SPA-friendly custom error rules)
- ACM certificate in `us-east-1` (required by CloudFront) with DNS validation
- Route 53 alias record pointing the domain to the CloudFront distribution

## Usage

```hcl
module "frontend" {
  source = "../../stacks/frontend"

  project     = "myapp"
  environment = "prod"
  region      = "us-east-1"

  name        = "dashboard"
  domain_name = "app.example.com"
  zone_name   = "example.com"
  zone_id     = "Z1234567890ABC"

  price_class = "PriceClass_100"   # US, Canada, Europe

  tags = { Team = "frontend" }
}
```

## Required Inputs

| Name | Type | Description |
|---|---|---|
| `project` | `string` | Project name prefix |
| `environment` | `string` | Deployment environment |
| `region` | `string` | AWS region (used for resource naming; ACM cert is always created in us-east-1) |
| `name` | `string` | Short name for this frontend deployment |
| `domain_name` | `string` | Full domain name (e.g. `app.example.com`) |
| `zone_name` | `string` | Route 53 zone apex (e.g. `example.com`) |
| `zone_id` | `string` | Route 53 hosted zone ID |

## Optional Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `subject_alternative_names` | `list(string)` | `[]` | Additional SANs for the ACM certificate |
| `price_class` | `string` | `"PriceClass_100"` | CloudFront price class (`PriceClass_100`, `PriceClass_200`, `PriceClass_All`) |
| `tags` | `map(string)` | `{}` | Additional resource tags |

## Outputs

| Name | Description |
|---|---|
| `s3_bucket_name` | S3 origin bucket name — deploy assets here |
| `s3_bucket_arn` | S3 origin bucket ARN |
| `cloudfront_distribution_id` | CloudFront distribution ID — used for cache invalidation |
| `cloudfront_domain_name` | CloudFront-assigned domain (e.g. `d1abc.cloudfront.net`) |
| `acm_certificate_arn` | ACM certificate ARN (in us-east-1) |

## Deployment pattern

After `terraform apply`, upload your build artifacts to the S3 bucket and invalidate the CloudFront cache:

```bash
aws s3 sync ./dist s3://<s3_bucket_name>/ --delete
aws cloudfront create-invalidation \
  --distribution-id <cloudfront_distribution_id> \
  --paths "/*"
```

## Notes

- ACM certificate DNS validation creates CNAME records in the specified Route 53 zone automatically. Allow up to 5 minutes for validation to complete on first apply.
- The S3 bucket is fully private. Only CloudFront (via Origin Access Control) can read from it.
- CloudFront is configured with a default root object of `index.html` and custom error responses returning `index.html` with HTTP 200 — standard SPA routing behaviour.
- `PriceClass_100` covers US, Canada, and Europe. Use `PriceClass_All` for global distribution.
