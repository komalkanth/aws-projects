# GuardDuty Detector
# Enables continuous security monitoring across AWS services
resource "aws_guardduty_detector" "main" {
  enable = true

  # Check for findings every 15 minutes
  finding_publishing_frequency = "FIFTEEN_MINUTES"

  # Enable S3 data event monitoring
  datasources {
    s3_logs {
      enable = true
    }

    kubernetes {
      audit_logs {
        enable = true
      }
    }

    malware_protection {
      scan_ec2_instance_with_findings {
        ebs_volumes {
          enable = true
        }
      }
    }
  }

  tags = {
    Name = "${var.stack_name}-GuardDuty"
  }
}
