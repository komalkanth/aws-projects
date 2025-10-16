# ########################
# ### INTERNET & NAT GATEWAY
# ########################

# # Resource to create Internet Gateway
resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.default_tags, {
      Name = "${var.environment}-${var.region_to_name_map[var.region]}-${replace(var.vpc_name, "-", "")}-igw"
    }
  )
}

# Resource to create EIP for NAT Gateway, one per public subnet
resource "aws_eip" "natgw_eip" {
  for_each = aws_subnet.public_subnet
  domain   = "vpc"

  tags = merge(
    var.default_tags, {
      Name = "${var.environment}-${var.region_to_name_map[var.region]}-eip-natgw-${split("-", each.key)[1]}"
    }
  )
}

# Resource to create NAT Gateway in each public subnet
resource "aws_nat_gateway" "networking_natgw" {
  for_each      = aws_subnet.public_subnet
  allocation_id = aws_eip.natgw_eip[each.key].id
  subnet_id     = each.value.id

  tags = merge(
    var.default_tags, {
      Name = "${var.environment}-${var.region_to_name_map[var.region]}-natgw-${split("-", each.key)[1]}"
    }
  )

  depends_on = [aws_internet_gateway.main_igw]
}