# Data source to get the latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# IAM role for Systems Manager access
resource "aws_iam_role" "ec2_ssm_role" {
  name_prefix = "${var.vpc_name}-ec2-ssm-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.vpc_name}-ec2-ssm-role"
      VPC         = var.vpc_name
      Environment = var.environment
      Project     = "CloudWAN"
    }
  )
}

# Attach Systems Manager policy
resource "aws_iam_role_policy_attachment" "ssm_managed_instance_core" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# IAM instance profile for the role
resource "aws_iam_instance_profile" "ec2_profile" {
  name_prefix = "${var.vpc_name}-ec2-"
  role        = aws_iam_role.ec2_ssm_role.name
}

# Security group for the instance
resource "aws_security_group" "instance" {
  name_prefix = "${var.vpc_name}-instance-"
  description = "Security group for EC2 instance in ${var.vpc_name}"
  vpc_id      = var.vpc_id

  # Allow all outbound traffic (required for Systems Manager)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.vpc_name}-instance-sg"
      VPC         = var.vpc_name
      Environment = var.environment
      Project     = "CloudWAN"
    }
  )
}

# EC2 Instance
resource "aws_instance" "main" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  vpc_security_group_ids = [aws_security_group.instance.id]

  # Disable public IP association by default (can access via Systems Manager)
  associate_public_ip_address = false

  # Enable detailed monitoring
  monitoring = true

  # User data (optional - can add custom initialization)
  user_data_base64 = base64encode(<<-EOF
              #!/bin/bash
              yum update -y
              EOF
  )

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.vpc_name}-instance"
      VPC         = var.vpc_name
      Environment = var.environment
      Project     = "CloudWAN"
    }
  )

  depends_on = [
    aws_iam_role_policy_attachment.ssm_managed_instance_core
  ]
}
