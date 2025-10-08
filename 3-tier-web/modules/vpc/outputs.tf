output "region" {
  value = var.region
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "organization" {
  value = var.organization
}

output "environment" {
  value = var.environment
}

output "default_tags" {
  value = var.default_tags
}

output "public_subnet_name2id_map" {
  value = local.public_subnet_name2id_map
}

output "private_subnet_name2id_map" {
  value = local.private_subnet_name2id_map
}

output "public_subnet_id_list" {
  value = [for subnet_name, subnet_id in local.public_subnet_name2id_map : subnet_id]
}

output "private_subnet_id_list" {
  value = [for subnet_name, subnet_id in local.private_subnet_name2id_map : subnet_id]
}

output "public_subnet_cidr_list" {
  value = local.public_subnet_cidr_list
}

output "private_subnet_cidr_list" {
  value = local.private_subnet_cidr_list
}

output "public_subnet_cidr_id_map" {
  value = local.public_subnet_cidr_id_map
}

output "private_subnet_cidr_id_map" {
  value = local.private_subnet_cidr_id_map
}

output "public_subnet_set" {
  value = local.public_subnet_set
}

output "private_subnet_set" {
  value = local.private_subnet_set
}