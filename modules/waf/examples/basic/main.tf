module "waf" {
  source = "../../"

  project     = "myapp"
  environment = "dev"
  region      = "us-east-1"
  name        = "api"
  scope       = "REGIONAL"

  managed_rule_groups = [
    { name = "AWSManagedRulesCommonRuleSet",         priority = 10 },
    { name = "AWSManagedRulesKnownBadInputsRuleSet", priority = 20 },
  ]

  rate_limit_rules = [
    { name = "global-rate-limit", priority = 1, limit = 2000 }
  ]

  tags = { Team = "security" }
}

output "web_acl_arn" { value = module.waf.web_acl_arn }
