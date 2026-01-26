# VPC Infrastructure for CloudWAN Project

This Terraform configuration creates multiple VPCs across two AWS regions (us-east-1 and us-east-2) as part of the CloudWAN project.

## Architecture Overview

This configuration creates **6 VPCs** across **2 AWS regions**:

### US-EAST-1 Region
1. **prod-use1-vpc-1** - Production VPC with CIDR 10.0.0.0/24
2. **prod-use1-vpc-2** - Production VPC with CIDR 10.0.1.0/24
3. **dev-use1-vpc-1** - Development VPC with CIDR 10.0.10.0/24

### US-EAST-2 Region
1. **prod-use2-vpc-1** - Production VPC with CIDR 10.0.2.0/24
2. **cust-use2-vpc-1** - Customer VPC with CIDR 10.0.20.0/24
3. **cust-use2-vpc-2** - Customer VPC with CIDR 10.0.21.0/24

## Features

Each VPC includes:
- ✅ **2 Subnets** across different Availability Zones (AZ-a and AZ-b)
- ✅ **Internet Gateway** for internet connectivity
- ✅ **Public Route Table** with route to Internet Gateway (0.0.0.0/0)
- ✅ **Route Table Associations** for both subnets
- ✅ **DNS Support** and **DNS Hostnames** enabled
- ✅ **Comprehensive Tagging** for resource management

## Prerequisites

- Terraform >= 1.13
- AWS credentials configured with appropriate permissions
- AWS provider (v6.25) - for us-east-1 and us-east-2 VPCs, subnets, EC2, IAM, and DynamoDB resources
- AWSCC provider (v1.0+) - for CloudWAN VPC attachments and network management
- S3 bucket for Terraform state: `terraformstatebucketkk` (in us-east-1)
- DynamoDB table: `cloudwan-terraform-outputs` (for storing Core Network ARN from cwan module and VPC outputs)
- Providers are automatically configured and installed

## Usage

### 1. Initialize Terraform

```bash
terraform init
```

### 2. Validate Configuration

```bash
terraform validate
```

### 3. Review the Execution Plan

```bash
terraform plan
```

### 4. Apply the Configuration

```bash
terraform apply
```

### 5. Destroy Resources (when needed)

```bash
terraform destroy
```

## Backend Configuration

This configuration uses an S3 backend to store Terraform state:

```hcl
backend "s3" {
  bucket  = "terraformstatebucketkk"
  key     = "cloudwan/vpc/terraform.tfstate"
  region  = "us-east-1"
  profile = "default"
  encrypt = true
}
```

> **Note**: The S3 bucket must exist before running `terraform init`. The state includes all VPC, subnet, EC2, and CloudWAN attachment information.

## Configuration Structure

```
vpc/
├── providers.tf                  # Terraform config & AWS/AWSCC provider setup
│                                # - S3 backend: cloudwan/vpc/terraform.tfstate
│                                # - AWS provider (default & us-east-2 alias)
│                                # - AWSCC provider (default & us-east-2 alias)
├── variables.tf                  # Input variable definitions (VPC, DynamoDB, tags)
├── terraform.tfvars              # Variable values for all 6 VPCs
├── main.tf                       # VPC, subnet, IGW, route table resources
│                                # - us-east-1: AWS provider (aws_vpc, aws_subnet, etc.)
│                                # - us-east-2: AWS provider with us-east-2 alias
├── data-dynamodb.tf              # Data source: Core Network ARN from DynamoDB table
├── dynamodb.tf                   # DynamoDB table item: Persists VPC output values
├── cloudwan-attachment.tf        # AWSCC VPC attachments to Core Network (with segments)
├── ec2-instances.tf              # EC2 instance module instantiation (for_each over VPCs)
├── outputs.tf                    # Output definitions (VPC, subnet, IGW, route table IDs)
├── .terraform.lock.hcl           # Terraform dependency lock file
├── terraform.tfstate             # Local state (should use S3 backend in production)
├── terraform.tfvars              # VPC configuration values
├── vpc-config.json               # VPC configuration reference (JSON format)
├── README.md                     # This file
├── modules/
│   └── ec2-instance/            # Reusable EC2 instance module
│       ├── main.tf              # EC2, IAM role, security group resources
│       ├── variables.tf          # Module input variables
│       └── outputs.tf            # Module output definitions
└── .terraform/                   # Local Terraform cache directory
```

## Outputs

After applying, Terraform will output:
- **VPC IDs**: For each region (us-east-1 and us-east-2)
- **Subnet IDs**: AZ 1a and 1b for us-east-1; AZ 2a and 2b for us-east-2
- **Internet Gateway IDs**: For each region
- **Route Table IDs**: For each VPC
- **VPC Summary**: Comprehensive map of all VPC configurations including CIDR blocks
- **EC2 Instance Details**: Instance IDs, private IPs, and availability zones
- **CloudWAN Attachments**: Attachment IDs and states
- **Core Network ARN**: Fetched from DynamoDB table

## DynamoDB Integration

This configuration integrates with the Core Network created by the `cwan` module:

### Reading Core Network ARN

The `data-dynamodb.tf` file reads the Core Network ARN from the DynamoDB table (`cloudwan-terraform-outputs`) created by the cwan module. This ARN is used to:
- Extract the Core Network ID for VPC attachments
- Dynamically reference the core network without hardcoding values

### Storing VPC Outputs

The `dynamodb.tf` file persists all VPC outputs to the same DynamoDB table under the `vpc` item:
- VPC IDs, subnet IDs, and IGW IDs for both regions
- Route table IDs and comprehensive VPC summary
- Enables other infrastructure modules to reference VPC values

## CloudWAN Attachments

VPC attachments to the Core Network are configured in `cloudwan-attachment.tf`:

### Attached VPCs

| VPC Name | Region | Segment | Auto-Accept |
|----------|--------|---------|-------------|
| prod-use1-vpc-1 | us-east-1 | production | No |
| prod-use1-vpc-2 | us-east-1 | production | No |
| dev-use1-vpc-1 | us-east-1 | development | No |
| prod-use2-vpc-1 | us-east-2 | production | No |
| cust-use2-vpc-1 | us-east-2 | customer | Yes (requires manual acceptance) |
| cust-use2-vpc-2 | us-east-2 | customer | Yes (requires manual acceptance) |

### Attachment Features

- ✅ **Dynamic Core Network ID extraction**: Regex extraction from DynamoDB-stored ARN
- ✅ **ARN construction**: Dynamically builds VPC and subnet ARNs using account ID
- ✅ **Subnet redundancy**: Both AZ-a and AZ-b subnets attached for high availability
- ✅ **AWSCC provider**: Uses Cloud Control API for consistent attachment management
- ✅ **Comprehensive tagging**: Environment, VPC, and project tags for all attachments

## EC2 Instances

Each VPC is deployed with one **t2.micro** EC2 instance configured for **AWS Systems Manager Session Manager** access (console-based SSH without public IPs):

- **prod-use1-vpc-1**: Instance in AZ 1a
- **prod-use1-vpc-2**: Instance in AZ 1a
- **dev-use1-vpc-1**: Instance in AZ 1a
- **prod-use2-vpc-1**: Instance in AZ 2a (us-east-2)
- **cust-use2-vpc-1**: Instance in AZ 2a (us-east-2)
- **cust-use2-vpc-2**: Instance in AZ 2a (us-east-2)

Each instance includes:
- ✅ IAM role with Systems Manager permissions
- ✅ Security group allowing outbound traffic
- ✅ Latest Amazon Linux 2 AMI
- ✅ Environment and VPC tagging for management

### Managing EC2 Instances Only

The EC2 instances are defined as a single reusable module in `modules/ec2-instance/` that uses `for_each` to iterate through all VPCs. This allows flexible deployment and destruction of instances independently from VPCs:

#### Deploy Only EC2 Instances

If VPCs already exist, deploy only EC2 instances:

```bash
# Plan only EC2 module
terraform plan -target='module.ec2_instances'

# Apply only EC2 module
terraform apply -target='module.ec2_instances'
```

#### Deploy EC2 Instances for Specific VPCs

```bash
# Example: Deploy only instances for prod VPCs
terraform apply -target='module.ec2_instances["prod-use1-vpc-1"]' \
                -target='module.ec2_instances["prod-use1-vpc-2"]' \
                -target='module.ec2_instances["prod-use2-vpc-1"]'
```

#### Destroy Only EC2 Instances (Preserve VPCs)

To destroy **only** the EC2 instances while keeping all VPCs and networking intact:

```bash
# Destroy all EC2 instances
terraform destroy -target='module.ec2_instances'
```

#### Destroy EC2 Instances for Specific VPCs

```bash
# Example: Destroy only instance in prod-use1-vpc-1
terraform destroy -target='module.ec2_instances["prod-use1-vpc-1"]'

# Example: Destroy instances for all dev VPCs
terraform destroy -target='module.ec2_instances["dev-use1-vpc-1"]' \
                  -target='module.ec2_instances["dev-use2-vpc-1"]' \
                  -target='module.ec2_instances["dev-use2-vpc-2"]'
```

#### Destroy Only a Single VPC and All Its Resources

```bash
# Example: Destroy everything in prod-use1-vpc-1 (VPC, subnets, instance, IGW, etc.)
terraform destroy -target='aws_vpc.use1["prod-use1-vpc-1"]'
```

**Note:** When destroying a VPC, dependent resources (subnets, route tables, instances, etc.) are automatically removed. Use terraform plan first to verify what will be destroyed.

### Access EC2 Instances via Systems Manager

After deploying, access instances using AWS Systems Manager Session Manager:

```bash
# List available instances
aws ssm describe-instances --query 'Reservations[*].Instances[*].[InstanceId,Tags[?Key==`Name`].Value|[0]]' --output table

# Connect to instance via Session Manager (console-based)
# Use AWS Management Console > Systems Manager > Session Manager > Start session
# Or via CLI:
aws ssm start-session --target <instance-id>
```

## Resource Naming Convention

Resources follow this naming pattern:
- VPCs: `{environment}-{region}-vpc-{number}` (e.g., prod-use1-vpc-1)
- Subnets: `{vpc-name}-subnet-{az}` (e.g., prod-use1-vpc-1-subnet-1a)
- Internet Gateways: `{vpc-name}-igw`
- Route Tables: `{vpc-name}-public-rt`

## Tags

All resources are tagged with:
- **Name**: Resource-specific name
- **Environment**: Production (prod) or Development (dev)
- **ManagedBy**: Terraform
- **Project**: CloudWAN
- **VPC**: Associated VPC name (for subnets and networking resources)

## Security Considerations

- All subnets are public with internet access via Internet Gateway
- DNS resolution enabled for all VPCs
- Consider adding NACLs and Security Groups for additional security layers
- Review and implement least-privilege IAM policies for Terraform execution

## Customization

To modify VPC configurations, edit the `terraform.tfvars` file. You can:
- Add or remove VPCs
- Change CIDR blocks
- Modify subnet configurations
- Enable/disable Internet Gateways

## Implementation Details

### Provider Strategy

This configuration uses a **regional provider approach** for managing resources across AWS regions:

| Component | Region | Provider | Resource Type | Purpose |
|-----------|--------|----------|---------------|---------|
| **VPCs & Subnets** | us-east-1 | AWS (default) | `aws_vpc`, `aws_subnet` | Primary region VPC management |
| **VPCs & Subnets** | us-east-2 | AWS (use2 alias) | `aws_vpc`, `aws_subnet` | Secondary region VPC management |
| **IGW & Routes** | us-east-1 | AWS (default) | `aws_internet_gateway`, `aws_route` | Primary region internet access |
| **IGW & Routes** | us-east-2 | AWS (use2 alias) | `aws_internet_gateway`, `aws_route` | Secondary region internet access |
| **CloudWAN Attachments** | Both | AWSCC (default) | `awscc_networkmanager_vpc_attachment` | Cloud Control API for attachment management |
| **EC2 Instances** | Both | AWS | `aws_instance`, `aws_iam_role` | EC2 and IAM resources for all regions |
| **DynamoDB** | us-east-1 | AWS (default) | `aws_dynamodb_table_item` | DynamoDB operations in primary region |

### Provider Aliases

Multi-region deployment uses provider aliases configured in `providers.tf`:
- `awscc.use2`: AWSCC provider alias for us-east-2 region
- `aws.use2`: AWS provider alias for us-east-2 region

### Tagging Strategy

All resources follow consistent tagging conventions:
- **Name**: Descriptive resource name (e.g., vpc-name, subnet-1a)
- **Environment**: extracted from VPC name prefix (prod, dev, or cust)
- **Project**: CloudWAN
- **ManagedBy**: Terraform
- **VPC**: Associated VPC name (for subnets and networking resources)

Note: AWS provider uses map format `{key = value}` while AWSCC provider uses list format `[{key = "name", value = "value"}]`

### Resource Organization

- **VPC & Networking**: Separated by region using `for_each` loops with locals (`local.use1_vpcs`, `local.use2_vpcs`)
- **EC2 Instances**: Deployed as a reusable module with `for_each` iterating over all VPCs
- **CloudWAN Attachments**: Individual resources for each VPC with segment-based association
- **DynamoDB**: Shared table for storing outputs from all CloudWAN-related modules

### Dynamic Configuration

- All VPC configurations defined in `terraform.tfvars` for easy customization
- Core Network ARN dynamically fetched from DynamoDB (no hardcoding required)
- Account ID automatically determined using `data.aws_caller_identity`
- Subnet and VPC ARNs dynamically constructed for CloudWAN attachments

### Networking Features

- **IPv4 Only**: All VPCs support IPv4 CIDR blocks (IPv6 can be added if needed)
- **DNS Enabled**: DNS support and DNS hostnames enabled for all VPCs
- **High Availability**: Each VPC has 2 subnets across different AZs
- **Internet Access**: All VPCs include Internet Gateway for public internet connectivity
- **Public Route Tables**: Each VPC has route table with 0.0.0.0/0 route to IGW

## Support

For issues or questions related to this infrastructure, please refer to the source instructions in `vpc-creation-instructions.md`.
