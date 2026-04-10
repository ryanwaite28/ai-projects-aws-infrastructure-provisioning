# Module: `acm`

Requests and validates an ACM TLS certificate via DNS validation in Route 53. Supports SANs and optional wildcard.

## Usage

```hcl
module "cert" {
  source = "../../modules/acm"

  project     = "myapp"
  environment = "prod"
  region      = "us-east-1"

  domain_name               = "app.example.com"
  subject_alternative_names = ["api.example.com"]
  zone_id                   = module.dns.zone_id
  create_wildcard           = false
  wait_for_validation       = true

  tags = { Team = "platform" }
}
```

### Wildcard certificate

```hcl
module "wildcard_cert" {
  source = "../../modules/acm"
  # ...
  domain_name     = "example.com"
  create_wildcard = true   # adds *.example.com as a SAN automatically
}
```

> **Note:** CloudFront certificates must be provisioned in `us-east-1` regardless of the distribution's region.

## Required Inputs

| Name | Type | Description |
|---|---|---|
| `project` | `string` | Project name prefix |
| `environment` | `string` | Deployment environment |
| `region` | `string` | AWS region |
| `domain_name` | `string` | Primary domain name (e.g. `app.example.com` or `*.example.com`) |
| `zone_id` | `string` | Route 53 hosted zone ID for DNS validation record creation |

## Optional Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `subject_alternative_names` | `list(string)` | `[]` | Additional domain names to include |
| `create_wildcard` | `bool` | `false` | Automatically add `*.{domain_name}` as a SAN |
| `wait_for_validation` | `bool` | `true` | Block until the certificate is validated and issued |
| `tags` | `map(string)` | `{}` | Additional resource tags |

## Outputs

| Name | Description |
|---|---|
| `certificate_arn` | ARN of the ACM certificate |
| `certificate_domain` | Primary domain name on the certificate |
| `certificate_status` | Current validation status |
