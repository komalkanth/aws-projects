# ============================================================================
# Update existing DynamoDB table with CloudWAN Terraform output values
# ============================================================================

# Store key Cloud WAN values as a single item in the existing table.
# Complex values are JSON-serialized strings.
resource "aws_dynamodb_table_item" "cloudwan_outputs_item" {
  table_name = "cloudwan-project-tf-outputs"
  hash_key   = "id"

  item = jsonencode({
    id                    = { S = "cloudwan" }
    global_network_id     = { S = aws_networkmanager_global_network.global-oldies-network.id }
    global_network_arn    = { S = aws_networkmanager_global_network.global-oldies-network.arn }
    core_network_id       = { S = aws_networkmanager_core_network.oldies-core-network.id }
    core_network_arn      = { S = aws_networkmanager_core_network.oldies-core-network.arn }
    core_network_state    = { S = aws_networkmanager_core_network.oldies-core-network.state }
    core_network_edges    = { S = jsonencode(aws_networkmanager_core_network.oldies-core-network.edges) }
    core_network_segments = { S = jsonencode(aws_networkmanager_core_network.oldies-core-network.segments) }
  })
}