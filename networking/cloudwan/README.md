# AWS CloudWAN with Inspection VPC - Complete Infrastructure

This repository contains a comprehensive Terraform configuration for a multi-region AWS CloudWAN deployment integrated with a centralized inspection VPC featuring Palo Alto Networks firewall and Gateway Load Balancer (GWLB).

## 📋 Overview

This infrastructure implements an enterprise-grade wide area network (WAN) architecture with:
- **AWS CloudWAN**: Global network management across three AWS regions with automatic routing policies
- **Multiple VPCs**: 6 VPCs distributed across us-east-1 and us-east-2 for development, production, and customer workloads
- **Inspection VPC**: Centralized security inspection hub in us-west-1 with Palo Alto VM-Series firewall
- **Gateway Load Balancer**: For transparent traffic steering to inspection appliances
- **DynamoDB Integration**: Centralized configuration sharing between modules

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                    AWS CloudWAN - Global Network                    │
│                                                                     │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │                       Core Network                             │ │
│  │         (VPN ECMP Disabled, 3 Edge Locations)                  │ │
│  │                                                                │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │ │
│  │  │  us-east-1   │  │  us-east-2   │  │  us-west-1   │          │ │
│  │  │  ASN: 64512  │  │  ASN: 64513  │  │  ASN: 64514  │          │ │
│  │  └──────────────┘  └──────────────┘  └──────────────┘          │ │
│  │                                                                │ │
│  │  Network Segments:                                             │ │
│  │  • default (required)                                          │ │
│  │  • production (prod VPCs)                                      │ │
│  │  • development (dev VPCs)                                      │ │
│  │  • customer (customer VPCs, requires acceptance)               │ │
│  └────────────────────────────────────────────────────────────────┘ │
│                                                                     │
│  ┌────────────┐        ┌────────────┐        ┌────────────┐         │
│  │ Production │        │   Dev      │        │ Inspection │         │
│  │   VPCs     │        │   VPC      │        │    VPC     │         │
│  │ (us-east1) │        │ (us-east1) │        │ (us-west1) │         │
│  │            │        │            │        │            │         │
│  │  prod-*    │        │  dev-*     │        │ 10.0.100/23│         │
│  │ 10.0.0/24  │        │ 10.0.10/24 │        │            │         │
│  │ 10.0.1/24  │        │            │        │ Firewall:  │         │
│  │            │        │            │        │ - 2 PANs   │         │
│  │ Attached   │        │ Attached   │        │ - GWLB     │         │
│  └────────────┘        └────────────┘        │ - GWLBe    │         │
│         │                     │              └────────────┘         │
│         │                     │                       │             │
│         └─────────────────────┴───────────────────────┘             │
│                  VPC Attachments via CloudWAN                       │
│                                                                     │
│  ┌────────────┐        ┌────────────┐                               │
│  │ Customer   │        │ Customer   │                               │
│  │   VPCs     │        │   VPCs     │                               │
│  │ (us-east2) │        │ (us-east2) │                               │
│  │            │        │            │                               │
│  │  cust-*    │        │  cust-*    │                               │
│  │ 10.0.20/24 │        │ 10.0.21/24 │                               │
│  │ 10.0.21/24 │        │            │                               │
│  │            │        │            │                               │
│  │ Attached   │        │ Attached   │                               │
│  └────────────┘        └────────────┘                               │
│         │                     │                                     │
│         └─────────────────────┘                                     │
│           (Route Sharing via Segment Actions)                       │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

## 📁 Repository Structure

```
cloudwan/
├── README.md                    # This file - Complete infrastructure overview
├── cwan/                        # CloudWAN Core Network Module
│   ├── main.tf                 # Global Network & Core Network resources
│   ├── core_policy.tf          # Core Network Policy with segments & routing
│   ├── providers.tf            # Terraform & AWS provider configuration
│   ├── dynamodb.tf             # DynamoDB integration for outputs
│   ├── output.tf               # Outputs: Global Network ID, Core Network ID/ARN
│   ├── README.md               # Detailed CloudWAN documentation
│   └── .terraform.lock.hcl     # Provider dependency lock file
│
├── vpc/                         # VPC Infrastructure Module
│   ├── main.tf                 # VPC, Subnet, IGW, and Route Table resources
│   ├── variables.tf            # Input variable definitions
│   ├── terraform.tfvars        # Variable values for 6 VPCs
│   ├── providers.tf            # Provider setup with multi-region support
│   ├── data-dynamodb.tf        # Data source for Core Network ARN
│   ├── dynamodb.tf             # VPC outputs storage
│   ├── ec2-instances.tf        # Optional EC2 instances for testing
│   ├── outputs.tf              # VPC, subnet, and attachment outputs
│   ├── vpc-config.json         # VPC configuration reference
│   ├── README.md               # VPC infrastructure details
│   └── .terraform.lock.hcl     # Provider dependency lock file
│
└── inspection-vpc/             # Inspection VPC with Firewall & GWLB Module
    ├── main.tf                 # VPC and Internet Gateway
    ├── variables.tf            # Input variables
    ├── providers.tf            # AWS & AWSCC provider configuration
    ├── routing.tf              # Route tables for all subnet types
    ├── firewall.tf             # Palo Alto VM-Series firewall instances
    ├── gwlb.tf                 # Gateway Load Balancer & VPC endpoints
    ├── sg.tf                   # Security groups
    ├── cloudwan-attachment.tf  # CloudWAN VPC attachment
    ├── dynamodb.tf             # Inspection VPC outputs storage
    ├── outputs.tf              # All resource outputs
    ├── inspection-vpc-config.json  # Configuration reference
    ├── README.md               # Detailed inspection VPC documentation
    ├── TODO.md                 # Project notes & remaining tasks
    └── .terraform.lock.hcl     # Provider dependency lock file
```

## 🚀 Component Details

### 1. CloudWAN Core Network (`cwan/`)

**Purpose**: Provides global network management and automatic routing across regions.

**Key Resources**:
- **Global Network**: Container for the core network and all network objects
- **Core Network**: Spans three edge locations (us-east-1, us-east-2, us-west-1) with base policy
- **Network Segments**: 4 segments for traffic isolation
  - `default`: Required minimum configuration
  - `production`: For production VPCs (Environment: prod tag)
  - `development`: For development VPCs (Environment: dev tag)
  - `customer`: For customer VPCs (Environment: customer tag, requires acceptance)

**Attachment Policies**:
Automatic VPC-to-segment routing based on tags:

| Rule | Condition | Segment |
|------|-----------|---------|
| 100  | Environment: prod + VPC attachment | production |
| 200  | Environment: dev + VPC attachment | development |
| 300  | Environment: customer + VPC attachment | customer |

**Segment Actions**:
- Production segment routes are shared with customer segment (attachment-route mode), allowing customer VPCs to reach production resources

**Configuration**:
- VPN ECMP: Disabled
- Region Availability: us-east-1, us-east-2, us-west-1

### 2. VPC Infrastructure (`vpc/`)

**Purpose**: Creates 6 VPCs distributed across two regions for various workloads.

**VPC Deployment**:

| Region | VPC Name | CIDR | Type | Purpose |
|--------|----------|------|------|---------|
| us-east-1 | prod-use1-vpc-1 | 10.0.0.0/24 | Production | Production workload 1 |
| us-east-1 | prod-use1-vpc-2 | 10.0.1.0/24 | Production | Production workload 2 |
| us-east-1 | dev-use1-vpc-1 | 10.0.10.0/24 | Development | Development workloads |
| us-east-2 | prod-use2-vpc-1 | 10.0.2.0/24 | Production | Production workload (HA) |
| us-east-2 | cust-use2-vpc-1 | 10.0.20.0/24 | Customer | Customer workload 1 |
| us-east-2 | cust-use2-vpc-2 | 10.0.21.0/24 | Customer | Customer workload 2 |

**Features per VPC**:
- ✅ 2 Subnets across different AZs (AZ-a and AZ-b)
- ✅ Internet Gateway with public routing (0.0.0.0/0)
- ✅ DNS support and DNS hostnames enabled
- ✅ Automatic CloudWAN attachment via tags
- ✅ Multi-region provider configuration

**CloudWAN Attachments**:
- VPCs are automatically attached to the core network based on Environment tags
- Attachment policies route traffic to appropriate segments

### 3. Inspection VPC with Firewall (`inspection-vpc/`)

**Purpose**: Provides centralized traffic inspection and filtering for the entire CloudWAN network.

**VPC Configuration**:
- **Region**: us-west-1 (North California)
- **CIDR**: 10.0.100.0/23 (512 IP addresses)
- **AZs**: us-west-1a and us-west-1b (HA across zones)
- **Subnet Size**: Each subnet is /27 (32 IP addresses)

**Subnet Types** (8 total, 4 per AZ):

| Subnet Type | Purpose | Count | Internet Access | Route Table |
|-------------|---------|-------|-----------------|-------------|
| fw-mgmt-subnet-* | Firewall management interfaces | 2 | ✅ Yes | igw-route |
| fw-data-subnet-* | Firewall data plane interfaces | 2 | ❌ No | N/A |
| gwlb-endpnt-subnet-* | Gateway LB endpoints | 2 | ❌ No | N/A |
| core-network-subnet-* | CloudWAN attachment | 2 | ❌ No | cwan-route |

**Security Infrastructure**:

1. **Palo Alto VM-Series Firewall**
   - 2 instances (one per AZ) for high availability
   - 3 network interfaces per instance:
     - Management interface (fw-mgmt-subnet) - for Panorama/console access
     - Data interface (fw-data-subnet) - for east-west traffic inspection
     - HA interface (fw-data-subnet) - for high availability heartbeat
   - Auto-assigned Elastic IPs for management access

2. **Gateway Load Balancer**
   - Transparently distributes traffic to firewall instances
   - Creates VPC endpoint service for traffic steering
   - Target group monitors firewall health
   - Integrates with CloudWAN for automatic traffic interception

3. **Traffic Flow**:
   ```
   CloudWAN Traffic
        ↓
   GWLBe Endpoint (us-west-1)
        ↓
   Gateway Load Balancer
        ↓
   Palo Alto Firewall Instances (HA)
        ↓
   Decision: Allow/Block/Log
        ↓
   Return to CloudWAN
   ```

**CloudWAN Integration**:
- Core network subnets attached to CloudWAN core network
- DynamoDB retrieves core network ARN from cwan module
- AWSCC provider ensures modern API compatibility
- Automatic segment association (inspection segment expected)

**Security Groups**:
- Firewall management: SSH/HTTPS access from authorized IPs
- Firewall data: All traffic between firewall instances and inspection VPC

## 🔄 Data Flow & Traffic Paths

### VPC-to-VPC Communication via CloudWAN

1. **Production to Production** (us-east-1 to us-east-2):
   - prod-use1-vpc-1 → CloudWAN production segment → prod-use2-vpc-1
   - Direct connectivity through core network

2. **Production to Development** (us-east-1):
   - prod-use1-vpc-1 → CloudWAN → dev-use1-vpc-1
   - Different segments (no direct route by default)

3. **Production to Customer**:
   - Production segment routes shared with customer segment
   - prod-use2-vpc-1 → CloudWAN (attachment-route) → cust-use2-vpc-1/vpc-2
   - Customer VPCs can reach production resources

### Traffic Inspection Path (via Inspection VPC)

Currently, the inspection VPC is attached to CloudWAN but traffic steering to the firewall requires:
1. **Route policies** in CloudWAN core network policy (define inspection as next hop)
2. **GWLB endpoint** configuration to intercept specific traffic flows
3. **Return path** configuration through GWLB for bidirectional inspection

This represents a **centralized security inspection model** where:
- All inter-VPC traffic can be routed through inspection VPC
- Firewall provides deep packet inspection, threat prevention, and logging
- Results in single point of control for security policies

## 📊 Connectivity Matrix

| From | To | Path | Status |
|------|-----|------|--------|
| prod-use1 → prod-use2 | CloudWAN (prod segment) | ✅ Direct |
| prod-use1 → dev-use1 | CloudWAN (different segments) | ⚠️ No route* |
| prod-use1 → cust-use2 | CloudWAN (segment sharing) | ✅ Allowed (via attachment-route) |
| prod-use2 → cust-use2 | CloudWAN (segment sharing) | ✅ Allowed (via attachment-route) |
| Any VPC → Inspection | CloudWAN + GWLB | ⚠️ Configured, needs route policy |
| Inspection → Firewall | GWLB | ✅ Active |

*Route policies in core network policy control segment connectivity.

## 🔐 Security Features

### Network Segmentation
- **CloudWAN Segments**: Automatic traffic isolation based on workload types
- **VPC CIDR Segregation**: Non-overlapping CIDRs (10.0.x.x range)
- **Subnet Type Segregation**: Specialized subnets for different functions

### Firewall Protection
- **Palo Alto VM-Series**: Industry-leading threat prevention
- **High Availability**: 2 instances across AZs with HA heartbeat
- **GWLB**: Non-intrusive, transparent traffic steering
- **Centralized Logging**: All inspection events logged and available for analysis

### IAM & Access Control
- **Tag-based policies**: Automatic segment assignment via tags
- **Default tags**: Applied to all resources for tracking and compliance
- **DynamoDB encryption**: State and configuration encrypted at rest

### Data Protection
- **S3 backend encryption**: Terraform state encrypted in S3
- **Elastic IPs**: Management access with public IPs (restricted by security groups)
- **VPC isolation**: No public internet routes except through IGW

## 🛠️ Prerequisites & Setup

### AWS Account Requirements
- AWS account with appropriate IAM permissions for:
  - Network Manager (CloudWAN)
  - EC2 (VPCs, subnets, security groups)
  - Elastic Load Balancing (GWLB)
  - DynamoDB
  - S3 (Terraform state)

### Required AWS Resources
1. **S3 Bucket** (for Terraform state):
   - Bucket name: `terraformstatebucketkk` (in us-east-1)
   - Must be created before running `terraform init`
   - Enable encryption and versioning

2. **DynamoDB Table** (for state sharing):
   - Table name: `cloudwan-project-tf-outputs`
   - Partition key: `project_component` (String)
   - Created automatically by cwan module

3. **EC2 Key Pair** (for firewall management):
   - Required in us-west-1 for Palo Alto management access
   - Used in inspection-vpc variables

### Local Requirements
- [Terraform](https://www.terraform.io/downloads.html) >= 1.13
- [AWS CLI](https://aws.amazon.com/cli/) configured with `default` profile
- Appropriate AWS IAM permissions
- SSH key pair for management access

### Provider Versions
- AWS Provider: v6.25 - v6.26
- AWSCC Provider: v1.66 - v1.67
- External Provider: v2.3 (for advanced data sources)

## 📋 Deployment Order

### Step 1: CloudWAN Core Network
```bash
cd cwan/
terraform init
terraform plan
terraform apply
# Outputs: Global Network ID, Core Network ID, Core Network ARN
```

### Step 2: VPC Infrastructure
```bash
cd ../vpc/
# Ensure DynamoDB table exists with core network ARN from Step 1
terraform init
terraform plan
terraform apply
# Outputs: VPC IDs, Subnet IDs, CloudWAN attachment IDs
```

### Step 3: Inspection VPC with Firewall
```bash
cd ../inspection-vpc/
# Ensure core network ARN is in DynamoDB
terraform init
terraform plan
terraform apply
# Outputs: Firewall IPs, GWLB DNS, VPC Endpoint Service Name
```

## 🔧 Configuration & Customization

### Modifying VPC Configuration
Edit [vpc/terraform.tfvars](vpc/terraform.tfvars) to add/modify VPCs:
- VPC names and CIDR blocks
- Subnet CIDRs and availability zones
- Tags and environment classification

### Customizing CloudWAN Policies
Edit [cwan/core_policy.tf](cwan/core_policy.tf) to:
- Add new network segments
- Modify attachment policies (tag conditions)
- Configure segment routing and filtering rules
- Adjust ASN values for regions

### Firewall Configuration
Edit [inspection-vpc/variables.tf](inspection-vpc/variables.tf) to:
- Change VPC CIDR and subnet structure
- Modify firewall instance types and count
- Configure EBS volume sizes
- Adjust security group rules

### DynamoDB Integration
- Core network ARN automatically exported to DynamoDB by cwan module
- VPC outputs automatically stored by vpc module
- Inspection VPC outputs automatically stored by inspection-vpc module
- Retrieve values via `data.aws_dynamodb_table_item` data sources

## 📤 Outputs

### CloudWAN Module Outputs
- `global_network_id`: Global Network identifier
- `core_network_id`: Core Network identifier
- `core_network_arn`: Core Network ARN (stored in DynamoDB)
- `core_network_policy_version_id`: Current policy version

### VPC Module Outputs
- `vpc_ids`: Map of VPC IDs
- `subnet_ids`: Map of subnet IDs
- `attachment_ids`: CloudWAN attachment IDs
- `deployment_outputs`: DynamoDB-stored outputs

### Inspection VPC Module Outputs
- `vpc_id`: Inspection VPC ID
- `subnet_ids`: Map of subnet IDs by type
- `route_table_ids`: Map of route table IDs
- `firewall_eni_ids`: Network interface IDs for both firewall instances
- `firewall_elastic_ips`: Public IPs for management access
- `gwlb_dns_name`: Gateway Load Balancer endpoint
- `vpc_endpoint_service_name`: GWLB VPC endpoint service
- `core_network_attachment_id`: CloudWAN attachment ID

## 📖 Documentation

Each module contains detailed documentation:
- [cwan/README.md](cwan/README.md): CloudWAN configuration details
- [vpc/README.md](vpc/README.md): VPC infrastructure details
- [inspection-vpc/README.md](inspection-vpc/README.md): Inspection VPC and firewall details

## 🧹 Cleanup

To destroy resources (in reverse order):

```bash
# Remove inspection VPC
cd inspection-vpc/
terraform destroy

# Remove VPCs
cd ../vpc/
terraform destroy

# Remove CloudWAN core network
cd ../cwan/
terraform destroy
```

**⚠️ Warning**: Destroying the CloudWAN core network will:
- Detach all VPCs
- Remove routing policies
- Delete all network segments
- This action cannot be undone immediately

## 🐛 Troubleshooting

### DynamoDB Table Not Found
**Issue**: `data.aws_dynamodb_table_item` fails to find core network ARN
**Solution**: Ensure cwan module is deployed first and outputs are stored in DynamoDB

### VPC Attachment Fails
**Issue**: VPC attachment to core network fails
**Solution**:
- Verify VPC has Environment tag matching segment definitions
- Check core network policy attachment is successful
- Ensure AWSCC provider version is compatible (v1.66+)

### Firewall Instance Fails to Launch
**Issue**: EC2 instance launch fails in inspection-vpc
**Solution**:
- Verify key pair exists in us-west-1
- Check IAM role has EC2 permissions
- Ensure Palo Alto AMI is available in the region

### State Lock Errors
**Issue**: Terraform state is locked
**Solution**:
```bash
terraform force-unlock <LOCK_ID>
# Check .terraform/terraform.tfstate.lock.info for LOCK_ID
```

## 📝 Notes & Considerations

### High Availability
- VPCs have subnets across 2 AZs for resilience
- Firewall has 2 instances across AZs with HA heartbeat
- GWLB automatically distributes traffic across healthy instances
- CloudWAN spans 3 regions for geographic diversity

### Scalability
- Add new VPCs by editing `terraform.tfvars`
- Add new segments by modifying core network policy
- Firewall instances can be scaled up/down in inspection-vpc

### Cost Optimization
- CloudWAN charges per attachment and routing policy evaluation
- Consider consolidating VPCs to reduce attachment costs
- GWLB charges per processed GB

### Future Enhancements
See [inspection-vpc/TODO.md](inspection-vpc/TODO.md) for planned improvements:
- Palo Alto license management
- Traffic steering policies
- Firewall management integration
- Additional inspection patterns

## 📞 Support & References

- [AWS CloudWAN Documentation](https://docs.aws.amazon.com/network-manager/latest/userguide/what-is-cloudwan.html)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Terraform AWSCC Provider](https://registry.terraform.io/providers/hashicorp/aws-cc/latest/docs)
- [Palo Alto VM-Series on AWS](https://docs.paloaltonetworks.com/vm-series/10-1/vm-series-deployment/set-up-the-vm-series-firewall-on-aws)

---

**Last Updated**: December 2025
**Terraform Version**: >= 1.13
**AWS Provider Versions**: AWS 6.25+, AWSCC 1.66+
