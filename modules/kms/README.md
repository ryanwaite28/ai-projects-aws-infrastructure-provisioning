# Module: `kms`

Creates a customer-managed KMS key with alias, automatic rotation, and a key policy granting admin/usage permissions to specified principals and service principals.

Full name pattern (alias): `alias/{project}/{environment}/{alias}`

## Usage

```hcl
module "kms" {
  source = "../../modules/kms"

  project     = "myapp"
  environment = "prod"
  region      = "us-east-1"
  alias       = "main"
  description = "Primary encryption key for prod"

  enable_key_rotation = true

  admin_principal_arns = [
    "arn:aws:iam::123456789012:role/DevOpsRole",
  ]

  usage_principal_arns = [
    module.api_task_role.role_arn,
    module.worker_task_role.role_arn,
  ]

  service_principals = [
    "logs.amazonaws.com",
    "secretsmanager.amazonaws.com",
    "sns.amazonaws.com",
  ]

  tags = { Team = "platform" }
}
```

### Multi-region key

```hcl
module "primary_key" {
  source = "../../modules/kms"
  # ...
  multi_region = true   # can be replicated to other regions
}
```

## Required Inputs

| Name | Type | Description |
|---|---|---|
| `project` | `string` | Project name prefix |
| `environment` | `string` | Deployment environment |
| `region` | `string` | AWS region |
| `alias` | `string` | Key alias (without the `alias/` prefix) |

## Optional Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `description` | `string` | `"Customer managed key"` | Human-readable description |
| `deletion_window_in_days` | `number` | `30` | Days to wait before deletion (7–30) |
| `enable_key_rotation` | `bool` | `true` | Enable automatic annual rotation |
| `multi_region` | `bool` | `false` | Create a multi-region primary key |
| `admin_principal_arns` | `list(string)` | `[]` | Principals that can administer (manage) this key |
| `usage_principal_arns` | `list(string)` | `[]` | Principals that can use this key for encrypt/decrypt |
| `service_principals` | `list(string)` | `[]` | AWS service principals allowed to use this key |
| `tags` | `map(string)` | `{}` | Additional resource tags |

## Outputs

| Name | Description |
|---|---|
| `key_id` | Globally unique KMS key ID |
| `key_arn` | KMS key ARN |
| `alias_name` | Alias name (with the `alias/` prefix) |
| `alias_arn` | KMS alias ARN |
