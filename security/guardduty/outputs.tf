# CloudFront distribution URL
# Public URL to access the Juice Shop application
output "juiceshop_url" {
  description = "The public URL of the Juice Shop application"
  value       = "https://${aws_cloudfront_distribution.main.domain_name}"
}

# S3 VPC Endpoint ID
output "s3_vpc_endpoint_id" {
  description = "The S3 VPC Endpoint that was created"
  value       = aws_vpc_endpoint.s3.id
}

# Secure S3 bucket name
output "secure_bucket" {
  description = "The S3 bucket that was created"
  value       = aws_s3_bucket.secure.id
}

# EC2 IAM role ARN
output "ec2_role_arn" {
  description = "The EC2 instance IAM role"
  value       = aws_iam_role.ec2_role.arn
}

# Application Load Balancer DNS name
output "alb_dns_name" {
  description = "The DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

# GuardDuty Detector ID
output "guardduty_detector_id" {
  description = "The GuardDuty Detector ID"
  value       = aws_guardduty_detector.main.id
}

# Lambda function ARN
output "lambda_function_arn" {
  description = "The Lambda function ARN for remediation"
  value       = aws_lambda_function.remediation.arn
}
