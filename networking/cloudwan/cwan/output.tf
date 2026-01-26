# ============================================================================
# Outputs
# ============================================================================
output "global_network_id" {
  description = "The ID of the Global Network"
  value       = aws_networkmanager_global_network.global-oldies-network.id
}

output "global_network_arn" {
  description = "The ARN of the Global Network"
  value       = aws_networkmanager_global_network.global-oldies-network.arn
}

output "core_network_id" {
  description = "The ID of the Core Network"
  value       = aws_networkmanager_core_network.oldies-core-network.id
}

output "core_network_arn" {
  description = "The ARN of the Core Network"
  value       = aws_networkmanager_core_network.oldies-core-network.arn
}

output "core_network_state" {
  description = "The current state of the Core Network"
  value       = aws_networkmanager_core_network.oldies-core-network.state
}

output "core_network_edges" {
  description = "The edge locations of the Core Network"
  value       = aws_networkmanager_core_network.oldies-core-network.edges
}

output "core_network_segments" {
  description = "The segments of the Core Network"
  value       = aws_networkmanager_core_network.oldies-core-network.segments
}
