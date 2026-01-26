# Outputs for the EC2 instance module

output "instance_id" {
  description = "The ID of the EC2 instance"
  value       = aws_instance.main.id
}

output "instance_arn" {
  description = "The ARN of the EC2 instance"
  value       = aws_instance.main.arn
}

output "instance_private_ip" {
  description = "The private IP address of the instance"
  value       = aws_instance.main.private_ip
}

output "instance_availability_zone" {
  description = "The AZ where the instance is running"
  value       = aws_instance.main.availability_zone
}

output "security_group_id" {
  description = "The ID of the security group"
  value       = aws_security_group.instance.id
}

output "iam_role_name" {
  description = "The name of the IAM role"
  value       = aws_iam_role.ec2_ssm_role.name
}

output "ami_id" {
  description = "The AMI ID used for the instance"
  value       = data.aws_ami.amazon_linux_2.id
}
