# Module: `s3`

Creates an S3 bucket with encryption, public-access block, versioning, lifecycle rules, optional cross-region replication, CORS, object lock, and access logging.

Full name pattern: `{project}-{environment}-{region_short}-{bucket_suffix}`

## Usage

```hcl
module "uploads" {
  source = "../../modules/s3"

  project       = "myapp"
  environment   = "prod"
  region        = "us-east-1"
  bucket_suffix = "uploads"

  versioning_enabled = true
  kms_key_arn        = module.kms.key_arn

  lifecycle_rules = [
    {
      id                    = "expire-old-versions"
      enabled               = true
      prefix                = ""
      transition_days       = 30
      transition_storage_class = "STANDARD_IA"
      glacier_transition_days  = 90
      noncurrent_version_expiration_days = 30
    }
  ]

  tags = { Team = "backend" }
}
```

### Static assets with CORS

```hcl
module "assets" {
  source = "../../modules/s3"
  # ...
  cors_rules = [
    {
      allowed_methods = ["GET"]
      allowed_origins = ["https://app.example.com"]
      expose_headers  = ["ETag"]
    }
  ]
}
```

### Cross-region replication

```hcl
module "primary_bucket" {
  source = "../../modules/s3"
  # ...
  versioning_enabled                   = true
  replication_enabled                  = true
  replication_destination_bucket_arn   = module.replica_bucket.bucket_arn
  replication_destination_kms_key_arn  = module.kms_west.key_arn
}
```

## Required Inputs

| Name | Type | Description |
|---|---|---|
| `project` | `string` | Project name prefix |
| `environment` | `string` | Deployment environment |
| `region` | `string` | AWS region |
| `bucket_suffix` | `string` | Short suffix (e.g. `assets`, `uploads`, `logs`) |

## Optional Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `versioning_enabled` | `bool` | `false` | Enable S3 versioning |
| `force_destroy` | `bool` | `false` | Allow Terraform to delete non-empty bucket |
| `kms_key_arn` | `string` | `null` | KMS key ARN for SSE-KMS (null = SSE-S3/AES-256) |
| `lifecycle_rules` | `list(object)` | `[]` | Lifecycle rule configurations |
| `replication_enabled` | `bool` | `false` | Enable cross-region replication |
| `replication_destination_bucket_arn` | `string` | `null` | Destination bucket ARN for replication |
| `replication_destination_kms_key_arn` | `string` | `null` | KMS key in destination region |
| `cors_rules` | `list(object)` | `[]` | CORS rule configurations |
| `bucket_policy_json` | `string` | `null` | Additional bucket policy JSON |
| `object_lock_enabled` | `bool` | `false` | Enable Object Lock (WORM). Irreversible after creation |
| `access_log_bucket_id` | `string` | `null` | Bucket ID for server access logs |
| `tags` | `map(string)` | `{}` | Additional resource tags |

## Outputs

| Name | Description |
|---|---|
| `bucket_id` | Bucket name/ID |
| `bucket_arn` | Bucket ARN |
| `bucket_domain_name` | Regional domain name (use as CloudFront origin) |
| `bucket_regional_domain_name` | Regional domain name |
| `replication_role_arn` | Replication IAM role ARN (null if disabled) |
