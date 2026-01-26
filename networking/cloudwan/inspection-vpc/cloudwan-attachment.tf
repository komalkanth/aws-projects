# ============================================================================
# Read CloudWAN Core Network from DynamoDB and attach VPC
# ============================================================================

# Data source to read the core network ARN from the existing DynamoDB table
data "aws_dynamodb_table_item" "cloudwan_core_network" {
  table_name = "cloudwan-project-tf-outputs"
  key = jsonencode({
    id = { S = "cloudwan" }
  })
}

# Parse the DynamoDB item to extract the core network ARN
locals {
  dynamodb_item    = jsondecode(data.aws_dynamodb_table_item.cloudwan_core_network.item)
  core_network_arn = local.dynamodb_item.core_network_arn.S

  # Filter subnets to only include core-network type
  core_network_subnet_arns = [
    for subnet in aws_subnet.subnets : subnet.arn
    if lookup(subnet.tags, "type", null) == "core-network"
  ]
}

# Attach the Inspection VPC to the CloudWAN core network
resource "awscc_networkmanager_vpc_attachment" "inspection_vpc" {
  subnet_arns      = local.core_network_subnet_arns
  core_network_id  = split(":", local.core_network_arn)[6]
  vpc_arn          = aws_vpc.main.arn

  tags = [
    {
      key   = "Name"
      value = "${var.vpc_name}-cloudwan-attachment"
    },
    {
      key   = "Project"
      value = "CloudWAN"
    }
  ]

  depends_on = [data.aws_dynamodb_table_item.cloudwan_core_network]
}
