# VPC CIDR range
variable "vpc_cidr" {
  description = "VPC CIDR range"
  type        = string
  default     = "10.0.3.0/26"
}

# First subnet CIDR range
variable "subnet_cidr" {
  description = "subnet CIDR range"
  type        = list(string)
  default     = ["10.0.3.16/28", "10.0.3.32/28"]
}

# Port application is listening at
variable "web_port" {
  description = "port application is listening at"
  type        = number
  default     = 80
}

# Stack name for resource tagging
variable "stack_name" {
  description = "Name to use for resource tagging"
  type        = string
  default     = "guardduty"
}

# AWS Access Key ID (optional - can use AWS CLI profile instead)
variable "aws_access_key_id" {
  description = "AWS Access Key ID"
  type        = string
  default     = ""
  sensitive   = true
}

# AWS Secret Access Key (optional - can use AWS CLI profile instead)
variable "aws_secret_access_key" {
  description = "AWS Secret Access Key"
  type        = string
  default     = ""
  sensitive   = true
}
