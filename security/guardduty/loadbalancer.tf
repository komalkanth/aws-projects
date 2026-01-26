# Application Load Balancer
# Distributes traffic across web server instances
resource "aws_lb" "main" {
  name_prefix        = "ngd-"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public_subnet[*].id

  tags = {
    Name = "${var.stack_name}-ALB"
  }
}

# Target Group for web servers
# Health checks ensure only healthy instances receive traffic
resource "aws_lb_target_group" "web" {
  name_prefix = "ngd-"
  port        = var.web_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"

  # Health check configuration
  health_check {
    enabled             = true
    healthy_threshold   = 3
    unhealthy_threshold = 10
    interval            = 10
    path                = "/"
    port                = var.web_port
    protocol            = "HTTP"
    timeout             = 5
    matcher             = "200-299"
  }

  # Fast deregistration for testing
  deregistration_delay = 0

  tags = {
    Name = "${var.stack_name}-TargetGroup"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# HTTP Listener for ALB
# Forwards traffic to target group
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = var.web_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}
