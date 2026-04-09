# new-stack

Scaffold a new stack under `stacks/<name>/`. A stack is an opinionated composition of two or more modules for a common use-case pattern.

## Usage
```
/new-stack <stack-name>
```

## Steps

1. Create `stacks/$ARGUMENTS/` with:

**`main.tf`** — module composition (calls into `../../modules/*`)
**`variables.tf`** — inputs forwarded to child modules
**`outputs.tf`** — aggregated outputs from child modules
**`README.md`** — purpose, included modules, and usage example

### main.tf template
```hcl
##
## Stack: $ARGUMENTS
## Composes: <list the modules this stack uses>
##

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

# Example module composition:
# module "network" {
#   source      = "../../modules/network"
#   project     = var.project
#   environment = var.environment
#   region      = var.region
#   tags        = var.tags
# }
```

### variables.tf template
```hcl
variable "project" {
  type        = string
  description = "Project name prefix."
}

variable "environment" {
  type        = string
  description = "Deployment environment."
}

variable "region" {
  type        = string
  description = "Primary AWS region."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Additional resource tags."
}
```

2. Remind the user to:
   - List which modules this stack composes at the top of `main.tf`
   - Add the stack to `PROJECT.md` under the Stacks section
   - Reference the stack from the relevant `environments/` root module
