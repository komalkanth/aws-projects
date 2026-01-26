# IAM Role for EC2 instances
# Provides permissions for SSM access and S3 operations
resource "aws_iam_role" "ec2_role" {
  name_prefix = "${var.stack_name}-ec2-role-"
  description = "IAM role for EC2 instances in GuardDuty project"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.${data.aws_partition.current.dns_suffix}"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

}

# Attach AWS managed policy for SSM
resource "aws_iam_role_policy_attachment" "ec2_ssm_managed" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Ensure Terraform exclusively manages EC2 role managed policy attachments
resource "aws_iam_role_policy_attachments_exclusive" "ec2_role" {
  role_name   = aws_iam_role.ec2_role.name
  policy_arns = [aws_iam_role_policy_attachment.ec2_ssm_managed.policy_arn]
}

# Inline policy for S3 access
# Grants specific permissions to interact with the secure bucket
resource "aws_iam_role_policy" "ec2_s3_policy" {
  name = "InstancePolicy"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:GetObjectAcl",
          "s3:PutObjectAcl",
          "s3:DeleteObject"
        ]
        Resource = "${aws_s3_bucket.secure.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketPolicy",
          "s3:GetEncryptionConfiguration"
        ]
        Resource = aws_s3_bucket.secure.arn
      }
    ]
  })
}

# Instance profile to attach IAM role to EC2 instances
resource "aws_iam_instance_profile" "ec2_profile" {
  name_prefix = "${var.stack_name}-ec2-profile-"
  role        = aws_iam_role.ec2_role.name
}

# Lambda execution role for remediation
# Allows Lambda to execute and call IAM APIs
resource "aws_iam_role" "lambda_remediation_role" {
  name_prefix = "${var.stack_name}-lambda-rem-"
  description = "IAM role for Lambda to perform GuardDuty remediation"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.${data.aws_partition.current.dns_suffix}"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Policy for Lambda to put role policies (revoke sessions)
resource "aws_iam_role_policy" "lambda_remediation_policy" {
  name = "LambdaRemediationPolicy"
  role = aws_iam_role.lambda_remediation_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iam:PutRolePolicy",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}
