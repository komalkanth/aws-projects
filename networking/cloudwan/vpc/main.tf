locals {
  # Separate VPCs by region for proper provider assignment
  use1_vpcs = { for k, v in var.vpcs : k => v if v.region == "us-east-1" }
  use2_vpcs = { for k, v in var.vpcs : k => v if v.region == "us-east-2" }
}

# ============================================
# US-EAST-1 VPCs
# ============================================

# VPCs in us-east-1
resource "aws_vpc" "use1" {
  for_each = local.use1_vpcs

  cidr_block           = each.value.vpc_cidr
  enable_dns_support   = each.value.enable_dns_support
  enable_dns_hostnames = each.value.enable_dns_hostnames

  tags = {
    Name        = each.value.vpc_name
    Environment = split("-", each.value.vpc_name)[0]
    ManagedBy   = "Terraform"
    Project     = "CloudWAN"
  }
}

# Subnets in AZ 1a for us-east-1
resource "aws_subnet" "use1_1a" {
  for_each = local.use1_vpcs

  vpc_id            = aws_vpc.use1[each.key].id
  cidr_block        = each.value.subnet_1a_cidr
  availability_zone = "${each.value.region}a"

  tags = {
    Name      = "${each.value.vpc_name}-subnet-1a"
    VPC       = each.value.vpc_name
    ManagedBy = "Terraform"
  }
}

# Subnets in AZ 1b for us-east-1
resource "aws_subnet" "use1_1b" {
  for_each = local.use1_vpcs

  vpc_id            = aws_vpc.use1[each.key].id
  cidr_block        = each.value.subnet_1b_cidr
  availability_zone = "${each.value.region}b"

  tags = {
    Name      = "${each.value.vpc_name}-subnet-1b"
    VPC       = each.value.vpc_name
    ManagedBy = "Terraform"
  }
}

# Internet Gateways for us-east-1
resource "aws_internet_gateway" "use1" {
  for_each = { for k, v in local.use1_vpcs : k => v if v.enable_igw }

  vpc_id = aws_vpc.use1[each.key].id

  tags = {
    Name      = "${each.value.vpc_name}-igw"
    VPC       = each.value.vpc_name
    ManagedBy = "Terraform"
  }
}

# Attach Internet Gateways to VPCs in us-east-1
resource "aws_internet_gateway_attachment" "use1" {
  for_each = { for k, v in local.use1_vpcs : k => v if v.enable_igw }

  vpc_id              = aws_vpc.use1[each.key].id
  internet_gateway_id = aws_internet_gateway.use1[each.key].id
}

# Route Tables for us-east-1
resource "aws_route_table" "use1" {
  for_each = local.use1_vpcs

  vpc_id = aws_vpc.use1[each.key].id

  tags = {
    Name      = "${each.value.vpc_name}-public-rt"
    VPC       = each.value.vpc_name
    ManagedBy = "Terraform"
  }
}

# Public Routes to Internet Gateway for us-east-1
resource "aws_route" "use1_public" {
  for_each = { for k, v in local.use1_vpcs : k => v if v.enable_igw }

  route_table_id         = aws_route_table.use1[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.use1[each.key].id

  depends_on = [aws_internet_gateway_attachment.use1]
}

# Route Table Association for subnet 1a in us-east-1
resource "aws_route_table_association" "use1_1a" {
  for_each = local.use1_vpcs

  subnet_id      = aws_subnet.use1_1a[each.key].id
  route_table_id = aws_route_table.use1[each.key].id
}

# Route Table Association for subnet 1b in us-east-1
resource "aws_route_table_association" "use1_1b" {
  for_each = local.use1_vpcs

  subnet_id      = aws_subnet.use1_1b[each.key].id
  route_table_id = aws_route_table.use1[each.key].id
}

# ============================================
# US-EAST-2 VPCs
# ============================================

# VPCs in us-east-2
resource "aws_vpc" "use2" {
  for_each = local.use2_vpcs
  provider = aws.use2

  cidr_block           = each.value.vpc_cidr
  enable_dns_support   = each.value.enable_dns_support
  enable_dns_hostnames = each.value.enable_dns_hostnames

  tags = {
    Name        = each.value.vpc_name
    Environment = split("-", each.value.vpc_name)[0]
    ManagedBy   = "Terraform"
    Project     = "CloudWAN"
  }
}

# Subnets in AZ 2a for us-east-2
resource "aws_subnet" "use2_2a" {
  for_each = local.use2_vpcs
  provider = aws.use2

  vpc_id            = aws_vpc.use2[each.key].id
  cidr_block        = each.value.subnet_1a_cidr
  availability_zone = "${each.value.region}a"

  tags = {
    Name      = "${each.value.vpc_name}-subnet-2a"
    VPC       = each.value.vpc_name
    ManagedBy = "Terraform"
  }
}

# Subnets in AZ 2b for us-east-2
resource "aws_subnet" "use2_2b" {
  for_each = local.use2_vpcs
  provider = aws.use2

  vpc_id            = aws_vpc.use2[each.key].id
  cidr_block        = each.value.subnet_1b_cidr
  availability_zone = "${each.value.region}b"

  tags = {
    Name      = "${each.value.vpc_name}-subnet-2b"
    VPC       = each.value.vpc_name
    ManagedBy = "Terraform"
  }
}

# Internet Gateways for us-east-2
resource "aws_internet_gateway" "use2" {
  for_each = { for k, v in local.use2_vpcs : k => v if v.enable_igw }
  provider = aws.use2

  vpc_id = aws_vpc.use2[each.key].id

  tags = {
    Name      = "${each.value.vpc_name}-igw"
    VPC       = each.value.vpc_name
    ManagedBy = "Terraform"
  }
}

# Attach Internet Gateways to VPCs in us-east-2
resource "aws_internet_gateway_attachment" "use2" {
  for_each = { for k, v in local.use2_vpcs : k => v if v.enable_igw }
  provider = aws.use2

  vpc_id              = aws_vpc.use2[each.key].id
  internet_gateway_id = aws_internet_gateway.use2[each.key].id
}

# Route Tables for us-east-2
resource "aws_route_table" "use2" {
  for_each = local.use2_vpcs
  provider = aws.use2

  vpc_id = aws_vpc.use2[each.key].id

  tags = {
    Name      = "${each.value.vpc_name}-public-rt"
    VPC       = each.value.vpc_name
    ManagedBy = "Terraform"
  }
}

# Public Routes to Internet Gateway for us-east-2
resource "aws_route" "use2_public" {
  for_each = { for k, v in local.use2_vpcs : k => v if v.enable_igw }
  provider = aws.use2

  route_table_id         = aws_route_table.use2[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.use2[each.key].id

  depends_on = [aws_internet_gateway_attachment.use2]
}

# Route Table Association for subnet 2a in us-east-2
resource "aws_route_table_association" "use2_2a" {
  for_each = local.use2_vpcs
  provider = aws.use2

  subnet_id      = aws_subnet.use2_2a[each.key].id
  route_table_id = aws_route_table.use2[each.key].id
}

# Route Table Association for subnet 2b in us-east-2
resource "aws_route_table_association" "use2_2b" {
  for_each = local.use2_vpcs
  provider = aws.use2

  subnet_id      = aws_subnet.use2_2b[each.key].id
  route_table_id = aws_route_table.use2[each.key].id
}
