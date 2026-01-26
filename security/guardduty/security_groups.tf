# Security Group for Application Load Balancer
# Allows traffic from CloudFront prefix list only
resource "aws_security_group" "alb" {
  name_prefix = "${var.stack_name}-alb-"
  description = "Load Balancer Group"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.stack_name}-TheLoadBalancerAccessSecurityGroup"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Ingress rule: Allow HTTP traffic from CloudFront
resource "aws_security_group_rule" "alb_ingress_cloudfront" {
  type              = "ingress"
  description       = "Allow ${var.web_port}/tcp from CloudFront"
  from_port         = var.web_port
  to_port           = var.web_port
  protocol          = "tcp"
  prefix_list_ids   = [data.aws_ec2_managed_prefix_list.cloudfront.id]
  security_group_id = aws_security_group.alb.id
}

# Egress rule: Allow all outbound traffic from ALB
resource "aws_security_group_rule" "alb_egress_all" {
  type              = "egress"
  description       = "Allow access to anywhere"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
}

# Security Group for Web Servers (EC2 instances)
# Allows traffic from ALB only
resource "aws_security_group" "web_server" {
  name_prefix = "${var.stack_name}-web-"
  description = "Web Server Group"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.stack_name}-TheWebServerAccessSecurityGroup"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Ingress rule: Allow HTTP traffic from ALB
resource "aws_security_group_rule" "web_server_ingress_alb" {
  type                     = "ingress"
  description              = "Allow ${var.web_port}/tcp from Load Balancer"
  from_port                = var.web_port
  to_port                  = var.web_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.web_server.id
}

# Egress rule: Allow all outbound traffic from web servers
resource "aws_security_group_rule" "web_server_egress_all" {
  type              = "egress"
  description       = "Allow access to anywhere"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.web_server.id
}
