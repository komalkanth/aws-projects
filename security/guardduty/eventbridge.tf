# EventBridge Rule for GuardDuty Findings
# Triggers Lambda function when IAM credentials are exfiltrated
resource "aws_cloudwatch_event_rule" "guardduty_remediation" {
  name_prefix = "${var.stack_name}-remediation-"
  description = "GuardDuty EC2 Credential Remediation Rule"
  state       = "ENABLED"

  # Match GuardDuty findings for credential exfiltration
  event_pattern = jsonencode({
    source      = ["aws.guardduty", "security.workshop"]
    detail-type = ["GuardDuty Finding"]
    detail = {
      type = [
        "UnauthorizedAccess:IAMUser/InstanceCredentialExfiltration.OutsideAWS",
        "UnauthorizedAccess:IAMUser/InstanceCredentialExfiltration.InsideAWS"
      ]
    }
  })
}

# EventBridge Target for Lambda
# Extracts role name and timestamp from GuardDuty finding
resource "aws_cloudwatch_event_target" "remediation_lambda" {
  rule      = aws_cloudwatch_event_rule.guardduty_remediation.name
  target_id = "lambda-remediation"
  arn       = aws_lambda_function.remediation.arn

  # Transform GuardDuty event to Lambda input
  input_transformer {
    input_paths = {
      role_name = "$.detail.resource.accessKeyDetails.userName"
      timestamp = "$.detail.service.eventLastSeen"
    }

    input_template = <<EOF
{
  "RoleName": "<role_name>",
  "PolicyDocument": {
    "Version": "2012-10-17",
    "Statement": {
      "Effect": "Deny",
      "Action": "*",
      "Resource": "*",
      "Condition": {
        "DateLessThan": {
          "aws:TokenIssueTime": "<timestamp>"
        }
      }
    }
  }
}
EOF
  }
}

# Grant EventBridge permission to invoke Lambda
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.remediation.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.guardduty_remediation.arn
}
