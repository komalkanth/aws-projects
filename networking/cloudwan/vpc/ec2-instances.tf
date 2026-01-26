# EC2 Instance Deployment Module
# Deploys one t2.micro instance in each VPC with Systems Manager access
# Uses single module with for_each to iterate through all VPCs

module "ec2_instances" {
  for_each = var.vpcs

  source = "./modules/ec2-instance"

  vpc_name    = each.value.vpc_name
  vpc_id      = each.value.region == "us-east-1" ? aws_vpc.use1[each.key].id : aws_vpc.use2[each.key].id
  subnet_id   = each.value.region == "us-east-1" ? aws_subnet.use1_1a[each.key].id : aws_subnet.use2_2a[each.key].id
  environment = split("-", each.value.vpc_name)[0]
  region      = each.value.region
  common_tags = var.common_tags
}
