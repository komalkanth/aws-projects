output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = try(aws_internet_gateway.main[0].id, null)
}

output "subnets" {
  description = "Map of subnet details"
  value = {
    for subnet_name, subnet in aws_subnet.subnets :
    subnet_name => {
      id             = subnet.id
      cidr           = subnet.cidr_block
      az             = subnet.availability_zone
      route_table_id = aws_route_table.subnet_rt[subnet_name].id
    }
  }
}

output "route_tables" {
  description = "Map of route table IDs by subnet"
  value = {
    for subnet_name, rt in aws_route_table.subnet_rt :
    subnet_name => rt.id
  }
}
