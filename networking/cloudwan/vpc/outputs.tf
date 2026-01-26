# ============================================
# US-EAST-1 Outputs
# ============================================

output "use1_vpc_ids" {
  description = "VPC IDs in us-east-1"
  value = {
    for k, v in awscc_ec2_vpc.use1 : k => v.vpc_id
  }
}

output "use1_subnet_1a_ids" {
  description = "Subnet IDs in AZ 1a for us-east-1"
  value = {
    for k, v in awscc_ec2_subnet.use1_1a : k => v.subnet_id
  }
}

output "use1_subnet_1b_ids" {
  description = "Subnet IDs in AZ 1b for us-east-1"
  value = {
    for k, v in awscc_ec2_subnet.use1_1b : k => v.subnet_id
  }
}

output "use1_internet_gateway_ids" {
  description = "Internet Gateway IDs in us-east-1"
  value = {
    for k, v in awscc_ec2_internet_gateway.use1 : k => v.internet_gateway_id
  }
}

output "use1_route_table_ids" {
  description = "Route Table IDs in us-east-1"
  value = {
    for k, v in awscc_ec2_route_table.use1 : k => v.route_table_id
  }
}

# ============================================
# US-EAST-2 Outputs
# ============================================

output "use2_vpc_ids" {
  description = "VPC IDs in us-east-2"
  value = {
    for k, v in awscc_ec2_vpc.use2 : k => v.vpc_id
  }
}

output "use2_subnet_2a_ids" {
  description = "Subnet IDs in AZ 2a for us-east-2"
  value = {
    for k, v in awscc_ec2_subnet.use2_2a : k => v.subnet_id
  }
}

output "use2_subnet_2b_ids" {
  description = "Subnet IDs in AZ 2b for us-east-2"
  value = {
    for k, v in awscc_ec2_subnet.use2_2b : k => v.subnet_id
  }
}

output "use2_internet_gateway_ids" {
  description = "Internet Gateway IDs in us-east-2"
  value = {
    for k, v in awscc_ec2_internet_gateway.use2 : k => v.internet_gateway_id
  }
}

output "use2_route_table_ids" {
  description = "Route Table IDs in us-east-2"
  value = {
    for k, v in awscc_ec2_route_table.use2 : k => v.route_table_id
  }
}

# ============================================
# Summary Output
# ============================================

output "vpc_summary" {
  description = "Summary of all VPCs created"
  value = {
    us-east-1 = {
      for k, v in local.use1_vpcs : k => {
        vpc_id         = awscc_ec2_vpc.use1[k].vpc_id
        vpc_cidr       = v.vpc_cidr
        subnet_1a_id   = awscc_ec2_subnet.use1_1a[k].subnet_id
        subnet_1a_cidr = v.subnet_1a_cidr
        subnet_1b_id   = awscc_ec2_subnet.use1_1b[k].subnet_id
        subnet_1b_cidr = v.subnet_1b_cidr
      }
    }
    us-east-2 = {
      for k, v in local.use2_vpcs : k => {
        vpc_id         = awscc_ec2_vpc.use2[k].vpc_id
        vpc_cidr       = v.vpc_cidr
        subnet_2a_id   = awscc_ec2_subnet.use2_2a[k].subnet_id
        subnet_2a_cidr = v.subnet_1a_cidr
        subnet_2b_id   = awscc_ec2_subnet.use2_2b[k].subnet_id
        subnet_2b_cidr = v.subnet_1b_cidr
      }
    }
  }
}

# ============================================
# EC2 Instance Outputs
# ============================================

output "ec2_instances" {
  description = "Summary of all EC2 instances deployed"
  value = {
    prod_use1_vpc_1 = {
      instance_id       = module.ec2_prod_use1_vpc_1.instance_id
      instance_ip       = module.ec2_prod_use1_vpc_1.instance_private_ip
      availability_zone = module.ec2_prod_use1_vpc_1.instance_availability_zone
    }
    prod_use1_vpc_2 = {
      instance_id       = module.ec2_prod_use1_vpc_2.instance_id
      instance_ip       = module.ec2_prod_use1_vpc_2.instance_private_ip
      availability_zone = module.ec2_prod_use1_vpc_2.instance_availability_zone
    }
    dev_use1_vpc_1 = {
      instance_id       = module.ec2_dev_use1_vpc_1.instance_id
      instance_ip       = module.ec2_dev_use1_vpc_1.instance_private_ip
      availability_zone = module.ec2_dev_use1_vpc_1.instance_availability_zone
    }
    prod_use2_vpc_1 = {
      instance_id       = module.ec2_prod_use2_vpc_1.instance_id
      instance_ip       = module.ec2_prod_use2_vpc_1.instance_private_ip
      availability_zone = module.ec2_prod_use2_vpc_1.instance_availability_zone
    }
    cust_use2_vpc_1 = {
      instance_id       = module.ec2_cust_use2_vpc_1.instance_id
      instance_ip       = module.ec2_cust_use2_vpc_1.instance_private_ip
      availability_zone = module.ec2_cust_use2_vpc_1.instance_availability_zone
    }
    cust_use2_vpc_2 = {
      instance_id       = module.ec2_cust_use2_vpc_2.instance_id
      instance_ip       = module.ec2_cust_use2_vpc_2.instance_private_ip
      availability_zone = module.ec2_cust_use2_vpc_2.instance_availability_zone
    }
  }
}
