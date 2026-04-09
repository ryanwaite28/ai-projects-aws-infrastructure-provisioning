# CLAUDE.md — Project Instructions

This is a Terraform module library and GitHub Actions workflow template for provisioning highly available, multi-region AWS infrastructure. See `PROJECT.md` for full design intent, module reference, and bootstrap runbook.

---

## Project Commands (Skills)

| Command | Description |
|---|---|
| `/new-module <name>` | Scaffold a new Terraform module under `modules/<name>/` |
| `/new-stack <name>` | Scaffold a new stack (module composition) under `stacks/<name>/` |
| `/plan <environment>` | Run `terraform plan` for `dev`, `qa`, or `prod` |
| `/lint [path]` | Run `terraform fmt`, `tflint`, `checkov`, and `terraform validate` |
| `/docs [module-name]` | Generate/update README.md for one or all modules via `terraform-docs` |

---

## Conventions

### Resource Naming
```
{project}-{environment}-{region_short}-{resource_type}[-{qualifier}]
```
Region short codes: `use1`, `use2`, `usw2`, `euw1`

### Required Tags on All Resources
```hcl
tags = {
  Project     = var.project
  Environment = var.environment
  Region      = var.region
  ManagedBy   = "terraform"
  Repository  = var.repository
}
```

### Module Structure
Every module must have exactly these files:
```
modules/<name>/
  main.tf        # resource definitions
  variables.tf   # all inputs with description + type
  outputs.tf     # all outputs with description
  README.md      # terraform-docs generated
  examples/      # at least one working example
```

### Variable Files
- `variables.tf` — declarations only (no values)
- `terraform.tfvars` — environment values (committed, no secrets)
- `secrets.auto.tfvars` — secrets injected by CI (never committed)

### State
- Remote state: S3 + DynamoDB per environment account
- State path: `{environment}/{stack}/terraform.tfstate`
- Cross-stack references: use `terraform_remote_state` or SSM Parameter Store

---

## Code Quality Rules

- Run `/lint` before opening any PR
- Run `/docs` after adding or changing variables/outputs in any module
- No `count` on resources where `for_each` is more appropriate
- No hardcoded account IDs, region strings, or ARNs — always use variables or data sources
- All secrets go through Secrets Manager or SSM SecureString — never in `.tfvars`
- Every module must be self-contained: no implicit dependencies on external state except via explicit `data` sources

---

## IAM Rules

- No wildcard (`*`) actions in IAM policies unless explicitly justified with a comment
- All Lambda, ECS task, and EC2 roles get a dedicated execution role — no shared roles across services
- All CI/CD uses OIDC assume-role — no IAM users with access keys

---

## Memory

Project memory is stored in `.claude/memory/`. Key files:
- `MEMORY.md` — index of all memory entries
- `PROJECT_INTENT.md` — design goals, module list, and bootstrap runbook summary
