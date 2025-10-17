data "aws_route_tables" "pvt_az1_rt" {
  vpc_id = module.vpc.vpc_id
  filter {
    name   = "tag:Name"
    values = ["*pvt-az1*"]
  }
}

data "aws_route_tables" "pvt_az2_rt" {
  vpc_id = module.vpc.vpc_id
  filter {
    name   = "tag:Name"
    values = ["*pvt-az2*"]
  }
}

data "aws_route_tables" "pvt_az3_rt" {
  vpc_id = module.vpc.vpc_id
  filter {
    name   = "tag:Name"
    values = ["*pvt-az3*"]
  }
}
