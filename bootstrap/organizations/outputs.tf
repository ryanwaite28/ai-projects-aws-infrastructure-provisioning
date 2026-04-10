output "organization_id"    { value = aws_organizations_organization.this.id }
output "organization_arn"   { value = aws_organizations_organization.this.arn }
output "root_id"            { value = aws_organizations_organization.this.roots[0].id }
output "workloads_ou_id"    { value = aws_organizations_organizational_unit.workloads.id }
output "env_ou_ids"         { value = { for env, ou in aws_organizations_organizational_unit.env : env => ou.id } }
