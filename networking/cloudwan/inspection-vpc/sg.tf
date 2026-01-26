resource "aws_security_group" "mgmt_sg" {
  name                  = "insp-fw-mgmt-sg"                                  # Name of the security group
  vpc_id                = aws_vpc.main.id                                     # VPC for the security group
  ingress {
    description         = "HTTPS from your IP"                                # Description of the rule
    from_port           = 443                                                 # HTTPS port
    to_port             = 443                                                 # HTTPS port
    protocol            = "tcp"                                               # Protocol for HTTPS
    cidr_blocks         = [var.my_public_ip]                                  # Source IP for management access
  }
  ingress {
    description         = "SSH from your IP"                                  # Description of the rule
    from_port           = 22                                                  # SSH port
    to_port             = 22                                                  # SSH port
    protocol            = "tcp"                                               # Protocol for SSH
    cidr_blocks         = [var.my_public_ip]                                  # Source IP for management access
  }
  egress {
    from_port           = 0                                                   # All ports for outbound traffic
    to_port             = 0                                                   # All ports for outbound traffic
    protocol            = "-1"                                                # All protocols for outbound traffic
    cidr_blocks         = ["0.0.0.0/0"]                                       # Allow all outbound destinations
  }
  tags                  = {
    Name                = "insp-fw-mgmt-sg"                                   # Name of the security group
  }
}

resource "aws_security_group" "fw_data_sg" {
  name                  = "insp-fw-data-sg"                                   # Name of the security group
  vpc_id                = aws_vpc.main.id                                     # VPC for the security group
  ingress {
    description         = "All traffic"                                       # Description of the rule
    from_port           = 0                                                   # All ports
    to_port             = 0                                                   # All ports
    protocol            = "-1"                                                # All protocols
    cidr_blocks         = ["0.0.0.0/0"]                                       # Allow all inbound traffic
  }
  egress {
    from_port           = 0                                                   # All ports for outbound traffic
    to_port             = 0                                                   # All ports for outbound traffic
    protocol            = "-1"                                                # All protocols for outbound traffic
    cidr_blocks         = ["0.0.0.0/0"]                                       # Allow all outbound destinations
  }
  tags                  = {
    Name                = "insp-fw-data-sg"                                   # Name of the security group
  }
}