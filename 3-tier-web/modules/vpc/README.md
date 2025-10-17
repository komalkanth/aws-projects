# AWS VPC Terraform Module

A comprehensive Terraform module for creating a multi-tier VPC architecture with public and private subnets across multiple availability zones.

## Features

- Multi-AZ VPC deployment with customizable CIDR blocks
- Separate public and private subnets for web, app, and database tiers
- Internet Gateway for public subnet internet access
- NAT Gateways for private subnet outbound connectivity
- Dedicated route tables for each subnet tier
- Network ACLs for additional security
- Flexible subnet configuration using AZ IDs

## Architecture

The module creates:
- 1 VPC with configurable CIDR
- Public subnets (1 per AZ) with Internet Gateway access
- Private subnets (3 per AZ: web, app, db tiers)
- NAT Gateways in public subnets (configurable per AZ)
- Route tables for proper traffic routing
- Network ACLs for subnet-level security

## Usage

```hcl
module "vpc" {
  source = "./modules/vpc"

  region            = "us-east-1"
  region_short_name = "use1"
  organization      = "kkoncloud.net"
  environment       = "dev"
  vpc_name          = "vpc-1"
  vpc_main_cidr     = "10.75.0.0/16"

  public_subnet_cidr_map = {
    "az1": {
      "subnet-1": ["10.75.2.0/24", "internet-access"]
    }
    "az2": {
      "subnet-1": ["10.75.0.0/24", "internet-access"]
    }
    "az3": {
      "subnet-1": ["10.75.1.0/24", "internet-access"]
    }
  }

  private_subnet_cidr_map = {
    "az1": {
      "subnet-1": ["10.75.5.0/24", "web"]
      "subnet-2": ["10.75.8.0/24", "app"]
      "subnet-3": ["10.75.11.0/24", "db"]
    }
    "az2": {
      "subnet-1": ["10.75.3.0/24", "web"]
      "subnet-2": ["10.75.6.0/24", "app"]
      "subnet-3": ["10.75.9.0/24", "db"]
    }
    "az3": {
      "subnet-1": ["10.75.4.0/24", "web"]
      "subnet-2": ["10.75.7.0/24", "app"]
      "subnet-3": ["10.75.10.0/24", "db"]
    }
  }

  natgw_enabled = {
    "az1": true
    "az2": true
    "az3": true
  }

  default_tags = {
    environment  = "dev"
    organization = "kkoncloud.net"
  }
}
```

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| region | AWS region for deployment | `string` | `"us-east-1"` | no |
| region_short_name | Short name for region (e.g., use1) | `string` | `""` | yes |
| vpc_main_cidr | Main IPv4 CIDR block for VPC | `string` | n/a | yes |
| vpc_name | Name for the VPC | `string` | n/a | yes |
| environment | Environment name (dev, prod, etc.) | `string` | n/a | yes |
| organization | Organization name | `string` | n/a | yes |
| public_subnet_cidr_map | Map of public subnet configurations by AZ | `map(any)` | `{}` | no |
| private_subnet_cidr_map | Map of private subnet configurations by AZ | `map(any)` | `{}` | no |
| natgw_enabled | Map to enable/disable NAT Gateway per AZ | `map(bool)` | `{}` | no |
| default_tags | Default tags to apply to all resources | `map(string)` | n/a | yes |

## Subnet Configuration Format

### Public Subnets
```hcl
public_subnet_cidr_map = {
  "az1": {
    "subnet-1": ["CIDR_BLOCK", "PURPOSE"]
  }
}
```

### Private Subnets
```hcl
private_subnet_cidr_map = {
  "az1": {
    "subnet-1": ["CIDR_BLOCK", "web"]
    "subnet-2": ["CIDR_BLOCK", "app"] 
    "subnet-3": ["CIDR_BLOCK", "db"]
  }
}
```

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | ID of the created VPC |
| nat_gateway_ids | Map of NAT Gateway IDs by AZ |

## Resources Created

### Core Infrastructure
- `aws_vpc.main` - Main VPC
- `aws_internet_gateway.main_igw` - Internet Gateway
- `aws_subnet.public_subnet` - Public subnets
- `aws_subnet.private_subnet` - Private subnets

### NAT Gateway Resources
- `aws_eip.natgw_eip` - Elastic IPs for NAT Gateways
- `aws_nat_gateway.networking_natgw` - NAT Gateways

### Routing Resources
- `aws_route_table.pub_rt` - Public route table
- `aws_route_table.pvt_web_rt` - Private web tier route tables
- `aws_route_table.pvt_app_rt` - Private app tier route tables
- `aws_route_table.pvt_db_rt` - Private database tier route tables
- Route table associations for all subnets
- Default routes for internet and NAT Gateway access

### Security Resources
- `aws_network_acl.public_subnet_nacl` - Public subnet Network ACL
- `aws_network_acl.private_subnet_nacl` - Private subnet Network ACL

## Naming Convention

Resources follow this naming pattern:
```
{environment}-{region_short}-{vpc_name}-{resource_type}-{az}
```

Examples:
- VPC: `dev-use1-vpc1`
- Public Subnet: `dev-use1-vpc1-pub-int-1a`
- Private Subnet: `dev-use1-vpc1-web-pvt-1a`
- NAT Gateway: `dev-use1-natgw-az1`

## AZ ID Mapping

The module uses AZ IDs (az1, az2, az3) which map to actual availability zones:
- `az1` → First AZ in region (e.g., us-east-1a)
- `az2` → Second AZ in region (e.g., us-east-1b)  
- `az3` → Third AZ in region (e.g., us-east-1c)

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.13.1 |
| aws | >= 5.97.0 |

## Notes

- NAT Gateways are optional and can be enabled/disabled per AZ
- Each private subnet tier (web, app, db) gets its own route table
- Network ACLs are currently configured to allow all traffic
- All resources are tagged with environment and organization tags
- The module supports flexible subnet configuration across multiple AZs