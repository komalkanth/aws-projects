# Data source to get AZ names from AZ IDs for az1, az2 and az3

data "aws_availability_zone" "az_name_from_id" {
  for_each = var.public_subnet_cidr_map
  zone_id  = "${var.region_short_name}-${each.key}"
}
