# Releases

All notable changes to this module library are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Added
- Initial module library: 25 modules covering all major AWS services
- Initial stack library: 13 opinionated stack compositions
- GitHub Actions reusable workflows: plan, apply, destroy, drift detection, bootstrap
- Environment root modules: dev, qa, prod
- Bootstrap modules: state-backend, oidc, organizations
- Backend config HCL files per environment
- Project documentation (PROJECT.md, CLAUDE.md)
- Workspace skills: new-module, new-stack, plan, lint, docs

---

## Versioning Strategy

Tags follow `vMAJOR.MINOR.PATCH`:

| Change type | Version bump |
|-------------|-------------|
| Breaking variable renames, removed outputs, structural refactors | MAJOR |
| New modules, new optional variables, new outputs | MINOR |
| Bug fixes, documentation updates, non-breaking internals | PATCH |

### Pinning modules from this repo

```hcl
module "network" {
  source = "git::https://github.com/your-org/infra-modules.git//modules/network?ref=v1.0.0"
  ...
}
```

### Calling reusable workflows from this repo

```yaml
jobs:
  plan:
    uses: your-org/infra-modules/.github/workflows/tf-plan.yml@v1.0.0
    with:
      working_directory: stacks/bff
      environment: dev
    secrets:
      aws_role_arn: ${{ secrets.AWS_ROLE_ARN_DEV }}
```
