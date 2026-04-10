# Module: `iam`

Creates an IAM role with a configurable trust policy (service principals, role ARNs, OIDC), attached managed policies, inline policies, and optional EC2 instance profile.

Full name pattern: `{project}-{environment}-{region_short}-role-{role_name}`

## Usage

### ECS task role

```hcl
module "api_task_role" {
  source = "../../modules/iam"

  project     = "myapp"
  environment = "prod"
  region      = "us-east-1"
  role_name   = "api-task"
  role_description = "ECS task role for the API service"

  trusted_service_principals = ["ecs-tasks.amazonaws.com"]

  inline_policies = {
    secrets = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = [module.db_password.secret_arn]
      }]
    })
  }

  tags = { Team = "backend" }
}
```

### OIDC role for GitHub Actions

```hcl
module "github_deploy_role" {
  source = "../../modules/iam"
  # ...
  trusted_oidc_provider_arn = data.aws_iam_openid_connect_provider.github.arn

  oidc_subject_conditions = {
    "token.actions.githubusercontent.com:sub" = "repo:your-org/your-repo:ref:refs/heads/main"
    "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
  }

  managed_policy_arns = ["arn:aws:iam::aws:policy/ReadOnlyAccess"]
}
```

### Cross-account assume role

```hcl
module "devops_role" {
  source = "../../modules/iam"
  # ...
  trusted_role_arns = ["arn:aws:iam::111122223333:role/ci-pipeline"]
}
```

## Required Inputs

| Name | Type | Description |
|---|---|---|
| `project` | `string` | Project name prefix |
| `environment` | `string` | Deployment environment |
| `region` | `string` | AWS region |
| `role_name` | `string` | Short role name |

## Optional Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `role_description` | `string` | `""` | Human-readable role description |
| `trusted_service_principals` | `list(string)` | `[]` | AWS service principals (e.g. `ecs-tasks.amazonaws.com`) |
| `trusted_role_arns` | `list(string)` | `[]` | IAM role ARNs allowed to assume this role |
| `trusted_oidc_provider_arn` | `string` | `null` | OIDC provider ARN for federated access |
| `oidc_subject_conditions` | `map(string)` | `{}` | OIDC condition key/value pairs for trust policy |
| `managed_policy_arns` | `list(string)` | `[]` | Managed or customer-managed policy ARNs to attach |
| `inline_policies` | `map(string)` | `{}` | Map of inline policy name → JSON policy document |
| `permission_boundary_arn` | `string` | `null` | Permissions boundary policy ARN |
| `max_session_duration` | `number` | `3600` | Max session duration in seconds (3600–43200) |
| `force_detach_policies` | `bool` | `true` | Force-detach policies before role deletion |
| `tags` | `map(string)` | `{}` | Additional resource tags |

## Outputs

| Name | Description |
|---|---|
| `role_name` | IAM role name |
| `role_arn` | IAM role ARN |
| `role_id` | Unique role ID |
| `instance_profile_name` | EC2 instance profile name (set when `ec2.amazonaws.com` is trusted) |
| `instance_profile_arn` | EC2 instance profile ARN |
