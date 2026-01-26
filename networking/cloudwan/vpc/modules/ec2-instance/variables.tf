# Module variables for EC2 instance deployment

variable "vpc_name" {
  description = "Name of the VPC where the instance will be deployed"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the instance will be deployed"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID where the instance will be launched"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "environment" {
  description = "Environment tag (prod, dev, or cust)"
  type        = string
  validation {
    condition     = contains(["prod", "dev", "cust"], var.environment)
    error_message = "Environment must be either 'prod', 'dev', or 'cust'."
  }
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    ManagedBy = "Terraform"
    Project   = "CloudWAN"
  }
}
