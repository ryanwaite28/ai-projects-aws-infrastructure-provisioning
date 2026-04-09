# docs

Generate or update Terraform documentation for one or all modules using `terraform-docs`.

## Usage
```
/docs [module-name]
```
If `module-name` is provided, regenerates docs for `modules/<module-name>/README.md` only.
If omitted, regenerates docs for **all** modules.

## Steps

### Single module
```bash
terraform-docs markdown modules/$ARGUMENTS > modules/$ARGUMENTS/README.md
echo "Docs updated: modules/$ARGUMENTS/README.md"
```

### All modules
```bash
for dir in modules/*/; do
  module=$(basename "$dir")
  terraform-docs markdown "$dir" > "${dir}README.md"
  echo "Updated: ${dir}README.md"
done
```

## Notes
- `terraform-docs` reads `variables.tf` and `outputs.tf` to build the inputs/outputs tables.
- The `<!-- BEGIN_TF_DOCS -->` / `<!-- END_TF_DOCS -->` markers in README.md control the injection region; content outside markers is preserved.
- If a module README does not yet contain the markers, terraform-docs will append to the file.
- Install: `brew install terraform-docs` or `go install github.com/terraform-docs/terraform-docs@latest`
