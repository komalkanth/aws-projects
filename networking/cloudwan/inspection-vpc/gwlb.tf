# ============================================================================
# AWS Gateway Load Balancer Configuration for Inspection VPC
# ============================================================================

# Gateway Load Balancer Target Group
resource "aws_lb_target_group" "gwlb_tg" {
  name            = "insp-gwlb-tg"
  port            = 6081
  protocol        = "GENEVE"
  vpc_id          = aws_vpc.main.id
  target_type     = "instance"

  health_check {
    enabled             = true
    healthy_threshold   = 3
    unhealthy_threshold = 3
    interval            = 10
    timeout             = 5
    matcher             = "200-399"
    port                = "80"
    protocol            = "HTTP"
    path                = "/"
  }

  tags = {
    Name    = "insp-gwlb-tg"
    Project = "CloudWAN"
  }
}

# Gateway Load Balancer
resource "aws_lb" "gwlb" {
  name               = "insp-gwlb"
  internal           = false
  load_balancer_type = "gateway"
  subnets = [
    aws_subnet.subnets["fw-data-subnet-1a"].id,
    aws_subnet.subnets["fw-data-subnet-1b"].id
  ]
  enable_deletion_protection = false

  tags = {
    Name    = "insp-gwlb"
    Project = "CloudWAN"
  }
}

# GWLB Listener
resource "aws_lb_listener" "gwlb_listener" {
  load_balancer_arn = aws_lb.gwlb.arn
  port              = "6081"
  protocol          = "GENEVE"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.gwlb_tg.arn
  }
}

# Register Palo Alto firewall instances as targets for GWLB
resource "aws_lb_target_group_attachment" "gwlb_target_palo_alto_1a" {
  target_group_arn = aws_lb_target_group.gwlb_tg.arn
  target_id        = aws_instance.palo_alto_1a.id
  port             = 6081
}

resource "aws_lb_target_group_attachment" "gwlb_target_palo_alto_1b" {
  target_group_arn = aws_lb_target_group.gwlb_tg.arn
  target_id        = aws_instance.palo_alto_1b.id
  port             = 6081
}

# VPC Endpoint Service for the Gateway Load Balancer
resource "aws_vpc_endpoint_service" "gwlb_service" {
  acceptance_required        = false
  gateway_load_balancer_arns = [aws_lb.gwlb.arn]

  tags = {
    Name    = "insp-gwlb-service"
    Project = "CloudWAN"
  }
}

# Gateway Load Balancer VPC Endpoint in us-west-1a
resource "aws_vpc_endpoint" "gwlb_endpoint_1a" {
  service_name      = aws_vpc_endpoint_service.gwlb_service.service_name
  subnet_ids        = [aws_subnet.subnets["gwlb-endpnt-subnet-1a"].id]
  vpc_endpoint_type = "GatewayLoadBalancer"
  vpc_id            = aws_vpc.main.id

  tags = {
    Name    = "insp-gwlb-endpoint-1a"
    Project = "CloudWAN"
  }
}

# Gateway Load Balancer VPC Endpoint in us-west-1b
resource "aws_vpc_endpoint" "gwlb_endpoint_1b" {
  service_name      = aws_vpc_endpoint_service.gwlb_service.service_name
  subnet_ids        = [aws_subnet.subnets["gwlb-endpnt-subnet-1b"].id]
  vpc_endpoint_type = "GatewayLoadBalancer"
  vpc_id            = aws_vpc.main.id

  tags = {
    Name    = "insp-gwlb-endpoint-1b"
    Project = "CloudWAN"
  }
}

# ============================================================================
# Outputs
# ============================================================================

output "gwlb_arn" {
  description = "ARN of the Gateway Load Balancer"
  value       = aws_lb.gwlb.arn
}

output "gwlb_dns_name" {
  description = "DNS name of the Gateway Load Balancer"
  value       = aws_lb.gwlb.dns_name
}

output "gwlb_service_name" {
  description = "Service name of the GWLB endpoint service"
  value       = aws_vpc_endpoint_service.gwlb_service.service_name
}

output "gwlb_endpoint_1a_id" {
  description = "ID of GWLB endpoint in us-west-1a"
  value       = aws_vpc_endpoint.gwlb_endpoint_1a.id
}

output "gwlb_endpoint_1b_id" {
  description = "ID of GWLB endpoint in us-west-1b"
  value       = aws_vpc_endpoint.gwlb_endpoint_1b.id
}
