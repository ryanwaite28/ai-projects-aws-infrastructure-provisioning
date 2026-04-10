# Module: `route53`

Looks up or creates a Route 53 hosted zone and manages DNS records including A/CNAME/TXT/MX/alias types.

## Usage

```hcl
module "dns" {
  source = "../../modules/route53"

  project     = "myapp"
  environment = "prod"
  region      = "us-east-1"
  zone_name   = "example.com"
  create_zone = false   # look up existing zone

  records = {
    app = {
      name = "app.example.com"
      type = "A"
      alias = {
        name    = module.alb.alb_dns_name
        zone_id = module.alb.alb_zone_id
      }
    }

    api = {
      name    = "api.example.com"
      type    = "CNAME"
      ttl     = 300
      records = [module.api_gw.custom_domain_target]
    }
  }

  tags = { Team = "platform" }
}
```

### Private hosted zone

```hcl
module "internal_dns" {
  source = "../../modules/route53"
  # ...
  create_zone  = true
  private_zone = true
  vpc_id       = module.network.vpc_id
}
```

## Required Inputs

| Name | Type | Description |
|---|---|---|
| `project` | `string` | Project name prefix |
| `environment` | `string` | Deployment environment |
| `region` | `string` | AWS region |
| `zone_name` | `string` | DNS zone name (e.g. `example.com`) |

## Optional Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `create_zone` | `bool` | `false` | Create a new hosted zone. If false, looks up an existing zone |
| `private_zone` | `bool` | `false` | Create a private hosted zone (requires `vpc_id`) |
| `vpc_id` | `string` | `null` | VPC ID for private hosted zones |
| `records` | `map(object)` | `{}` | Map of DNS records to create |
| `tags` | `map(string)` | `{}` | Additional resource tags |

### Record object schema

| Field | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | required | Fully qualified record name |
| `type` | `string` | required | `A`, `AAAA`, `CNAME`, `TXT`, `MX`, `NS` |
| `ttl` | `number` | `300` | TTL in seconds (ignored for alias records) |
| `records` | `list(string)` | `null` | Record values (non-alias records) |
| `alias.name` | `string` | — | Alias target DNS name |
| `alias.zone_id` | `string` | — | Alias target hosted zone ID |
| `alias.evaluate_target_health` | `bool` | `true` | Enable health checking on alias target |

## Outputs

| Name | Description |
|---|---|
| `zone_id` | Route 53 hosted zone ID |
| `zone_name` | Route 53 zone name |
| `name_servers` | Name servers (only populated for newly created zones) |
| `record_fqdns` | Map of record key to FQDN |
