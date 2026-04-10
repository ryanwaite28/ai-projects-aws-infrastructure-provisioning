output "ssm_prefix"         { value = module.platform.ssm_prefix }
output "vpc_id"             { value = module.platform.vpc_id }
output "cluster_arn"        { value = module.platform.cluster_arn }
output "public_alb_dns"     { value = module.platform.public_alb_dns }
output "private_alb_dns"    { value = module.platform.private_alb_dns }
