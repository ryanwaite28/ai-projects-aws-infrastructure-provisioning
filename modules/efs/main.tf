##
## Module: efs
## Creates an EFS file system with mount targets in each subnet,
## a security group for NFS access, and optional access points.
##

locals {
  region_short = {
    "us-east-1" = "use1", "us-east-2" = "use2", "us-west-1" = "usw1", "us-west-2" = "usw2",
    "eu-west-1" = "euw1", "eu-west-2" = "euw2", "eu-central-1" = "euc1",
    "ap-southeast-1" = "apse1", "ap-southeast-2" = "apse2", "ap-northeast-1" = "apne1"
  }
  rs          = lookup(local.region_short, var.region, replace(var.region, "-", ""))
  name_prefix = "${var.project}-${var.environment}-${local.rs}-efs-${var.name}"

  default_tags = merge({
    Project = var.project, Environment = var.environment, Region = var.region, ManagedBy = "terraform"
  }, var.tags)
}

resource "aws_efs_file_system" "this" {
  creation_token   = local.name_prefix
  performance_mode = var.performance_mode
  throughput_mode  = var.throughput_mode
  provisioned_throughput_in_mibps = var.throughput_mode == "provisioned" ? var.provisioned_throughput_mibps : null
  encrypted        = true
  kms_key_id       = var.kms_key_arn

  dynamic "lifecycle_policy" {
    for_each = var.lifecycle_policy.transition_to_ia != null ? [1] : []
    content {
      transition_to_ia = var.lifecycle_policy.transition_to_ia
    }
  }

  dynamic "lifecycle_policy" {
    for_each = var.lifecycle_policy.transition_to_primary_storage_class != null ? [1] : []
    content {
      transition_to_primary_storage_class = var.lifecycle_policy.transition_to_primary_storage_class
    }
  }

  tags = merge(local.default_tags, { Name = local.name_prefix })
}

resource "aws_efs_backup_policy" "this" {
  file_system_id = aws_efs_file_system.this.id
  backup_policy {
    status = var.enable_backup ? "ENABLED" : "DISABLED"
  }
}

resource "aws_security_group" "efs" {
  name        = "${local.name_prefix}-sg"
  description = "Allow NFS access to EFS from permitted security groups."
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.allowed_security_group_ids
    content {
      from_port                = 2049
      to_port                  = 2049
      protocol                 = "tcp"
      source_security_group_id = ingress.value
      description              = "NFS from sg ${ingress.value}"
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.default_tags, { Name = "${local.name_prefix}-sg" })
}

resource "aws_efs_mount_target" "this" {
  count           = length(var.subnet_ids)
  file_system_id  = aws_efs_file_system.this.id
  subnet_id       = var.subnet_ids[count.index]
  security_groups = [aws_security_group.efs.id]
}

resource "aws_efs_access_point" "this" {
  for_each       = var.access_points
  file_system_id = aws_efs_file_system.this.id

  root_directory {
    path = each.value.root_directory_path
    creation_info {
      owner_gid   = each.value.root_directory_owner_gid
      owner_uid   = each.value.root_directory_owner_uid
      permissions = each.value.root_directory_permissions
    }
  }

  posix_user {
    gid = each.value.posix_user_gid
    uid = each.value.posix_user_uid
  }

  tags = merge(local.default_tags, { Name = "${local.name_prefix}-ap-${each.key}" })
}
