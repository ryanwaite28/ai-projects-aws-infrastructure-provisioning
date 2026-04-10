# Module: `ecr`

Creates an ECR repository with immutable tags, automated vulnerability scanning, lifecycle policies for image retention, KMS encryption, and optional cross-account pull access.

Full name pattern: `{project}/{environment}/{repository_name}`

## Usage

```hcl
module "api_repo" {
  source = "../../modules/ecr"

  project         = "myapp"
  environment     = "prod"
  region          = "us-east-1"
  repository_name = "api"

  image_tag_mutability = "IMMUTABLE"
  scan_on_push         = true
  keep_image_count     = 10
  untagged_expiry_days = 7
  kms_key_arn          = module.kms.key_arn

  tags = { Team = "platform" }
}
```

### Cross-account pull (ops → prod pattern)

```hcl
module "shared_repo" {
  source = "../../modules/ecr"
  # ...
  cross_account_pull_arns = [
    "arn:aws:iam::111122223333:root",   # prod account
    "arn:aws:iam::444455556666:root",   # staging account
  ]
}
```

> **Best practice:** Use `IMMUTABLE` tags in production to prevent tag overwrites. CI pipelines should push images with the git SHA as the tag and never reuse tags.

## Required Inputs

| Name | Type | Description |
|---|---|---|
| `project` | `string` | Project name prefix |
| `environment` | `string` | Deployment environment |
| `region` | `string` | AWS region |
| `repository_name` | `string` | Short repository name |

## Optional Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `image_tag_mutability` | `string` | `"IMMUTABLE"` | `MUTABLE` or `IMMUTABLE` |
| `scan_on_push` | `bool` | `true` | Enable automated vulnerability scanning |
| `keep_image_count` | `number` | `10` | Number of tagged images to retain |
| `untagged_expiry_days` | `number` | `7` | Days until untagged images are deleted |
| `kms_key_arn` | `string` | `null` | KMS key ARN (null = AES-256/AWS-managed) |
| `cross_account_pull_arns` | `list(string)` | `[]` | IAM principal ARNs from other accounts allowed to pull |
| `tags` | `map(string)` | `{}` | Additional resource tags |

## Outputs

| Name | Description |
|---|---|
| `repository_url` | Full repository URL (for docker push/pull and ECS task definitions) |
| `repository_arn` | Repository ARN |
| `repository_name` | Repository name |
| `registry_id` | AWS account ID of the ECR registry |
