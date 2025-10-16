# locals {
#   az_ids_list = [for key, value in var.public_subnet_cidr_map : key]
# }

# locals {
#   az_ids_list = for_each in
# }

data "aws_availability_zones" "available" {
  state = "available"
  filter {
    name   = "zone-id"
    values = ["opt-in-not-required"]
  }
}

# output "az_ids_list" {
#   value = local.az_ids_list
# }