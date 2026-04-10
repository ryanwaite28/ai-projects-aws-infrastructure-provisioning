output "vpc_id"              { value = module.network.vpc_id }
output "vpc_cidr"             { value = module.network.vpc_cidr }
output "public_subnet_ids"    { value = module.network.public_subnet_ids }
output "private_subnet_ids"   { value = module.network.private_subnet_ids }
output "db_subnet_ids"        { value = module.network.db_subnet_ids }
output "nat_public_ips"       { value = module.network.nat_public_ips }
output "vpce_security_group_id" { value = module.network.vpce_security_group_id }
output "interface_endpoint_ids" { value = module.network.interface_endpoint_ids }
