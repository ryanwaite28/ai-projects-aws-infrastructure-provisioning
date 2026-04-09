# lint

Run all static analysis and security checks across the Terraform codebase.

## Usage
```
/lint [path]
```
If `path` is omitted, runs against the entire repo. Pass a module path (e.g. `modules/network`) to scope the run.

## Steps

Run the following commands in order. Report any failures clearly with file and line number.

```bash
# 1. Validate HCL syntax across all modules
terraform fmt -check -recursive ${ARGUMENTS:-.}

# 2. tflint — Terraform linting (variable types, deprecated syntax, AWS-specific rules)
tflint --recursive ${ARGUMENTS:-.}

# 3. checkov — Security and compliance scanning
checkov -d ${ARGUMENTS:-.} --framework terraform --compact

# 4. terraform validate — per-environment (requires init)
for env in environments/*/; do
  echo "=== Validating $env ==="
  terraform -chdir="$env" validate
done
```

## Fix mode

If the user asks to fix formatting issues, run:
```bash
terraform fmt -recursive ${ARGUMENTS:-.}
```

## Expected tools
- `terraform` >= 1.7
- `tflint` with `tflint-ruleset-aws`
- `checkov` (pip install checkov)

Remind the user to install missing tools if any command is not found.
