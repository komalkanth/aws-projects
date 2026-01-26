
## Architecture

The configuration creates a multi-tier secure infrastructure on AWS:

- **VPC Infrastructure**: Custom VPC with 2 public subnets across multiple Availability Zones for high availability.
- **Compute**: Auto Scaling Group running **OWASP Juice Shop** (an intentionally insecure web app) on Ubuntu 20.04 instances.
- **Load Balancing**: Application Load Balancer (ALB) to distribute incoming traffic.
- **Global Delivery**: CloudFront distribution serving as the entry point with SSL termination.
- **Storage**: Encrypted S3 "Secure Bucket" with strict bucket policies and a VPC Gateway Endpoint.
- **Security Monitoring**: **Amazon GuardDuty** detector with S3, EKS, and EBS Malware protection enabled.
- **Automated Remediation**: **EventBridge** + **AWS Lambda** for near real-time response to credential exfiltration findings.

## Terraform Configuration

This directory contains the Terraform configuration to deploy the kkoncloud GuardDuty threat detection and automated remediation project.

### File Structure

```
terraform/
├── providers.tf            # Provider configuration (supports CLI profiles and explicit credentials)
├── variables.tf            # Input variables for customization
├── lookups.tf              # Data sources for AMI, AZ, and Account lookups
├── vpc.tf                  # Core networking: VPC, subnets, IGW, and S3 Endpoint
├── security_groups.tf      # Firewall rules for ALB and Web Servers
├── iam.tf                  # Centralized IAM Roles and Policies for EC2 and Lambda
├── s3.tf                   # S3 Bucket configuration and encryption
├── compute.tf              # Launch Template and Auto Scaling Group
├── loadbalancer.tf         # ALB, Target Group, and HTTP Listeners
├── cloudfront.tf           # CloudFront Distribution settings
├── guardduty.tf            # GuardDuty Detector and monitoring configuration
├── eventbridge.tf          # Finding detection rules and Lambda trigger logic
├── lambda.tf               # Lambda function resource definition
├── remediation_lambda.py   # Python code for the remediation logic
├── package-lambda.sh       # Bash script to package the Lambda function
├── user-data.sh            # EC2 initialization script (Juice Shop setup)
├── outputs.tf              # Important stack outputs (URLs, IDs)
├── credentials.tfvars      # (Local-only) AWS credentials (ignored by git)
├── README.md               # Extensive project guide and manual walkthrough
└── ABOUT.md                # This file
``````

### Scripts

### 1. `remediation_lambda.py` (Python)
This script contains the core remediation logic. When triggered by EventBridge, it:
- Extracts the compromised Role Name and timestamp from the GuardDuty finding.
- Uses Boto3 to attach an inline "RevokeOldSessions" policy to the affected IAM role.
- The policy denies all actions for sessions issued *before* the finding timestamp, neutralizing stolen credentials instantly.

### 2. `package-lambda.sh` (Bash)
A utility script to prepare the Lambda deployment package. It:
- Creates a temporary packaging directory.
- Zips `remediation_lambda.py` into `remediation_lambda.zip`.
- Cleans up after itself, leaving the zip file ready for Terraform to upload.

## Prerequisites

- **Terraform** >= 1.0
- **AWS CLI** configured with a "default" profile (or use `credentials.tfvars`).
- **Bash environment** to run the packaging script.

## Usage

1. **Package the Lambda**:
   ```bash
   ./package-lambda.sh
   ```

2. **Initialize Terraform**:
   ```bash
   terraform init
   ```

3. **Deploy**:
   ```bash
   terraform apply
   ```

## Automated Remediation Flow

1. **Detection**: GuardDuty detects a `CredentialExfiltration` finding (e.g., EC2 credentials being used outside AWS).
2. **Trigger**: EventBridge catches the specific finding type.
3. **Execution**: EventBridge triggers the `remediation` Lambda function, passing the finding details.
4. **Response**: The Lambda function attaches a "Deny" policy to the role, effectively revoking all compromised sessions while allowing the instance to continue functioning (if it can obtain new credentials).

## Important Notes

⚠️ **This environment is intentionally insecure for educational purposes.**

- Do NOT use this configuration for production workloads.
- The Juice Shop application contains known vulnerabilities.
- Destroy resources via `terraform destroy` when finished to avoid costs.

---
*Created for the kkoncloud GuardDuty Threat Detection Project.*
