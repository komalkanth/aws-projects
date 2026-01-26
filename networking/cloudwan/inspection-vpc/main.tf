# Create VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name    = var.vpc_name
    Project = "CloudWAN"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "main" {
  count  = var.create_internet_gateway ? 1 : 0
  vpc_id = aws_vpc.main.id

  tags = {
    Name    = "${var.vpc_name}-igw"
    Project = "CloudWAN"
  }
}

# Create Subnets
resource "aws_subnet" "subnets" {
  for_each = {
    for subnet in var.subnets :
    subnet.name => subnet
  }

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = {
    Name    = each.value.name
    Type    = each.value.type
    Project = "CloudWAN"
  }
}
