
variable "region" {
  default = "us-east-1"
}

variable "region_short_name" {
  default = ""
}

variable "vpc_main_cidr" {
  description = "The main IPv4 CIDR for VPC"
}

variable "default_tags" {}

variable "vpc_name" {}

variable "public_subnet_cidr_map" {
  type        = map(any)
  description = "Map of list of CIDRs for public subnets corresponding to specific AZs"
  default     = {}
}

variable "private_subnet_cidr_map" {
  type        = map(any)
  description = "Map of list of CIDRs for public subnets corresponding to specific AZs"
  default     = {}
}

variable "natgw_enabled" {
  type        = map(bool)
  description = "Map to enable/disable NAT Gateway in specific AZs"
  default     = {}
}

variable "environment" {}
variable "organization" {}

variable "region_to_name_map" {
  type = map(any)
  default = {
    us-east-1      = "use1"
    us-east-2      = "use2"
    us-west-1      = "usw1"
    us-west-2      = "usw2"
    ca-central-1   = "cac1"
    eu-west-1      = "euw1"
    eu-west-2      = "euw2"
    eu-central-1   = "euc1"
    ap-southeast-1 = "apse1"
    ap-southeast-2 = "apse2"
    ap-south-1     = "aps1"
    ap-northeast-1 = "apne1"
    ap-northeast-2 = "apne2"
    sa-east-1      = "sae1"
  }

}