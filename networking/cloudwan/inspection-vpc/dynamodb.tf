# ============================================================================
# Update existing DynamoDB table with Inspection VPC Terraform output values
# ============================================================================

# Store key Inspection VPC values as a single item in the existing table.
# Complex values are JSON-serialized strings.
resource "aws_dynamodb_table_item" "inspection_vpc_outputs_item" {
  table_name = "cloudwan-project-tf-outputs"
  hash_key   = "id"

  item = jsonencode({
    id                  = { S = "inspection-vpc" }
    vpc_id              = { S = aws_vpc.main.id }
    vpc_cidr            = { S = aws_vpc.main.cidr_block }
    internet_gateway_id = { S = try(aws_internet_gateway.main[0].id, "") }
    subnets             = { S = jsonencode(aws_subnet.subnets) }
    route_tables        = { S = jsonencode(aws_route_table.subnet_rt) }
  })
}
