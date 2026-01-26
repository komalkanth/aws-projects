# Launch Template for EC2 instances
# Configures Ubuntu 20.04 instances running OWASP Juice Shop
resource "aws_launch_template" "web" {
  name_prefix   = "${var.stack_name}-web-"
  image_id      = data.aws_ssm_parameter.ubuntu_ami.value
  instance_type = "t2.micro"

  iam_instance_profile {
    arn = aws_iam_instance_profile.ec2_profile.arn
  }

  # Root volume configuration
  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = 20
      volume_type           = "gp3"
      delete_on_termination = true
    }
  }

  # Network configuration
  network_interfaces {
    associate_public_ip_address = true
    delete_on_termination       = true
    security_groups             = [aws_security_group.web_server.id]
  }

  instance_initiated_shutdown_behavior = "terminate"

  # User data script to install and configure Juice Shop
  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    stack_name    = var.stack_name
    aws_region    = data.aws_region.current.name
    secure_bucket = aws_s3_bucket.secure.id
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = var.stack_name
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group for managing web server instances
# Ensures high availability across multiple AZs
resource "aws_autoscaling_group" "web" {
  name_prefix         = "${var.stack_name}-web-"
  vpc_zone_identifier = aws_subnet.public_subnet[*].id
  target_group_arns   = [aws_lb_target_group.web.arn]
  health_check_type   = "ELB"
  min_size            = 1
  max_size            = 2
  desired_capacity    = 1

  # Fast scaling configuration
  default_cooldown          = 0
  default_instance_warmup   = 10
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = var.stack_name
    propagate_at_launch = true
  }

  # Lifecycle configuration for updates
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
      instance_warmup        = 300
    }
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [aws_lb.main]
}
