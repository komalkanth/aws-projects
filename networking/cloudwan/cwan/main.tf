# ============================================================================
# AWS Cloud WAN - Global Network and Core Network Configuration
# ============================================================================
# This configuration creates:
# - A Global Network (container for network objects)
# - A Core Network with three edge locations: us-east-1, us-east-2, us-west-1
# ============================================================================

# ============================================================================
# Global Network
# ============================================================================
# A Global Network is a container for your core network and network objects
resource "aws_networkmanager_global_network" "global-oldies-network" {
  description = "Global Network for Cloud WAN"

  tags = {
    Name        = "cloudwan-global-network"
    Environment = "production"
    ManagedBy   = "terraform"
    Project     = "CloudWAN"
  }
}

# ============================================================================
# Core Network
# ============================================================================
# The Core Network is deployed within the Global Network
resource "aws_networkmanager_core_network" "oldies-core-network" {
  global_network_id = aws_networkmanager_global_network.global-oldies-network.id
  description       = "Core Network with edge locations in us-east-1, us-east-2, and us-west-1"

  # Create a base policy to allow attachments before the full policy is applied
  create_base_policy  = true
  base_policy_regions = ["us-east-1", "us-east-2", "us-west-1"]

  tags = {
    Name        = "cloudwan-core-network"
    Environment = "production"
    ManagedBy   = "terraform"
    Project     = "CloudWAN"
  }
}

# ============================================================================
# Core Network Policy Attachment
# ============================================================================
# Attach the policy document to the core network
resource "aws_networkmanager_core_network_policy_attachment" "main" {
  core_network_id = aws_networkmanager_core_network.oldies-core-network.id
  policy_document = data.aws_networkmanager_core_network_policy_document.main.json
}


