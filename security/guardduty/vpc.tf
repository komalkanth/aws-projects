# VPC for the GuardDuty project
# Creates an isolated network for the web application
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default"

  tags = {
    Name = "${var.stack_name}-VPC"
  }
}

# Internet Gateway to provide internet access to the VPC
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.stack_name}-InternetGateway"
  }
}

# First public subnet in availability zone 0
# Hosts web servers with auto-assigned public IPs
resource "aws_subnet" "public_subnet" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_cidr[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.stack_name}-publicsubnet-${count.index + 1}"
  }

  depends_on = [aws_internet_gateway.main]
}

# Route table for public subnets
resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.stack_name}-RouteTable"
  }
}

# Default route to the internet gateway
resource "aws_route" "internet" {
  route_table_id         = aws_route_table.main.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

# Associate first subnet with route table
resource "aws_route_table_association" "public_subnet" {
  count          = 2
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.main.id
}

# VPC Endpoint for S3
# Keeps S3 traffic within AWS network for security and performance
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.main.id]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket",
          "s3:GetBucketPolicy",
          "s3:GetObjectAcl",
          "s3:PutObjectAcl",
          "s3:DeleteObject"
        ]
        Resource = [
          aws_s3_bucket.secure.arn,
          "${aws_s3_bucket.secure.arn}/*",
          "arn:${data.aws_partition.current.partition}:s3:::cloudformation-examples",
          "arn:${data.aws_partition.current.partition}:s3:::cloudformation-examples/*"
        ]
      }
    ]
  })
}
