# Create custom routing table for each subnet
resource "aws_route_table" "subnet_rt" {
  for_each = {
    for subnet in var.subnets :
    subnet.name => subnet
  }

  vpc_id = aws_vpc.main.id

  tags = {
    Name    = "${each.value.name}-rt"
    Project = "CloudWAN"
  }
}

# Add default route to IGW for subnets with internet access
resource "aws_route" "internet_access" {
  for_each = {
    for subnet in var.subnets :
    subnet.name => subnet
    if subnet.internetAccess && var.create_internet_gateway
  }

  route_table_id         = aws_route_table.subnet_rt[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main[0].id
}

# Associate route table with subnets
resource "aws_route_table_association" "subnet_assoc" {
  for_each = {
    for subnet in var.subnets :
    subnet.name => subnet
  }

  subnet_id      = aws_subnet.subnets[each.key].id
  route_table_id = aws_route_table.subnet_rt[each.key].id
}
