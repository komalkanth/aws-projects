# Default route for private app subnets to route traffic to NAT Gateway
resource "aws_route" "pvt_az1_natgw_route" {
  for_each                   = toset(data.aws_route_tables.pvt_az1_rt.ids)
  route_table_id             = each.value
  destination_cidr_block     = "0.0.0.0/0"
  nat_gateway_id             = module.vpc.nat_gateway_ids["az1"]
}

resource "aws_route" "pvt_az2_natgw_route" {
  for_each                   = toset(data.aws_route_tables.pvt_az2_rt.ids)
  route_table_id             = each.value
  destination_cidr_block     = "0.0.0.0/0"
  nat_gateway_id             = module.vpc.nat_gateway_ids["az2"]
}

resource "aws_route" "pvt_az3_natgw_route" {
  for_each                   = toset(data.aws_route_tables.pvt_az3_rt.ids)
  route_table_id             = each.value
  destination_cidr_block     = "0.0.0.0/0"
  nat_gateway_id             = module.vpc.nat_gateway_ids["az3"]
}