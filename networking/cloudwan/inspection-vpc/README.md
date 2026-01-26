# Inspection VPC Terraform Configuration

This Terraform configuration creates an inspection VPC with firewall instances, Gateway Load Balancer, and CloudWAN integration for centralized traffic inspection within a CloudWAN network.

## Project Overview

The Inspection VPC serves as a centralized hub for traffic inspection within a CloudWAN network. It includes:
- A VPC with 8 specialized subnets across two availability zones
- Palo Alto VM-Series firewall instances (2 instances for HA)
- Gateway Load Balancer (GWLB) for traffic distribution
- Gateway Load Balancer endpoints for traffic steering
- Custom routing tables per subnet
- Internet Gateway for management traffic
- CloudWAN attachment for integration with the core network
- DynamoDB integration to retrieve and store CloudWAN configuration
- Security groups for firewall management and data traffic

## Files Overview

| File | Purpose |
|------|---------|
| **provider.tf** | Terraform provider configuration (AWS v6.25, AWSCC v1.0) with S3 backend |
| **variables.tf** | Variable definitions for VPC, subnets, firewall instances, and key pair configuration |
| **main.tf** | Core VPC resources: VPC, Internet Gateway, and subnets |
| **routing.tf** | Route tables and routing rules for each subnet type |
| **firewall.tf** | Palo Alto VM-Series firewall instances, network interfaces, and Elastic IPs |
| **gwlb.tf** | Gateway Load Balancer, target groups, and VPC endpoint service |
| **sg.tf** | Security groups for firewall management and data traffic |
| **cloudwan-attachment.tf** | CloudWAN attachment logic and DynamoDB integration |
| **dynamodb.tf** | DynamoDB table item for storing Inspection VPC outputs |
| **outputs.tf** | Output values for VPC, subnets, route tables, and firewall IPs |
| **inspection-vpc-config.json** | JSON configuration file (reference documentation) |
| **.gitignore** | Git ignore rules for Terraform state and sensitive files |
| **TODO.md** | Project notes and remaining tasks |

## Architecture

### Subnet Types

The VPC includes the following subnet types:

1. **Firewall Management Subnets** (fw-mgmt-subnet-*)
   - For firewall appliance management interfaces
   - Internet accessible
   - 2 subnets across different AZs for high availability

2. **Firewall Data Subnets** (fw-data-subnet-*)
   - For firewall data plane interfaces
   - No internet access
   - 2 subnets across different AZs for high availability

3. **Gateway Load Balancer Endpoint Subnets** (gwlb-endpnt-subnet-*)
   - For Gateway Load Balancer endpoints
   - No internet access
   - 2 subnets across different AZs

4. **Core Network Subnets** (core-network-subnet-*)
   - For CloudWAN core network attachment
   - No internet access
   - 2 subnets across different AZs

### Network Configuration

- **VPC CIDR**: `10.0.100.0/23` (512 IP addresses)
- **Region**: `us-west-1` (North California)
- **Availability Zones**: `us-west-1a` and `us-west-1b`
- **Each subnet**: `/27` (32 IP addresses)

### CloudWAN Integration

The configuration uses the AWSCC provider (`awscc_networkmanager_vpc_attachment`) to:
- Attach the Inspection VPC to a CloudWAN core network
- Filter and attach only core-network type subnets to the attachment
- Retrieve the core network ARN from DynamoDB (stored by the main CloudWAN project)
- Automatically tag resources for tracking

## Features

- **Infrastructure as Code**: All AWS resources defined in Terraform
- **AWSCC Provider**: Uses Cloud Control API for newer CloudWAN resources
- **Variable-driven**: All values defined in `variables.tf` with sensible defaults
- **High Availability**: Subnets across multiple availability zones
- **Automatic Routing**: Subnets with `internetAccess: true` automatically route through IGW
- **DynamoDB Integration**: Shares outputs with other Terraform projects via DynamoDB
- **Default Tags**: Applied to all resources (Environment, ManagedBy, Project)
- **State Management**: Remote S3 backend for secure state storage

## Prerequisites

- AWS Account with appropriate IAM permissions
- Terraform >= 1.13
- AWS CLI configured with `default` profile
- Existing DynamoDB table: `cloudwan-project-tf-outputs` with CloudWAN core network details
- Key pair in the AWS region for EC2 instances
- Public IP address for firewall management access (for security group rules)

## Usage

### Initialize Terraform

```bash
terraform init
```

This will:
- Configure the S3 remote backend
- Download provider plugins (aws v6.25, awscc v1.67.0)
- Prepare the working directory

### Plan the deployment

```bash
terraform plan
```

This shows what resources will be created without making any changes.

### Apply the configuration

```bash
terraform apply
```

This creates all the resources. You'll be prompted to confirm before applying.

### View outputs

```bash
terraform output
```

Shows the VPC ID, CIDR, Internet Gateway ID, subnet details, and route table IDs.

### Destroy resources (if needed)

```bash
terraform destroy
```

This removes all resources managed by this configuration. Note: The DynamoDB table item will also be destroyed.

## Variable Configuration

All variables are defined in `variables.tf` with default values. You can override them by:

1. **Environment variables**: Set `TF_VAR_variable_name`
2. **Command-line flags**: `terraform apply -var="variable_name=value"`
3. **Variable files**: Create a `.tfvars` file and pass with `-var-file`

### Main Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `vpc_name` | string | `insp-usw1-vpc-1` | Name of the VPC |
| `vpc_region` | string | `us-west-1` | AWS region |
| `vpc_cidr` | string | `10.0.100.0/23` | VPC CIDR block |
| `create_internet_gateway` | bool | `true` | Create IGW |
| `key_name` | string | (required) | EC2 key pair name for firewall instances |
| `my_public_ip` | string | (required) | Your public IP in CIDR format (e.g., "203.0.113.0/32") for management access |
| `firewall_ami` | string | (Palo Alto AMI) | AMI ID for Palo Alto VM-Series firewall |
| `firewall_instance_type` | string | (required) | Instance type for firewall (e.g., "m5.xlarge") |
| `subnets` | list(object) | See below | Subnet configurations |

### Subnet Object Schema

```hcl
{
  name           = string           # Subnet name
  cidr           = string           # Subnet CIDR block
  az             = string           # Availability Zone
  type           = string           # Subnet type (firewall-management, firewall-data, gateway-load-balancer-endpoint, core-network)
  internetAccess = bool             # Whether to route traffic through IGW
}
```

## Firewall Configuration

### Palo Alto VM-Series Instances

The configuration deploys two Palo Alto VM-Series firewall instances for high availability:

**Instance Details**:
- **Number of Instances**: 2 (one per availability zone)
- **Management Interfaces**: Connected to firewall management subnets with Elastic IPs
- **Data Interfaces**: Connected to firewall data subnets with source/dest check disabled
- **User Data**: DHCP client configuration for automatic IP assignment

**Network Interfaces**:
- **Management 1a**: 10.0.100.10 (fw-mgmt-subnet-1a)
- **Management 1b**: 10.0.100.42 (fw-mgmt-subnet-1b)
- **Data 1a**: 10.0.100.74 (fw-data-subnet-1a)
- **Data 1b**: 10.0.100.106 (fw-data-subnet-1b)

**Elastic IPs**:
- Public IPs allocated for firewall management interface access
- Outputs: `management_public_ip_1a`, `management_public_ip_1b`

### Gateway Load Balancer (GWLB)

The GWLB distributes traffic to firewall instances:

**Configuration**:
- **Port**: 6081 (GENEVE protocol)
- **Target Type**: EC2 instances (firewall instances)
- **Health Check**: HTTP on port 80, every 10 seconds
- **Subnets**: Deployed in firewall data subnets

**VPC Endpoint Service**:
- Enables other VPCs to connect to the inspection VPC via GWLB endpoints
- Acceptance required: False (automatic acceptance)

### Security Groups

**Firewall Management SG** (`insp-fw-mgmt-sg`):
- Ingress: HTTPS (443) and SSH (22) from your public IP
- Egress: All traffic to 0.0.0.0/0

**Firewall Data SG** (`insp-fw-data-sg`):
- Ingress: All traffic from 0.0.0.0/0
- Egress: All traffic to 0.0.0.0/0

## DynamoDB Integration

### Data Flow

1. **CloudWAN Project** stores its core network ARN in DynamoDB under key `id = "cloudwan"`
2. **Inspection VPC Project** reads the core network ARN from DynamoDB via `data.aws_dynamodb_table_item.cloudwan_core_network`
3. **Inspection VPC** attaches itself to the CloudWAN core network using the `awscc_networkmanager_vpc_attachment` resource
4. **Inspection VPC Project** stores its outputs in DynamoDB under key `id = "inspection-vpc"` via `aws_dynamodb_table_item.inspection_vpc_outputs_item`

### DynamoDB Table Structure

The configuration uses a single DynamoDB table: `cloudwan-project-tf-outputs`

**CloudWAN item** (key: `id = "cloudwan"`):
```json
{
  "id": "cloudwan",
  "core_network_arn": "arn:aws:networkmanager::ACCOUNT:core-network/core-network-id"
}
```

**Inspection VPC item** (key: `id = "inspection-vpc"`):
```json
{
  "id": "inspection-vpc",
  "vpc_id": "vpc-xxxxxxxx",
  "vpc_cidr": "10.0.100.0/23",
  "internet_gateway_id": "igw-xxxxxxxx",
  "subnets": "[{...subnet details...}]",
  "route_tables": "[{...route table details...}]"
}
```

## Outputs

After applying the configuration, the following outputs are available:

| Output | Description |
|--------|-------------|
| `vpc_id` | ID of the created VPC |
| `vpc_cidr` | CIDR block of the VPC |
| `internet_gateway_id` | ID of the IGW |
| `subnets` | Map of subnet details (ID, CIDR, AZ, route table ID) |
| `route_tables` | Map of route table IDs by subnet name |
| `management_public_ip_1a` | Public IP for firewall 1a management interface |
| `management_public_ip_1b` | Public IP for firewall 1b management interface |

Example:
```bash
$ terraform output vpc_id
"vpc-0a1b2c3d4e5f6g7h8"

$ terraform output management_public_ip_1a
"203.0.113.5"

$ terraform output subnets
{
  "core-network-subnet-1a" = {
    "az" = "us-west-1a"
    "cidr" = "10.0.100.192/27"
    "id" = "subnet-0x1y2z3a4b5c6d7e8"
    "route_table_id" = "rtb-0p1q2r3s4t5u6v7w"
  }
  ...
}
```

## CloudWAN Attachment Details

### Resource: `awscc_networkmanager_vpc_attachment`

This resource (using AWSCC provider) attaches the Inspection VPC to the CloudWAN core network.

**Key Features**:
- **Automatic core-network subnet filtering**: Only core-network type subnets are attached
- **DynamoDB-driven**: Core network ARN is retrieved from DynamoDB
- **Automatic tagging**: Resources are tagged with project information
- **Dependency management**: Explicitly depends on DynamoDB data source

**Subnet Selection Logic**:
The attachment uses a local value that filters subnets by type:
```hcl
core_network_subnet_arns = [
  for subnet in aws_subnet.subnets : subnet.arn
  if lookup(subnet.tags, "type", null) == "core-network"
]
```

This ensures only the appropriate subnets (core-network-subnet-1a and core-network-subnet-1b) are attached to CloudWAN.

## Security Considerations

1. **IAM Permissions**: Ensure the AWS profile has permissions for:
   - VPC, subnet, route table creation
   - EC2 instance, network interface, and Elastic IP management
   - DynamoDB item read/write
   - CloudWAN attachment
   - Elastic Load Balancing for GWLB
   - Security group creation and management

2. **State File Security**:
   - S3 bucket encryption enabled
   - Bucket versioning enabled
   - Access logs enabled
   - Public access blocked

3. **Network Security**:
   - Non-internet subnets (firewall data, gateway LB endpoint, core network) have no IGW route
   - Firewall management access restricted to specified public IP only
   - Firewall data plane allows all traffic for inspection
   - Security groups restrict access based on subnet purpose

4. **Firewall Security**:
   - Management interface accessible only via HTTPS/SSH from your IP
   - Data interface handles traffic inspection without source/dest check
   - GWLB distributes traffic for load balancing and HA

## Troubleshooting

### CloudWAN Attachment Fails
- Verify the DynamoDB table exists and contains the CloudWAN core network ARN
- Ensure the core network ARN is correctly stored in DynamoDB with key `id = "cloudwan"`
- Check that the AWS profile has CloudWAN attachment permissions
- Verify AWSCC provider version compatibility (>= 1.0)

### Firewall Instances Not Running
- Verify the firewall AMI ID is valid for your region
- Check that the instance type is available in the selected region
- Ensure the key pair name exists in the selected region
- Verify IAM permissions for EC2 instance creation

### GWLB Health Checks Failing
- Verify firewall instances are running and healthy
- Check firewall data plane security group allows HTTP on port 80
- Confirm GENEVE protocol support on firewall instances
- Review firewall logs for health check failures

### Subnets Not Created
- Verify the subnets array in variables is correctly formatted
- Check for CIDR block overlaps within the VPC CIDR
- Ensure availability zones are valid for the selected region

### DynamoDB Errors
- Confirm the table `cloudwan-project-tf-outputs` exists
- Verify credentials have DynamoDB access (GetItem, PutItem)
- Check that items are properly JSON-encoded

### Management Access to Firewall
- Verify the `my_public_ip` variable is set correctly in CIDR format
- Check security group rules allow HTTPS and SSH from your IP
- Confirm Elastic IP is properly associated with management interface
- Verify firewall is fully booted (may take 5-10 minutes after launch)

### State Lock Issues
- If Terraform hangs during operations, a state lock may be held
- Check S3 for `.tfstate.lock` files in the Terraform state bucket
- Only force-unlock if you're certain no other process is using Terraform

## Related Projects

- **CloudWAN Core Network**: Main CloudWAN project that creates the core network
- **Additional VPCs**: Other VPCs that can attach to the same CloudWAN core network

## Next Steps

1. **Configure Firewall**: After deployment, configure the Palo Alto firewall via its management interface
2. **Create GWLB Endpoints**: Set up GWLB endpoints in other VPCs for traffic steering
3. **Test Connectivity**: Verify traffic flows through inspection VPC
4. **Monitor**: Set up CloudWatch alarms for GWLB and firewall metrics
