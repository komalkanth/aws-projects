# Network Interfaces
# Management NIC for Firewall in us-west-1a
resource "aws_network_interface" "management_1a" {
  subnet_id                 = aws_subnet.subnets["fw-mgmt-subnet-1a"].id                    # Management subnet 1a for firewall
  private_ips               = ["10.0.100.10"]                                               # 10th IP address in fw-mgmt-subnet-1a
  security_groups           = [aws_security_group.mgmt_sg.id]                               # Management security group for access control
  tags                      = {
    Name                    = "insp-fw-mgmt-1a-eni-001"                                     # Name of the NIC for AZ 1a
  }
}

# Management NIC for Firewall in us-west-1b
resource "aws_network_interface" "management_1b" {
  subnet_id                 = aws_subnet.subnets["fw-mgmt-subnet-1b"].id                    # Management subnet 1b for firewall
  private_ips               = ["10.0.100.42"]                                               # 10th IP address in fw-mgmt-subnet-1b
  security_groups           = [aws_security_group.mgmt_sg.id]                               # Management security group for access control
  tags                      = {
    Name                    = "insp-fw-mgmt-1b-eni-001"                                     # Name of the NIC for AZ 1b
  }
}

# Data NIC for Firewall in us-west-1a
resource "aws_network_interface" "data_1a" {
  subnet_id                 = aws_subnet.subnets["fw-data-subnet-1a"].id                    # Data subnet 1a for firewall
  private_ips               = ["10.0.100.74"]                                               # 10th IP address in fw-data-subnet-1a
  security_groups           = [aws_security_group.fw_data_sg.id]                               # Data security group for access control
  source_dest_check         = false                                                         # Disable source/dest check for routing
  tags                      = {
    Name                    = "insp-fw-data-1a-eni-001"                                     # Name of the NIC for AZ 1a
  }
}

# Data NIC for Firewall in us-west-1b
resource "aws_network_interface" "data_1b" {
  subnet_id                 = aws_subnet.subnets["fw-data-subnet-1b"].id                    # Data subnet 1b for firewall
  private_ips               = ["10.0.100.106"]                                              # 10th IP address in fw-data-subnet-1b
  security_groups           = [aws_security_group.fw_data_sg.id]                               # Data security group for access control
  source_dest_check         = false                                                         # Disable source/dest check for routing
  tags                      = {
    Name                    = "insp-fw-data-1b-eni-001"                                     # Name of the NIC for AZ 1b
  }
}

# Elastic IPs
# Elastic IP for Firewall management interface in us-west-1a
resource "aws_eip" "management_1a" {
  domain                    = "vpc"                                                         # VPC domain for Elastic IP
  network_interface         = aws_network_interface.management_1a.id                        # Management NIC for Firewall in AZ 1a
  associate_with_private_ip = "10.0.100.10"                                                 # Specific private IP for EIP association
  depends_on                = [aws_internet_gateway.main]                               # Ensure internet gateway exists
  tags                      = {
    Name                    = "insp-fw-mgmt-1a-eip-001"                                     # Name of the EIP for AZ 1a
  }
}

# Elastic IP for Firewall management interface in us-west-1b
resource "aws_eip" "management_1b" {
  domain                    = "vpc"                                                         # VPC domain for Elastic IP
  network_interface         = aws_network_interface.management_1b.id                        # Management NIC for Firewall in AZ 1b
  associate_with_private_ip = "10.0.100.42"                                                 # Specific private IP for EIP association
  depends_on                = [aws_internet_gateway.main]                               # Ensure internet gateway exists
  tags                      = {
    Name                    = "insp-fw-mgmt-1b-eip-001"                                     # Name of the EIP for AZ 1b
  }
}

                                                                                            # Palo Alto Firewall Instance 1a
resource "aws_instance" "palo_alto_1a" {
  ami                       = var.firewall_ami                                              # VM-Series AMI for Palo Alto firewall
  instance_type             = var.firewall_instance_type                                    # Instance type for firewall
  key_name                  = var.key_name                                                  # Key pair for SSH access
  primary_network_interface {
    network_interface_id    = aws_network_interface.management_1a.id                        # Management NIC as primary interface
  }
                                                                                            # User data for DHCP configuration
  user_data                 = <<-EOF
                            type=dhcp-client
                            EOF
  tags                      = {
    Name                    = "insp-fw-1a"                                                  # Name of Firewall 1a
  }
}

# Palo Alto Firewall Instance 1b
resource "aws_instance" "palo_alto_1b" {
  ami                       = var.firewall_ami                                              # VM-Series AMI for Palo Alto firewall
  instance_type             = var.firewall_instance_type                                    # Instance type for firewall
  key_name                  = var.key_name                                                  # Key pair for SSH access
  primary_network_interface {
    network_interface_id    = aws_network_interface.management_1b.id                        # Management NIC as primary interface
  }
                                                                                            # User data for DHCP configuration
  user_data                 = <<-EOF
                            type=dhcp-client
                            EOF
  tags                      = {
    Name                    = "insp-fw-1b"                                                  # Name of Firewall 1b
  }
}
                                                                                            # Attach Data NIC to Firewall 1a
resource "aws_network_interface_attachment" "fw_nic_data_1a" {
  instance_id               = aws_instance.palo_alto_1a.id                                  # Firewall instance
  network_interface_id      = aws_network_interface.data_1a.id                              # Data NIC
  device_index              = 1                                                             # Data interface index
}
                                                                                            # Attach Data NIC to Firewall 1b
resource "aws_network_interface_attachment" "fw_nic_data_1b" {
  instance_id               = aws_instance.palo_alto_1b.id                                  # Firewall instance
  network_interface_id      = aws_network_interface.data_1b.id                              # Data NIC
  device_index              = 1                                                             # Data interface index
}
                                                                                            # Outputs
                                                                                            # Output for firewall management IP 1a
output "management_public_ip_1a" {
  description               = "Management interface public IP for Firewall 1a"              # Description of the output
  value                     = aws_eip.management_1a.public_ip                               # Public IP for firewall management
}

                                                                                            # Output for firewall management IP 1b
output "management_public_ip_1b" {
  description               = "Management interface public IP for Firewall 1b"              # Description of the output
  value                     = aws_eip.management_1b.public_ip                               # Public IP for firewall management
}