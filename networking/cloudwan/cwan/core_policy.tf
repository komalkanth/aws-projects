# ============================================================================
# Core Network Policy Document
# ============================================================================
# This data source generates the JSON policy for the core network
data "aws_networkmanager_core_network_policy_document" "main" {
  core_network_configuration {
    vpn_ecmp_support = false
    asn_ranges       = ["64512-65534"]

    # Edge Location: us-east-1
    edge_locations {
      location = "us-east-1"
      asn      = 64512
    }

    # Edge Location: us-east-2
    edge_locations {
      location = "us-east-2"
      asn      = 64513
    }

    # Edge Location: us-west-1
    edge_locations {
      location = "us-west-1"
      asn      = 64514
    }
  }

  # Minimal segment required for core network policy
  segments {
    name = "default"
  }

  # Production segment
  segments {
    name = "production"
  }

  # Development segment
  segments {
    name                          = "development"
    require_attachment_acceptance = false
  }

  # Customer segment
  segments {
    name                          = "customer"
    require_attachment_acceptance = true
  }

  # Attachment policy for prod VPC attachments
  attachment_policies {
    rule_number     = 100
    condition_logic = "and"

    conditions {
      type     = "tag-value"
      operator = "equals"
      key      = "Environment"
      value    = "prod"
    }

    conditions {
      type     = "attachment-type"
      operator = "equals"
      value    = "vpc"
    }

    action {
      association_method = "constant"
      segment            = "production"
    }
  }

  # Attachment policy for dev VPC attachments
  attachment_policies {
    rule_number     = 200
    condition_logic = "and"

    conditions {
      type     = "tag-value"
      operator = "equals"
      key      = "Environment"
      value    = "dev"
    }

    conditions {
      type     = "attachment-type"
      operator = "equals"
      value    = "vpc"
    }

    action {
      association_method = "constant"
      segment            = "development"
    }
  }

  # Attachment policy for customer VPC attachments
  attachment_policies {
    rule_number     = 300
    condition_logic = "and"

    conditions {
      type     = "tag-value"
      operator = "equals"
      key      = "Environment"
      value    = "customer"
    }

    conditions {
      type     = "attachment-type"
      operator = "equals"
      value    = "vpc"
    }

    action {
      association_method = "constant"
      segment            = "customer"
    }
  }

  # Segment action to share production segment with customer segment
  segment_actions {
    action     = "share"
    mode       = "attachment-route"
    segment    = "production"
    share_with = ["customer"]
  }

  # Segment action to send traffic from customer to production via Inspection VPC
  segment_actions {
    action  = "send-via"
    mode    = "single-hop"
    segment = "customer"

    via {
      network_function_groups = ["InspectionVPC"]
    }

    when_sent_to {
      segments = ["production"]
    }
  }

  # Segment action to send traffic from development to the internet via Inspection VPC
  segment_actions {
    action  = "send-to"
    segment = "development"

    via {
      network_function_groups = ["InspectionVPC"]
    }
  }

  network_function_groups {
    name                           = "InspectionVPC"
    description                    = "Route segment traffic to the inspection VPC"
    require_attachment_acceptance = true
  }
}

