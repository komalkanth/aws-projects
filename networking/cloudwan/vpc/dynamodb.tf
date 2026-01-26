# ============================================================================
# DynamoDB table item to persist VPC Terraform output values
# References the existing "cloudwan-terraform-outputs" table from cwan module
# ============================================================================

# data "aws_dynamodb_table" "cloudwan_outputs" {
#   name = "cloudwan-terraform-outputs"
# }

# Store key VPC values as a separate item in the shared DynamoDB table
# Complex values are JSON-serialized strings
resource "aws_dynamodb_table_item" "vpc_outputs_item" {
  table_name = "cloudwan-terraform-outputs"
  hash_key   = "id"

  item = jsonencode({
    id                    = { S = "vpc" }
    use1_vpc_ids          = { S = jsonencode(output.use1_vpc_ids.value) }
    use1_subnet_1a_ids    = { S = jsonencode(output.use1_subnet_1a_ids.value) }
    use1_subnet_1b_ids    = { S = jsonencode(output.use1_subnet_1b_ids.value) }
    use1_internet_gateway = { S = jsonencode(output.use1_internet_gateway_ids.value) }
    use1_route_table_ids  = { S = jsonencode(output.use1_route_table_ids.value) }
    use2_vpc_ids          = { S = jsonencode(output.use2_vpc_ids.value) }
    use2_subnet_2a_ids    = { S = jsonencode(output.use2_subnet_2a_ids.value) }
    use2_subnet_2b_ids    = { S = jsonencode(output.use2_subnet_2b_ids.value) }
    use2_internet_gateway = { S = jsonencode(output.use2_internet_gateway_ids.value) }
    use2_route_table_ids  = { S = jsonencode(output.use2_route_table_ids.value) }
    vpc_summary           = { S = jsonencode(output.vpc_summary.value) }
  })

  depends_on = [
    output.use1_vpc_ids,
    output.use1_subnet_1a_ids,
    output.use1_subnet_1b_ids,
    output.use1_internet_gateway_ids,
    output.use1_route_table_ids,
    output.use2_vpc_ids,
    output.use2_subnet_2a_ids,
    output.use2_subnet_2b_ids,
    output.use2_internet_gateway_ids,
    output.use2_route_table_ids,
    output.vpc_summary
  ]
}
