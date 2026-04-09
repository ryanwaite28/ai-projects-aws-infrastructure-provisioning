# plan

Run `terraform plan` for a specific environment, using the correct backend config and var file.

## Usage
```
/plan <environment>
```
`environment` must be one of: `dev`, `qa`, `prod`

## Steps

```bash
ENVIRONMENT=$ARGUMENTS
ENV_DIR="environments/${ENVIRONMENT}"

# Validate the environment directory exists
if [ ! -d "$ENV_DIR" ]; then
  echo "ERROR: Environment directory '$ENV_DIR' not found."
  exit 1
fi

# Init with backend config
terraform -chdir="$ENV_DIR" init \
  -backend-config="../../config/backend-${ENVIRONMENT}.hcl" \
  -reconfigure

# Plan
terraform -chdir="$ENV_DIR" plan \
  -var-file="terraform.tfvars" \
  -out="${ENVIRONMENT}.tfplan"

echo ""
echo "Plan saved to: ${ENV_DIR}/${ENVIRONMENT}.tfplan"
echo "To apply: terraform -chdir=${ENV_DIR} apply ${ENVIRONMENT}.tfplan"
```

## Notes
- Requires valid AWS credentials. Locally, set `AWS_PROFILE=<environment>` or authenticate via `aws sso login --profile <environment>`.
- The `.tfplan` output file should never be committed to git (it is gitignored).
- For prod, always review the plan output carefully before applying.
