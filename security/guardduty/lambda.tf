


# Lambda function for automated remediation
# Revokes IAM sessions issued before a GuardDuty finding timestamp
resource "aws_lambda_function" "remediation" {
  filename         = "remediation_lambda.zip"
  function_name    = "${var.stack_name}-remediation"
  role             = aws_iam_role.lambda_remediation_role.arn
  handler          = "index.lambda_handler"
  source_code_hash = filebase64sha256("remediation_lambda.zip")
  runtime          = "python3.11"
  timeout          = 60

  tags = {
    Name = "${var.stack_name}-RemediationLambda"
  }
}

