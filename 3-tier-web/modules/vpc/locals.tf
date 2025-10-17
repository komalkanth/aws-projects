/* Default tags for all resources created together */

locals {
  default_tags = {
    Environment  = var.environment
    Organization = var.organization
  }
}



/* locals public_subnet_set takes below input
public_subnet_cidr_map  = {
    "us-east-1a": {
      "subnet-1": "10.1.0.0/24"
    }
    "us-east-1b": {
      "subnet-1": "10.1.1.0/24"
      }
    "us-east-1c": {
      "subnet-1": "10.1.3.0/24"
      "subnet-2": "10.1.4.0/24"
      }
  }

Creates multiple maps with all relevant configs grouped together
+ locals_output = {
    + public_subnet_locals = [
        + {
            + availability_zone = "us-east-1a"
            + cidr_block        = "10.1.0.0/24"
            + subnet_number     = "pub-1a-1"
          },
        + {
            + availability_zone = "us-east-1b"
            + cidr_block        = "10.1.1.0/24"
            + subnet_number     = "pub-1b-1"
          },
        + {
            + availability_zone = "us-east-1c"
            + cidr_block        = "10.1.3.0/24"
            + subnet_number     = "pub-1c-1"
          },
        + {
            + availability_zone = "us-east-1c"
            + cidr_block        = "10.1.4.0/24"
            + subnet_number     = "pub-1c-2"
          },
      ]
  }   */

locals {
  public_subnet_set = flatten([
    for selected_az, public_subnet_map in var.public_subnet_cidr_map : [
      for subnetnumber, attrib_map in public_subnet_map : {
        availability_zone = data.aws_availability_zone.az_name_from_id[selected_az].name
        selected_az       = selected_az
        cidr_block        = attrib_map[0]
        purpose           = attrib_map[1]
        subnet_number     = "pub-${substr(attrib_map[1], 0, 3)}-${substr(data.aws_availability_zone.az_name_from_id[selected_az].name, -2, -1)}"
      }
    ]
  ])
}


locals {
  private_subnet_set = flatten([
    for selected_az, private_subnet_map in var.private_subnet_cidr_map : [
      for subnetnumber, attrib_map in private_subnet_map : {
        availability_zone = data.aws_availability_zone.az_name_from_id[selected_az].name
        selected_az       = selected_az
        cidr_block        = attrib_map[0]
        purpose           = attrib_map[1]
        subnet_number     = "pvt-${substr(attrib_map[1], 0, 3)}-${substr(data.aws_availability_zone.az_name_from_id[selected_az].name, -2, -1)}"
      }
    ]
  ])
}



/* Produces a list of all the subnet CIDRs used for public subnets similar to below example
"public_subnet_cidr_list" = [
  "10.1.0.0/24",
  "10.1.1.0/24",
  "10.1.3.0/24",
  "10.1.4.0/24",
] */

locals {
  public_subnet_cidr_list = flatten([
    for selected_az, public_subnet_map in var.public_subnet_cidr_map : [
      for subnet_number, subnet_cidr in public_subnet_map : subnet_cidr
    ]
  ])
}

locals {
  private_subnet_cidr_list = flatten([
    for selected_az, private_subnet_map in var.private_subnet_cidr_map : [
      for subnet_number, subnet_cidr in private_subnet_map : subnet_cidr
    ]
  ])
}



/* Produces a map of subnet name to subnet ID similar to below
"public_subnet_name2id_map" = {
  "prod-usea1-vpc1-pub-1a-1" = "subnet-0c3b7a3ede8027c88"
  "prod-usea1-vpc1-pub-1b-1" = "subnet-044c00a73b2de4470"
  "prod-usea1-vpc1-pub-1c-1" = "subnet-0bcdd1dc534433aa7"
  "prod-usea1-vpc1-pub-1c-2" = "subnet-078919335491582dc"
} */

locals {
  public_subnet_name2id_map = {
    for subnet_key, subnetdetails in aws_subnet.public_subnet : subnet_key => subnetdetails.id
  }
}

locals {
  private_web_subnet_map = {
    for subnet_key, subnet_details in aws_subnet.private_subnet :
    subnet_key => subnet_details.id
    if lookup(subnet_details.tags, "purpose", "") == "web"
  }
}

locals {
  private_app_subnet_map = {
    for subnet_key, subnet_details in aws_subnet.private_subnet :
    subnet_key => subnet_details.id
    if lookup(subnet_details.tags, "purpose", "") == "app"
  }
}

locals {
  private_db_subnet_map = {
    for subnet_key, subnet_details in aws_subnet.private_subnet :
    subnet_key => subnet_details.id
    if lookup(subnet_details.tags, "purpose", "") == "db"
  }
}


locals {
  public_subnet_cidr_id_map = flatten([{
    for subnetkey, subnetdetails in aws_subnet.public_subnet : subnetdetails.tags.Name => {
      "subnet_cidr_block" = subnetdetails.cidr_block
      "subnet_id"         = subnetdetails.id
    }
    }
  ])
}

locals {
  private_subnet_cidr_id_map = {
    for subnetkey, subnetdetails in aws_subnet.private_subnet : subnetdetails.tags.Name => { "${subnetdetails.cidr_block}" = subnetdetails.id }
  }
}


# Produces a list of public subnets where NAT Gateway is enabled based on natgw_enabled variable

# # Input map below
#   natgw_enabled = {
#     "az1" : true
#     "az2" : false
#     "az3" : true
#   }
# # gets output like below
#     "public_subnets_with_natgw_enabled = [
#       "10.75.2.0/24-az1",
#       "10.75.1.0/24-az3",
#     ]

locals {
  public_subnets_with_natgw_enabled = flatten([
    for az, subnet_map in var.public_subnet_cidr_map : [
      for subnet_number, subnet_details in subnet_map : "${subnet_details[0]}-${az}"
      if lookup(var.natgw_enabled, az, false) == true
    ]
  ])
}
