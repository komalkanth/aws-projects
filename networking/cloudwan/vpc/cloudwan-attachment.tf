# CloudWAN VPC Attachment for dev-use1-vpc-1
# Uses core_network_arn from DynamoDB and VPC/subnet info from local state

data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  vpc_name   = "dev-use1-vpc-1"
  vpc_region = "us-east-1"
}

# Create CloudWAN attachment for dev-use1-vpc-1 VPC
resource "awscc_networkmanager_vpc_attachment" "dev_use1_vpc_1" {
  provider = awscc

  core_network_id = regex(
    "core-network/([^/]+)$",
    local.core_network_arn
  )[0]

  vpc_arn = format(
    "arn:aws:ec2:%s:%s:vpc/%s",
    local.vpc_region,
    local.account_id,
    aws_vpc.use1[local.vpc_name].id
  )

  subnet_arns = [
    format(
      "arn:aws:ec2:%s:%s:subnet/%s",
      local.vpc_region,
      local.account_id,
      aws_subnet.use1_1a[local.vpc_name].id
    ),
    format(
      "arn:aws:ec2:%s:%s:subnet/%s",
      local.vpc_region,
      local.account_id,
      aws_subnet.use1_1b[local.vpc_name].id
    )
  ]

  tags = [
    {
      key   = "Name"
      value = "${local.vpc_name}-cloudwan-attachment"
    },
    {
      key   = "Environment"
      value = "dev"
    },
    {
      key   = "VPC"
      value = local.vpc_name
    },
    {
      key   = "ManagedBy"
      value = "Terraform"
    },
    {
      key   = "Project"
      value = "CloudWAN"
    }
  ]
}

output "dev_vpc_attachment_id" {
  description = "CloudWAN VPC attachment ID for dev-use1-vpc-1"
  value       = awscc_networkmanager_vpc_attachment.dev_use1_vpc_1.id
}

output "dev_vpc_attachment_state" {
  description = "State of the VPC attachment"
  value       = awscc_networkmanager_vpc_attachment.dev_use1_vpc_1.state
}

# ============================================
# Production VPC Attachments (us-east-1)
# ============================================

# Create CloudWAN attachment for prod-use1-vpc-1 VPC
resource "awscc_networkmanager_vpc_attachment" "prod_use1_vpc_1" {
  provider = awscc

  core_network_id = regex(
    "core-network/([^/]+)$",
    local.core_network_arn
  )[0]

  vpc_arn = format(
    "arn:aws:ec2:us-east-1:%s:vpc/%s",
    data.aws_caller_identity.current.account_id,
    aws_vpc.use1["prod-use1-vpc-1"].id
  )

  subnet_arns = [
    format(
      "arn:aws:ec2:us-east-1:%s:subnet/%s",
      data.aws_caller_identity.current.account_id,
      aws_subnet.use1_1a["prod-use1-vpc-1"].id
    ),
    format(
      "arn:aws:ec2:us-east-1:%s:subnet/%s",
      data.aws_caller_identity.current.account_id,
      aws_subnet.use1_1b["prod-use1-vpc-1"].id
    )
  ]

  tags = [
    {
      key   = "Name"
      value = "prod-use1-vpc-1-cloudwan-attachment"
    },
    {
      key   = "Environment"
      value = "prod"
    },
    {
      key   = "VPC"
      value = "prod-use1-vpc-1"
    },
    {
      key   = "ManagedBy"
      value = "Terraform"
    },
    {
      key   = "Project"
      value = "CloudWAN"
    }
  ]
}

# Create CloudWAN attachment for prod-use1-vpc-2 VPC
resource "awscc_networkmanager_vpc_attachment" "prod_use1_vpc_2" {
  provider = awscc

  core_network_id = regex(
    "core-network/([^/]+)$",
    local.core_network_arn
  )[0]

  vpc_arn = format(
    "arn:aws:ec2:us-east-1:%s:vpc/%s",
    data.aws_caller_identity.current.account_id,
    aws_vpc.use1["prod-use1-vpc-2"].id
  )

  subnet_arns = [
    format(
      "arn:aws:ec2:us-east-1:%s:subnet/%s",
      data.aws_caller_identity.current.account_id,
      aws_subnet.use1_1a["prod-use1-vpc-2"].id
    ),
    format(
      "arn:aws:ec2:us-east-1:%s:subnet/%s",
      data.aws_caller_identity.current.account_id,
      aws_subnet.use1_1b["prod-use1-vpc-2"].id
    )
  ]

  tags = [
    {
      key   = "Name"
      value = "prod-use1-vpc-2-cloudwan-attachment"
    },
    {
      key   = "Environment"
      value = "prod"
    },
    {
      key   = "VPC"
      value = "prod-use1-vpc-2"
    },
    {
      key   = "ManagedBy"
      value = "Terraform"
    },
    {
      key   = "Project"
      value = "CloudWAN"
    }
  ]
}

output "prod_use1_vpc_1_attachment_id" {
  description = "CloudWAN VPC attachment ID for prod-use1-vpc-1"
  value       = awscc_networkmanager_vpc_attachment.prod_use1_vpc_1.id
}

output "prod_use1_vpc_1_attachment_state" {
  description = "State of the prod-use1-vpc-1 attachment"
  value       = awscc_networkmanager_vpc_attachment.prod_use1_vpc_1.state
}

output "prod_use1_vpc_2_attachment_id" {
  description = "CloudWAN VPC attachment ID for prod-use1-vpc-2"
  value       = awscc_networkmanager_vpc_attachment.prod_use1_vpc_2.id
}

output "prod_use1_vpc_2_attachment_state" {
  description = "State of the prod-use1-vpc-2 attachment"
  value       = awscc_networkmanager_vpc_attachment.prod_use1_vpc_2.state
}

# ============================================
# Production VPC Attachments (us-east-2)
# ============================================

# Create CloudWAN attachment for prod-use2-vpc-1 VPC
resource "awscc_networkmanager_vpc_attachment" "prod_use2_vpc_1" {
  provider = awscc

  core_network_id = regex(
    "core-network/([^/]+)$",
    local.core_network_arn
  )[0]

  vpc_arn = format(
    "arn:aws:ec2:us-east-2:%s:vpc/%s",
    data.aws_caller_identity.current.account_id,
    aws_vpc.use2["prod-use2-vpc-1"].id
  )

  subnet_arns = [
    format(
      "arn:aws:ec2:us-east-2:%s:subnet/%s",
      data.aws_caller_identity.current.account_id,
      aws_subnet.use2_2a["prod-use2-vpc-1"].id
    ),
    format(
      "arn:aws:ec2:us-east-2:%s:subnet/%s",
      data.aws_caller_identity.current.account_id,
      aws_subnet.use2_2b["prod-use2-vpc-1"].id
    )
  ]

  tags = [
    {
      key   = "Name"
      value = "prod-use2-vpc-1-cloudwan-attachment"
    },
    {
      key   = "Environment"
      value = "prod"
    },
    {
      key   = "VPC"
      value = "prod-use2-vpc-1"
    },
    {
      key   = "ManagedBy"
      value = "Terraform"
    },
    {
      key   = "Project"
      value = "CloudWAN"
    }
  ]
}

output "prod_use2_vpc_1_attachment_id" {
  description = "CloudWAN VPC attachment ID for prod-use2-vpc-1"
  value       = awscc_networkmanager_vpc_attachment.prod_use2_vpc_1.id
}

output "prod_use2_vpc_1_attachment_state" {
  description = "State of the prod-use2-vpc-1 attachment"
  value       = awscc_networkmanager_vpc_attachment.prod_use2_vpc_1.state
}

# ============================================
# Development VPC Attachments (us-east-2)
# ============================================

# Create CloudWAN attachment for dev-use2-vpc-1 VPC
resource "awscc_networkmanager_vpc_attachment" "dev_use2_vpc_1" {
  provider = awscc

  core_network_id = regex(
    "core-network/([^/]+)$",
    local.core_network_arn
  )[0]

  vpc_arn = format(
    "arn:aws:ec2:us-east-2:%s:vpc/%s",
    data.aws_caller_identity.current.account_id,
    aws_vpc.use2["dev-use2-vpc-1"].id
  )

  subnet_arns = [
    format(
      "arn:aws:ec2:us-east-2:%s:subnet/%s",
      data.aws_caller_identity.current.account_id,
      aws_subnet.use2_2a["dev-use2-vpc-1"].id
    ),
    format(
      "arn:aws:ec2:us-east-2:%s:subnet/%s",
      data.aws_caller_identity.current.account_id,
      aws_subnet.use2_2b["dev-use2-vpc-1"].id
    )
  ]

  tags = [
    {
      key   = "Name"
      value = "dev-use2-vpc-1-cloudwan-attachment"
    },
    {
      key   = "Environment"
      value = "dev"
    },
    {
      key   = "VPC"
      value = "dev-use2-vpc-1"
    },
    {
      key   = "ManagedBy"
      value = "Terraform"
    },
    {
      key   = "Project"
      value = "CloudWAN"
    }
  ]
}

# Create CloudWAN attachment for dev-use2-vpc-2 VPC
resource "awscc_networkmanager_vpc_attachment" "dev_use2_vpc_2" {
  provider = awscc

  core_network_id = regex(
    "core-network/([^/]+)$",
    local.core_network_arn
  )[0]

  vpc_arn = format(
    "arn:aws:ec2:us-east-2:%s:vpc/%s",
    data.aws_caller_identity.current.account_id,
    aws_vpc.use2["dev-use2-vpc-2"].id
  )

  subnet_arns = [
    format(
      "arn:aws:ec2:us-east-2:%s:subnet/%s",
      data.aws_caller_identity.current.account_id,
      aws_subnet.use2_2a["dev-use2-vpc-2"].id
    ),
    format(
      "arn:aws:ec2:us-east-2:%s:subnet/%s",
      data.aws_caller_identity.current.account_id,
      aws_subnet.use2_2b["dev-use2-vpc-2"].id
    )
  ]

  tags = [
    {
      key   = "Name"
      value = "dev-use2-vpc-2-cloudwan-attachment"
    },
    {
      key   = "Environment"
      value = "dev"
    },
    {
      key   = "VPC"
      value = "dev-use2-vpc-2"
    },
    {
      key   = "ManagedBy"
      value = "Terraform"
    },
    {
      key   = "Project"
      value = "CloudWAN"
    }
  ]
}

output "dev_use2_vpc_1_attachment_id" {
  description = "CloudWAN VPC attachment ID for dev-use2-vpc-1"
  value       = awscc_networkmanager_vpc_attachment.dev_use2_vpc_1.id
}

output "dev_use2_vpc_1_attachment_state" {
  description = "State of the dev-use2-vpc-1 attachment"
  value       = awscc_networkmanager_vpc_attachment.dev_use2_vpc_1.state
}

output "dev_use2_vpc_2_attachment_id" {
  description = "CloudWAN VPC attachment ID for dev-use2-vpc-2"
  value       = awscc_networkmanager_vpc_attachment.dev_use2_vpc_2.id
}

output "dev_use2_vpc_2_attachment_state" {
  description = "State of the dev-use2-vpc-2 attachment"
  value       = awscc_networkmanager_vpc_attachment.dev_use2_vpc_2.state
}
