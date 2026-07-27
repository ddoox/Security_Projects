resource "aws_security_group" "allow_ssh_honeypot" {
  name        = "allow_ssh_honeypot"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.honeypot_vpc.id
  ingress {
    from_port   = var.honeypot_true_ssh_port
    to_port     = var.honeypot_true_ssh_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Placeholder for repository - to harden access replace with own IP + /32
  }
  ingress {
    from_port   = var.ssh_port
    to_port     = var.ssh_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "allow_external_icmp" {
  name        = "allow_icmp"
  description = "Allow ICMP outbound traffic for diagnostics"
  vpc_id      = aws_vpc.honeypot_vpc.id
  egress {
    from_port   = "-1"
    to_port     = "-1"
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "allow_egress_internet" {
  name        = "allow_egress_internet"
  description = "Allow outbound traffic for payloads download on honeypots"
  vpc_id      = aws_vpc.honeypot_vpc.id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Egress rules below are redundant, can be used when allow_egress_internet is removed(disabling download capabilties on honeypots other than via ssh)
resource "aws_security_group" "wazuh_agent_ports" {
  name        = "wazuh_agent_ports"
  description = "Allow Wazuh agent ports for communication"
  vpc_id      = aws_vpc.honeypot_vpc.id
  egress {
    from_port   = 1514
    to_port     = 1515
    protocol    = "tcp"
    cidr_blocks = ["${var.wazuh_manager_ip}/32"]
  }
}

resource "aws_security_group" "wazuh_manager_ports" {
  name        = "wazuh_manager_ports"
  description = "Allow Wazuh manager ports for communication"
  vpc_id      = aws_vpc.honeypot_vpc.id
  ingress {
    from_port   = 1514
    to_port     = 1515
    protocol    = "tcp"
    cidr_blocks = [var.public_subnet_cidr]
  }
}

resource "aws_security_group" "vpc_endpoints" {
  name        = "vpc_endpoints"
  description = "Security group for VPC Endpoints"
  vpc_id      = aws_vpc.honeypot_vpc.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.private_subnet_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# Security Group for EC2 instance using SSM
resource "aws_security_group" "ec2_ssm_outbound" {
  name        = "ec2_ssm_outbound"
  description = "Allow outbound HTTPS for SSM Agent to VPC Endpoints"
  vpc_id      = aws_vpc.honeypot_vpc.id

  egress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.vpc_endpoints.id]
  }
}
