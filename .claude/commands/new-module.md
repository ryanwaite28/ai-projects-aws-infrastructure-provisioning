# new-module

Scaffold a new Terraform module under `modules/<name>/`.

## Usage
```
/new-module <module-name>
```

## Steps

1. Create the directory `modules/$ARGUMENTS/` with the following files:

**`main.tf`** — resource definitions (empty scaffold with a comment block at top)
**`variables.tf`** — input variable declarations, each with `description` and `type`
**`outputs.tf`** — output value declarations
**`README.md`** — module documentation (populated via terraform-docs conventions)

2. Use this file structure template for each file:

### main.tf
```hcl
##
## Module: $ARGUMENTS
## Managed by Terraform — do not edit manually.
##

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}
```

### variables.tf
```hcl
variable "project" {
  description = "Project name, used as a prefix in resource names and tags."
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, qa, prod)."
  type        = string
}

variable "region" {
  description = "AWS region for this module's resources."
  type        = string
}

variable "tags" {
  description = "Additional tags to merge with the default tag set."
  type        = map(string)
  default     = {}
}
```

### outputs.tf
```hcl
# Add outputs here as resources are defined in main.tf
```

### README.md
```markdown
# Module: $ARGUMENTS

<!-- BEGIN_TF_DOCS -->
<!-- Run: terraform-docs markdown . >> README.md -->
<!-- END_TF_DOCS -->

## Usage

\`\`\`hcl
module "$ARGUMENTS" {
  source = "../../modules/$ARGUMENTS"

  project     = var.project
  environment = var.environment
  region      = var.region
  tags        = var.tags
}
\`\`\`

## Examples

See `examples/` for a working example.
```

3. Also create `modules/$ARGUMENTS/examples/main.tf` with a minimal working usage example.

4. Confirm all files were created and remind the user to:
   - Add the module to `PROJECT.md` under the Modules Reference section
   - Run `terraform-docs markdown modules/$ARGUMENTS > modules/$ARGUMENTS/README.md` after writing resources
   - Add a usage example in `stacks/` if this module is part of a common composition
