variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
  default     = "insp-usw1-vpc-1"
}

variable "vpc_region" {
  description = "AWS region for the VPC"
  type        = string
  default     = "us-west-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.100.0/23"
}

variable "create_internet_gateway" {
  description = "Whether to create an Internet Gateway"
  type        = bool
  default     = true
}

variable "subnets" {
  description = "List of subnets to create in the VPC"
  type = list(object({
    name           = string
    cidr           = string
    az             = string
    type           = string
    internetAccess = bool
  }))
  default = [
    {
      name           = "fw-mgmt-subnet-1a"
      cidr           = "10.0.100.0/27"
      az             = "us-west-1a"
      type           = "firewall-management"
      internetAccess = true
    },
    {
      name           = "fw-mgmt-subnet-1b"
      cidr           = "10.0.100.32/27"
      az             = "us-west-1b"
      type           = "firewall-management"
      internetAccess = true
    },
    {
      name           = "fw-data-subnet-1a"
      cidr           = "10.0.100.64/27"
      az             = "us-west-1a"
      type           = "firewall-data"
      internetAccess = false
    },
    {
      name           = "fw-data-subnet-1b"
      cidr           = "10.0.100.96/27"
      az             = "us-west-1b"
      type           = "firewall-data"
      internetAccess = false
    },
    {
      name           = "gwlb-endpnt-subnet-1a"
      cidr           = "10.0.100.128/27"
      az             = "us-west-1a"
      type           = "gateway-load-balancer-endpoint"
      internetAccess = false
    },
    {
      name           = "gwlb-endpnt-subnet-1b"
      cidr           = "10.0.100.160/27"
      az             = "us-west-1b"
      type           = "gateway-load-balancer-endpoint"
      internetAccess = false
    },
    {
      name           = "core-network-subnet-1a"
      cidr           = "10.0.100.192/27"
      az             = "us-west-1a"
      type           = "core-network"
      internetAccess = false
    },
    {
      name           = "core-network-subnet-1b"
      cidr           = "10.0.100.224/27"
      az             = "us-west-1b"
      type           = "core-network"
      internetAccess = false
    }
  ]
}

# AMI ID for Palo Alto VM-Series firewall
variable "firewall_ami" {
  type        = string
  description = "AMI ID for Palo Alto VM-Series firewall"
  default     = "ami-0d87f3ea3b14a85f4"                     # AMI ID for Next-Gen Virtual Firewall w/Advanced Threat Prevention (PAYG) in us-west-1
}

# Instance type for firewalls
variable "firewall_instance_type" {
  type        = string
  description = "Instance type for Palo Alto VM-Series firewalls"
  default     = "m5.4xlarge"
}

# Key pair for SSH access to firewall instances
variable "key_name" {
  type        = string
  description = "AWS EC2 Key Pair name for SSH access to firewall instances"
  default     = ""
}

# Your public IP for management access to firewalls
variable "my_public_ip" {
  type        = string
  description = "Your public IP address for SSH and HTTPS access to firewall management (e.g., 203.0.113.0/32)"
  default     = "0.0.0.0/0"
}

