# Data source to read CloudWAN core network ARN from DynamoDB table
# Table: cloudwan-terraform-outputs in us-east-1
# Requires: dynamodb:GetItem permission on the specified table

data "aws_dynamodb_table_item" "core_network_arn" {
  table_name = var.dynamodb_table_name

  # Build the key in DynamoDB format
  # Example: {"id": {"S": "core_network_arn"}}
  key = jsonencode({
    (var.dynamodb_key_attr) = {
      S = var.dynamodb_core_network_key
    }
  })
}

# Extract the core network ARN from the DynamoDB item
# The item structure is: {attribute_name: {type: value}}
# We navigate the nested structure to get the actual string value
locals {
  core_network_item = jsondecode(data.aws_dynamodb_table_item.core_network_arn.item)
  core_network_arn  = try(local.core_network_item[var.dynamodb_value_attr].S, null)
}

# Output for downstream modules/resources
output "core_network_arn" {
  description = "Core Network ARN fetched from DynamoDB table"
  value       = local.core_network_arn
}
