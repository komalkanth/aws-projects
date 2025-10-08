# Resource to create VPCs
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_main_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = merge(
    var.default_tags, {
      Name = "${var.environment}-${var.region_to_name_map[var.region]}-${var.vpc_name}"
    }
  )
}

# Resource to create public subnets
# Uses locals "public_subnet_set" for input
resource "aws_subnet" "public_subnet" {
  vpc_id   = aws_vpc.main.id
  for_each = { for subnet_input in local.public_subnet_set : "${subnet_input.cidr_block}" => subnet_input }

  cidr_block        = each.value.cidr_block
  availability_zone = each.value.availability_zone

  tags = merge(
    var.default_tags, {
      Name    = "${var.environment}-${var.region_to_name_map[var.region]}-${replace(var.vpc_name, "-", "")}-${each.value.subnet_number}",
      purpose = each.value.purpose
    }
  )
}

# Resource to create private subnets
# Uses locals "private_subnet_set" for input
resource "aws_subnet" "private_subnet" {
  vpc_id   = aws_vpc.main.id
  for_each = { for subnet_input in local.private_subnet_set : "${subnet_input.cidr_block}" => subnet_input }

  cidr_block        = each.value.cidr_block
  availability_zone = each.value.availability_zone

  tags = merge(
    var.default_tags, {
      Name    = "${var.environment}-${var.region_to_name_map[var.region]}-${replace(var.vpc_name, "-", "")}-${each.value.subnet_number}",
      purpose = each.value.purpose
    }
  )
}


# Resource to create an ACL for public subnets currently allowing traffic both ways
resource "aws_network_acl" "public_subnet_nacl" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = [for subnet_name, subnet_id in local.public_subnet_name2id_map : subnet_id]

  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
    icmp_code  = 0
    icmp_type  = 0
  }

  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
    icmp_code  = 0
    icmp_type  = 0
  }

  tags = merge(
    var.default_tags, {
      Name = "${var.environment}-${var.region_to_name_map[var.region]}-${replace(var.vpc_name, "-", "")}-pub-nacl"
    }
  )
}

# Resource to create an ACL for private subnets currently allowing traffic both ways
resource "aws_network_acl" "private_subnet_nacl" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = [for subnet_name, subnet_id in local.private_subnet_name2id_map : subnet_id[0]]

  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
    icmp_code  = 0
    icmp_type  = 0
  }

  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
    icmp_code  = 0
    icmp_type  = 0
  }

  tags = merge(
    var.default_tags, {
      Name = "${var.environment}-${var.region_to_name_map[var.region]}-${replace(var.vpc_name, "-", "")}-pvt-nacl"
    }
  )
}