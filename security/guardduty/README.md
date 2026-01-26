# GuardDuty vs. an Intentionally Insecure Web App

> “What happens if I put a deliberately sketchy web app on the internet and let AWS GuardDuty watch it?”
> This article is my answer to that question.

This mini project, based on the [project here](https://learn.nextwork.org/projects/aws-security-guardduty?track=high), spins up a vulnerable web application (OWASP Juice Shop) in AWS, gives it just enough “secure-looking” setup to feel real, then depends on Amazon GuardDuty to catch suspicious behavior and trigger an automatic remediation Lambda.

The goal isn’t to build production-grade security. I never got to work on GuardDuty at work on account of always having dedicated S.O.C teams. The goal for me is to **see GuardDuty in action**: from finding malicious activity to automatically locking down compromised credentials.

GuardDuty allows us to create sample findings based on real-world threat intelligence which is good to explore the different kinds of findings it can generate but it's not quite the same as seeing it detect actual suspicious activity in a live environment.

We’ll walk through the main building blocks and peek at the Terraform that wires everything together.

---

## What We’re Building (High Level)

Here’s the story in plain terms:

- A **VPC with public subnets** hosts an Auto Scaling group of EC2 instances running OWASP Juice Shop.
- An **Application Load Balancer (ALB)** and **CloudFront distribution** expose the app to the internet.
- A seemingly **“secure” S3 bucket** stores sensitive-looking data, reachable via an EC2 IAM role and an S3 VPC endpoint.
- **GuardDuty** watches for suspicious behavior, especially **credential exfiltration** from the EC2 role.
- An **EventBridge rule** listens for specific GuardDuty findings and invokes a **remediation Lambda**.
- The Lambda **attaches a time-scoped deny policy** to the compromised IAM role, effectively revoking stolen credentials.

We’ll step through each piece with just enough Terraform to show how it all fits together.



> ⚠️ **This is not production security guidance.**
> The app is intentionally vulnerable, some configs are deliberately relaxed, and you should assume attackers *will* win here—that’s the point.

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
├── .terraform.lock.hcl     # Terraform dependency lock file
├── ABOUT.md                # Project summary and overview
├── STEP01.md               # Part 1: Terraform Setup for Networking and Compute
├── STEP02.md               # Part 2: Security Components and Attack Simulation
├── cloudfront.tf           # CloudFront Distribution settings
├── compute.tf              # Launch Template and Auto Scaling Group
├── credentials.tfvars      # (Local-only) AWS credentials (ignored by git)
├── eventbridge.tf          # Finding detection rules and Lambda trigger logic
├── guardduty.tf            # GuardDuty Detector and monitoring configuration
├── iam.tf                  # Centralized IAM Roles and Policies for EC2 and Lambda
├── lambda.tf               # Lambda function resource definition
├── loadbalancer.tf         # ALB, Target Group, and HTTP Listeners
├── lookups.tf              # Data sources for AMI, AZ, and Account lookups
├── outputs.tf              # Important stack outputs (URLs, IDs)
├── package-lambda.sh       # Bash script to package the Lambda function
├── providers.tf            # Provider configuration (supports CLI profiles and explicit credentials)
├── README.md               # Extensive project guide and manual walkthrough
├── remediation_lambda.py   # Python code for the remediation logic
├── s3.tf                   # S3 Bucket configuration and encryption
├── security_groups.tf      # Firewall rules for ALB and Web Servers
├── user-data.sh            # EC2 initialization script (Juice Shop setup)
├── variables.tf            # Input variables for customization
├── vpc.tf                  # Core networking: VPC, subnets, IGW, and S3 Endpoint
├── terraform.tfstate       # Current state of deployed resources
├── terraform.tfstate.backup # Backup of previous state
└── .terraform/             # Terraform working directory (providers and modules)
``````
\* _I'm using local backend just for the sake of simplicity in this lab._

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

---

## Prerequisites & How to Run

You’ll need:

- An AWS account and permissions to create IAM, EC2, S3, Lambda, GuardDuty, and EventBridge resources.
- Terraform installed and configured.
- A default AWS profile or access keys you’re comfortable using for a lab.

The provider is configured in `providers.tf` and can use either a profile or explicit credentials via variables.

### Quick Start

From this directory:

```bash
# (Optional) Create a credentials.tfvars with demo-only keys
# access_key  = "AKIA..."
# secret_key  = "..."

terraform init
terraform plan \
  -var-file="credentials.tfvars" \
  -out=tfplan
terraform apply tfplan
```

After a successful apply, Terraform will print outputs like the Juice Shop **CloudFront URL** and some IDs you’ll use when exploring logs and findings.

When you’re done with the lab:

```bash
terraform destroy
```

---

## The Lab Walkthrough

I have broken the lab setup into two parts for easier understanding.
- [Part 1: Terraform Setup for the Networking and Compute](STEP01.md)
- [Part 2: Setting up the security components and Simulating an Attack and Observing GuardDuty](STEP02.md)