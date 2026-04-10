# Module: `ebs`

Creates an EBS volume with encryption, optional provisioned IOPS/throughput, and snapshot restore support.

Full name pattern: `{project}-{environment}-{region_short}-ebs-{volume_name}`

## Usage

```hcl
module "data_volume" {
  source = "../../modules/ebs"

  project           = "myapp"
  environment       = "prod"
  region            = "us-east-1"
  volume_name       = "postgres-data"
  availability_zone = "us-east-1a"

  size_gb     = 500
  volume_type = "gp3"
  kms_key_arn = module.kms.key_arn

  tags = { Team = "data" }
}
```

### High-performance io2 volume

```hcl
module "iops_volume" {
  source = "../../modules/ebs"
  # ...
  volume_type = "io2"
  size_gb     = 1000
  iops        = 32000
}
```

> **Note:** EBS volumes must be in the same AZ as the EC2 instance they attach to. Use `availability_zone` carefully.

## Required Inputs

| Name | Type | Description |
|---|---|---|
| `project` | `string` | Project name prefix |
| `environment` | `string` | Deployment environment |
| `region` | `string` | AWS region |
| `volume_name` | `string` | Short name for the volume |
| `availability_zone` | `string` | AZ where the volume is created |

## Optional Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `size_gb` | `number` | `20` | Volume size in GiB |
| `volume_type` | `string` | `"gp3"` | `gp3`, `gp2`, `io2`, `io1`, `st1`, `sc1` |
| `iops` | `number` | `null` | Provisioned IOPS. Required for io1/io2; optional for gp3 |
| `throughput` | `number` | `null` | Throughput in MiB/s for gp3 (125–1000) |
| `kms_key_arn` | `string` | `null` | KMS key ARN for encryption (null = AWS-managed key) |
| `snapshot_id` | `string` | `null` | Snapshot ID to restore from |
| `multi_attach_enabled` | `bool` | `false` | Allow attach to multiple instances (io1/io2 only) |
| `tags` | `map(string)` | `{}` | Additional resource tags |

## Outputs

| Name | Description |
|---|---|
| `volume_id` | EBS volume ID |
| `volume_arn` | EBS volume ARN |
| `volume_size_gb` | Volume size in GiB |
| `availability_zone` | AZ of the volume |
