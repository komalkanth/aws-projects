variable "vpcs" {
  description = "Map of VPC configurations"
  type = map(object({
    vpc_name             = string
    region               = string
    vpc_cidr             = string
    subnet_1a_cidr       = string
    subnet_1b_cidr       = string
    enable_igw           = bool
    enable_dns_support   = optional(bool, true)
    enable_dns_hostnames = optional(bool, true)
  }))
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    ManagedBy   = "Terraform"
    Environment = "Multi"
    Project     = "CloudWAN"
  }
}

# ==============================
# DynamoDB lookup configuration
# ==============================
variable "dynamodb_region" {
  description = "Region where the DynamoDB table resides"
  type        = string
  default     = "us-east-1"
}

variable "dynamodb_table_name" {
  description = "DynamoDB table name that stores CloudWAN outputs"
  type        = string
  default     = "cloudwan-terraform-outputs"
}

variable "dynamodb_key_attr" {
  description = "Partition key attribute name for the DynamoDB table"
  type        = string
  default     = "id"
}

variable "dynamodb_value_attr" {
  description = "Attribute name that holds the value to read from the item"
  type        = string
  default     = "core_network_arn"
}

variable "dynamodb_core_network_key" {
  description = "Partition key value to fetch the Core Network ARN"
  type        = string
  default     = "cloudwan"
}
