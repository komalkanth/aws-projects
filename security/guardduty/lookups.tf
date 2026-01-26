# Data source to get available availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Data source to get CloudFront prefix list for the current region
data "aws_ec2_managed_prefix_list" "cloudfront" {
  filter {
    name   = "prefix-list-name"
    values = ["com.amazonaws.global.cloudfront.origin-facing"]
  }
}

# Data source to get Ubuntu 20.04 AMI
data "aws_ssm_parameter" "ubuntu_ami" {
  name = "/aws/service/canonical/ubuntu/server/20.04/stable/current/amd64/hvm/ebs-gp2/ami-id"
}

# Data source to get current AWS region
data "aws_region" "current" {}

# Data source to get current AWS account ID
data "aws_caller_identity" "current" {}

# Data source to get AWS partition
data "aws_partition" "current" {}
