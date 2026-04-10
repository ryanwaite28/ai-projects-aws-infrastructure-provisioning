# Module: `efs`

Creates an EFS file system with mount targets, a managed security group, access points, lifecycle policies, and optional AWS Backup.

Full name pattern: `{project}-{environment}-{region_short}-efs-{name}`

## Usage

```hcl
module "shared_fs" {
  source = "../../modules/efs"

  project     = "myapp"
  environment = "prod"
  region      = "us-east-1"
  name        = "uploads"

  subnet_ids                 = module.network.private_subnet_ids
  vpc_id                     = module.network.vpc_id
  allowed_security_group_ids = [module.api.service_security_group_id]

  throughput_mode = "elastic"
  kms_key_arn     = module.kms.key_arn
  enable_backup   = true

  access_points = {
    api = {
      root_directory_path = "/uploads"
      posix_user_uid      = 1000
      posix_user_gid      = 1000
    }
  }

  tags = { Team = "platform" }
}
```

## Required Inputs

| Name | Type | Description |
|---|---|---|
| `project` | `string` | Project name prefix |
| `environment` | `string` | Deployment environment |
| `region` | `string` | AWS region |
| `name` | `string` | Short name for the file system |
| `subnet_ids` | `list(string)` | Subnet IDs for mount targets (one per AZ) |
| `vpc_id` | `string` | VPC ID for the EFS security group |
| `allowed_security_group_ids` | `list(string)` | Security groups allowed NFS access (port 2049) |

## Optional Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `performance_mode` | `string` | `"generalPurpose"` | `generalPurpose` or `maxIO` |
| `throughput_mode` | `string` | `"elastic"` | `bursting`, `provisioned`, or `elastic` |
| `provisioned_throughput_mibps` | `number` | `null` | MiB/s when `throughput_mode = "provisioned"` |
| `kms_key_arn` | `string` | `null` | KMS key ARN for encryption at rest |
| `lifecycle_policy` | `object` | AFTER_30_DAYS IA | EFS lifecycle transition policies |
| `access_points` | `map(object)` | `{}` | EFS access point configurations |
| `enable_backup` | `bool` | `true` | Enable AWS Backup for the file system |
| `tags` | `map(string)` | `{}` | Additional resource tags |

## Outputs

| Name | Description |
|---|---|
| `file_system_id` | EFS file system ID |
| `file_system_arn` | EFS file system ARN |
| `dns_name` | DNS name for mount targets |
| `security_group_id` | Security group ID for NFS access |
| `mount_target_ids` | IDs of the mount targets |
| `access_point_ids` | Map of access point key to ID |
| `access_point_arns` | Map of access point key to ARN |
