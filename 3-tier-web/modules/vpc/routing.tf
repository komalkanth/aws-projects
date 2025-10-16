
# # Resource to create Internet Gateway
resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.default_tags, {
      Name = "${var.environment}-${var.region_to_name_map[var.region]}-${replace(var.vpc_name, "-", "")}-igw"
    }
  )
}

# #########################
# ### PUBLIC SUBNET ROUTING
# #########################

# # Resource to create dedicated Route table for public subnets so that they can have route to internet
resource "aws_route_table" "pub_rt" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.default_tags, {
      Name = "${var.environment}-${var.region_to_name_map[var.region]}-${replace(var.vpc_name, "-", "")}-pub-rt"
    }
  )
}

# Resource to create public Route table association to public subnets so that they can have route to internet
resource "aws_route_table_association" "pub_rt_assoc" {
  for_each       = local.public_subnet_name2id_map
  subnet_id      = each.value
  route_table_id = aws_route_table.pub_rt.id
}

# Resource to add dfault route to pub_rt Route table pointing to IGW
resource "aws_route" "pub_rt_route" {
  route_table_id         = aws_route_table.pub_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main_igw.id
  depends_on             = [aws_route_table.pub_rt]
}


# ##########################
# ### PRIVATE SUBNET ROUTING
# ##########################

# # Resource to create dedicated Route table for private subnets without internet access
resource "aws_route_table" "pvt_web_rt" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.default_tags, {
      Name    = "${var.environment}-${var.region_to_name_map[var.region]}-${replace(var.vpc_name, "-", "")}-web-pvt-rt",
      purpose = "web"
    }
  )
}

resource "aws_route_table" "pvt_app_rt" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.default_tags, {
      Name    = "${var.environment}-${var.region_to_name_map[var.region]}-${replace(var.vpc_name, "-", "")}-app-pvt-rt",
      purpose = "app"
    }
  )
}

resource "aws_route_table" "pvt_db_rt" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.default_tags, {
      Name    = "${var.environment}-${var.region_to_name_map[var.region]}-${replace(var.vpc_name, "-", "")}-db-pvt-rt",
      purpose = "db"
    }
  )
}

# # Resource to create private Route table association to private subnets
# resource "aws_route_table_association" "pvt_web_rt_assoc" {
#   for_each       = local.private_subnet_name2id_map
#   subnet_id      = each.value[1] == "web" ? each.value[0] : ""
#   route_table_id = aws_route_table.pvt_web_rt.id
# }

# resource "aws_route_table_association" "pvt_app_rt_assoc" {
#   for_each       = local.private_subnet_name2id_map
#   subnet_id      = each.value[1] == "app" ? each.value[0] : ""
#   route_table_id = aws_route_table.pvt_app_rt.id
# }

# resource "aws_route_table_association" "pvt_db_rt_assoc" {
#   for_each       = local.private_subnet_name2id_map
#   subnet_id      = each.value[1] == "db" ? each.value[0] : ""
#   route_table_id = aws_route_table.pvt_db_rt.id
# }
