output "vpc_id" {
  value = aws_vpc.main.id
}

# output "organization" {
#   value = var.organization
# }

# output "environment" {
#   value = var.environment
# }

# output "default_tags" {
#   value = var.default_tags
# }

# output "public_subnet_name2id_map" {
#   value = local.public_subnet_name2id_map
# }


# output "public_subnet_id_list" {
#   value = [for subnet_name, subnet_id in local.public_subnet_name2id_map : subnet_id]
# }

# output "private_subnet_id_list" {
#   value = [for subnet_name, subnet_id in local.private_subnet_name2id_map : subnet_id]
# }

# output "public_subnet_cidr_list" {
#   value = local.public_subnet_cidr_list
# }

# output "private_subnet_cidr_list" {
#   value = local.private_subnet_cidr_list
# }

# output "public_subnet_cidr_id_map" {
#   value = local.public_subnet_cidr_id_map
# }

# output "private_subnet_cidr_id_map" {
#   value = local.private_subnet_cidr_id_map
# }

# output "public_subnet_set" {
#   value = local.public_subnet_set
# }

# output "private_subnet_set" {
#   value = local.private_subnet_set
# }

# output "public_subnets_with_natgw_enabled" {
#   value = local.public_subnets_with_natgw_enabled
# }

output nat_gateway_ids {
  value = { for natgw_key, natgw_details in aws_nat_gateway.networking_natgw : split("-", natgw_key)[1] => natgw_details.id }
}