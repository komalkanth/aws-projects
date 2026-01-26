# AWS Cloud WAN - Global Network and Core Network

This Terraform configuration deploys an AWS Cloud WAN infrastructure with a Global Network and Core Network spanning three edge locations (us-east-1, us-east-2, us-west-1).

## Overview

AWS Cloud WAN is a wide area network service that you can use to build, manage, and monitor unified global networks from disparate branches, AWS regions, and on-premises locations. This configuration sets up:

- **Global Network**: A container for your core network and all network objects
- **Core Network**: Spans three edge locations with automatic segment routing based on VPC tags
- **Network Segments**: Four segments (default, production, development, customer) for traffic isolation and policy enforcement
- **Attachment Policies**: Automatic VPC-to-segment association based on Environment tags
- **Segment Actions**: Production segment routes shared with customer segment

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      Global Network                             │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                     Core Network                          │  │
│  │                  (VPN ECMP: Disabled)                     │  │
│  │                                                           │  │
│  │   ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    │  │
│  │   │  us-east-1   │  │  us-east-2   │  │  us-west-1   │    │  │
│  │   │ ASN: 64512   │  │ ASN: 64513   │  │ ASN: 64514   │    │  │
│  │   │ (Edge)       │  │ (Edge)       │  │ (Edge)       │    │  │
│  │   └──────────────┘  └──────────────┘  └──────────────┘    │  │
│  │                                                           │  │
│  │   ┌─────────────────────────────────────────────────┐     │  │
│  │   │           Network Segments                      │     │  │
│  │   │  • default (required)                           │     │  │
│  │   │  • production (for prod VPCs)                   │     │  │
│  │   │  • development (for dev VPCs)                   │     │  │
│  │   │  • customer (for customer VPCs, requires accept)│     │  │
│  │   └─────────────────────────────────────────────────┘     │  │
│  │                                                           │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Resources Created

| Resource | Description | File |
|----------|-------------|------|
| `aws_networkmanager_global_network` | Container for the core network and network objects | main.tf |
| `aws_networkmanager_core_network` | Core network with three edge locations and base policy | main.tf |
| `aws_networkmanager_core_network_policy_attachment` | Attaches the policy document to the core network | main.tf |
| `aws_dynamodb_table_item` | Stores Cloud WAN output values in DynamoDB (`cloudwan-project-tf-outputs`) | dynamodb.tf |

## Core Network Configuration

### Edge Locations

| Region | ASN |
|--------|-----|
| us-east-1 | 64512 |
| us-east-2 | 64513 |
| us-west-1 | 64514 |

**VPN ECMP Support**: Disabled

### Network Segments

The Core Network Policy defines four segments for traffic isolation:

| Segment | Purpose | Requires Acceptance | Description |
|---------|---------|-------------------|-------------|
| `default` | Required minimum | N/A | Minimal requirement for core network policy |
| `production` | Production workloads | No | For production VPCs tagged with `Environment: prod` |
| `development` | Development workloads | No | For development VPCs tagged with `Environment: dev` |
| `customer` | Customer workloads | Yes | For customer VPCs tagged with `Environment: customer` |

### Attachment Policies

Attachment policies automatically route VPCs to appropriate segments based on tags:

| Rule | Condition | Action | Segment |
|------|-----------|--------|---------|
| 100 | VPC with `Environment: prod` tag + VPC attachment type | Associate | `production` |
| 200 | VPC with `Environment: dev` tag + VPC attachment type | Associate | `development` |
| 300 | VPC with `Environment: customer` tag + VPC attachment type | Associate | `customer` |

### Segment Actions

- **Production → Customer**: Production segment routes are shared with the customer segment using `attachment-route` mode, allowing customer attachments to access production resources

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= 1.13
- AWS CLI configured with the `default` profile
- An S3 bucket for Terraform state: `terraformstatebucketkk` (in us-east-1)
- Appropriate AWS IAM permissions for Network Manager and DynamoDB resources

## Configuration Details

### Terraform Version

- Terraform >= 1.13
- AWS Provider >= 6.25

### Backend Configuration

This configuration uses an S3 backend to store Terraform state:

```hcl
backend "s3" {
  bucket  = "terraformstatebucketkk"
  key     = "cloudwan/cwan/terraform.tfstate"
  region  = "us-east-1"
  profile = "default"
}
```

> **Important**: The S3 bucket must exist before running `terraform init`. Create it manually or update the bucket name in `providers.tf` if you're using a different state bucket.

### Required IAM Permissions

To deploy this configuration, your AWS IAM user or role needs the following permissions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "networkmanager:*",
        "dynamodb:PutItem",
        "dynamodb:GetItem",
        "dynamodb:DescribeTable"
      ],
      "Resource": "*"
    }
  ]
}
```

## File Structure

```    # Global network, core network resource definitions
├── providers.tf               # Terraform version, AWS provider, and S3 backend configuration
├── core_policy.tf             # Core network policy document with segments and attachment policies
├── dynamodb.tf                # DynamoDB table item to persist Cloud WAN outputs
├── output.tf                  # Terraform output values
├── .terraform.lock.hcl        # Terraform dependency lock file
└── README.md                  # This file
```

### File Descriptions

- **main.tf**: Defines the Global Network and Core Network resources with base policy enabled
- **providers.tf**: Configures Terraform version constraints, AWS provider (v6.25), and S3 backend state storage
- **core_policy.tf**: Contains the core network policy document as a data source with:
  - Core network configuration (VPN ECMP, ASN ranges, edge locations)
  - Network segment definitions (default, production, development, customer)
  - Attachment policies for automatic VPC segment association
  - Segment actions for route sharing
- **dynamodb.tf**: Stores Cloud WAN outputs (IDs, ARNs, state, edges, segments) in DynamoDB for easy reference
- **output.tf**: Defines Terraform output values for network identifiers and configuration details .terraform.lock.hcl    # Terraform dependency lock file
└── README.md              # This file
```

## Deployment Instructions

### 1. Navigate to the cwan directory

```bash
cd cloudwan/cwan
```

### 2. Initialize Terraform

This will initialize the Terraform working directory and download the AWS provider. The configuration also creates a `terraform.tfstate` file in the S3 backend.

```bash
terraform init
```

### 3. Review the execution plan

```bash
terraform plan -out=tfplan
```

This will show all resources that will be created:
- Global Network
- Core Network with base policy
- Core Network Policy with segments and attachment policies
- DynamoDB table for output persistence

### 4. Apply the configuration

```bashDeployment

After successful deployment, Terraform will output the Cloud WAN resource identifiers:

```
global_network_id = "global-network-xxxxxxxxx"
global_network_arn = "arn:aws:networkmanager::123456789012:global-network/global-network-xxxxxxxxx"
core_network_id = "core-network-xxxxxxxxx"
core_network_arn = "arn:aws:networkmanager::123456789012:core-network/core-network-xxxxxxxxx"
core_network_state = "AVAILABLE"
core_network_edges = [...]
core_network_segments = [...]
```

To view the persisted output values in DynamoDB:

```bash
aws dynamodb get-item \
  --table-name cloudwan-project-tf-outputs \
  --key '{"id": {"S": "cloudwan"}}'
```

This returns all stored Cloud WAN outputs including Global Network ID, Core Network ID, ARN, state, and segment information in JSON format.e_network_edges = [...]
core_network_segments = [...]
``` to view persisted output values:

```bash
aws dynamodb get-item \
  --table-name cloudwan-project-tf-outputs \
  --key '{"id": {"S": "cloudwan"}}'
```

This will return all stored Cloud WAN outputs including Global Network ID, Core Network ID, ARN, state, and segment information in JSON format.-table-name cloudwan-terraform-outputs \
  --key '{"id": {"S": "cloudwan"}}'
```

## Outputs

| Output | Description |
|--------|-------------|
| `global_network_id` | The ID of the Global Network |
| `global_network_arn` | The ARN of the Global Network |
| `core_network_id` | The ID of the Core Network |
| `core_network_arn` | The ARN of the Core Network |
| `core_network_state` | The current state of the Core Network (AVAILABLE, CREATING, UPDATING, DELETING, etc.) |
| `core_network_edges` | The edge locations of the Core Network with region and ASN details |
| `core_network_segments` | The segments of the Core Network with their routing and acceptance policies |

## DynamoDB Persistence

The Cloud WAN configuration persists all critical output values to a DynamoDB table (`cloudwan-project-tf-outputs`) for easy reference and integration with other automation tools. The stored values include:

- `id`: Item identifier (cloudwan)
- `global_network_id`: Global Network resource ID
- `global_network_arn`: Global Network ARN
- `core_network_id`: Core Network resource ID
- `core_network_arn`: Core Network ARN
- `core_network_state`: Current operational state
- `core_network_edges`: JSON-serialized edge location details
- `core_network_segments`: JSON-serialized segment configuration

## Cleanup

To destroy all resources created by this configuration:

```bash
terraform destroy
```

Type `yes` when prompted to confirm the destruction.

## Resource Naming Convention

All resources follow a naming pattern for easy identification:

| Resource | Terraform Name | AWS Tag Name |
|----------|---|---|
| Global Network | `global-oldies-network` | `cloudwan-global-network` |
| Core Network | `oldies-core-network` | `cloudwan-core-network` |
| DynamoDB Table | N/A | `cloudwan-project-tf-outputs` |

## DynamoDB Persistence

The configuration persists critical Cloud WAN outputs to a DynamoDB table (`cloudwan-project-tf-outputs`) for easy reference and integration with other automation tools.

**Stored Items:**
- `id`: Item identifier (`cloudwan`)
- `global_network_id`: Global Network resource ID
- `global_network_arn`: Global Network ARN
- `core_network_id`: Core Network resource ID
- `core_network_arn`: Core Network ARN
- `core_network_state`: Current operational state
- `core_network_edges`: JSON-serialized edge location details with regions and ASNs
- `core_network_segments`: JSON-serialized segment configuration

## How VPC Attachment Works

When attaching a VPC to the Core Network:

1. The attachment policy evaluates the VPC's `Environment` tag
2. The VPC is automatically associated with the corresponding segment:
   - `Environment: prod` → `production` segment
   - `Environment: dev` → `development` segment
   - `Environment: customer` → `customer` segment
3. For the customer segment, manual acceptance is required
4. Once accepted, the VPC can route to:
   - Other VPCs in the same segment
   - Resources in shared segments (production segment is shared with customer)

## Next Steps

After deploying the Cloud WAN core network, you can:

1. **Attach VPCs** - Create VPC attachments to the core network using the automatic routing policies
2. **Create Site-to-Site VPN attachments** - Connect on-premises networks to the core network
3. **Add new segments** - Extend network segmentation by modifying `core_policy.tf` with additional segments
4. **Configure routing** - Set up additional routing policies between segments using `segment_actions`
5. **Monitor connectivity** - Use the AWS Network Manager console to visualize network topology and monitor attachment states

## Troubleshooting

### Policy attachment fails

Ensure the core network is in `AVAILABLE` state before the policy attachment is created. The `create_base_policy = true` setting in `main.tf` creates a base policy first to help with this transition.

### Permission errors

Verify your AWS CLI profile has the necessary IAM permissions for Network Manager and DynamoDB operations. See the [Required IAM Permissions](#required-iam-permissions) section above.

### DynamoDB table not found

Ensure the `cloudwan-project-tf-outputs` DynamoDB table exists in your AWS account. The `dynamodb.tf` expects this table to already exist and only writes items to it.

## References

- [AWS Cloud WAN Documentation](https://docs.aws.amazon.com/network-manager/latest/cloudwan/what-is-cloudwan.html)
- [AWS Network Manager API Reference](https://docs.aws.amazon.com/networkmanager/latest/APIReference/)
- [Terraform AWS Network Manager Global Network](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkmanager_global_network)
- [Terraform AWS Network Manager Core Network](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkmanager_core_network)
- [Terraform AWS Network Manager Policy Document Data Source](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/networkmanager_core_network_policy_document)
