resource "aws_security_group" "allow_ssh_honeypot" {
    name        = "allow_ssh_honeypot"
    description = "Allow SSH inbound traffic"
    vpc_id      = aws_vpc.honeypot_vpc.id
        ingress {
            from_port   = var.honeypot_ssh_port
            to_port     = var.honeypot_ssh_port
            protocol    = "tcp"
            cidr_blocks = ["0.0.0.0/0"]
        }
        ingress {
            from_port   = var.ssh_port
            to_port     = var.ssh_port
            protocol    = "tcp"
            cidr_blocks = ["0.0.0.0/0"]
        }
        egress {
            from_port   = var.ssh_port
            to_port     = var.ssh_port
            protocol    = "tcp"
            cidr_blocks = ["10.0.1.0/24"]
        }
}

resource "aws_security_group" "allow_ssh_wazuh" {
    name        = "allow_ssh_wazuh"
    description = "Allow SSH inbound traffic"
    vpc_id      = aws_vpc.honeypot_vpc.id
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

resource "aws_security_group" "allow_inbound_http" {
    name        = "allow_http"
    description = "Allow HTTP inbound traffic"
    vpc_id      = aws_vpc.honeypot_vpc.id
        ingress {
            from_port   = 80
            to_port     = 80
            protocol    = "tcp"
            cidr_blocks = ["0.0.0.0/0"]
        }
        ingress {
            from_port   = 443
            to_port     = 443
            protocol    = "tcp"
            cidr_blocks = ["0.0.0.0/0"]
        }
}

resource "aws_security_group" "temporary_allow_Internet" {
    name        = "temporary_allow_Internet"
    description = "Allow Internet traffic for debug purposes"
    vpc_id      = aws_vpc.honeypot_vpc.id
        egress {
            from_port   = 0
            to_port     = 0
            protocol    = "-1"
            cidr_blocks = ["0.0.0.0/0"]
        }
}

resource "aws_security_group" "wazuh_agent_ports" {
    name        = "wazuh_agent_ports"
    description = "Allow Wazuh agent ports for communication"
    vpc_id      = aws_vpc.honeypot_vpc.id
        egress {
            from_port   = 1514
            to_port     = 1515
            protocol    = "tcp"
            cidr_blocks = ["100.87.168.87/32"]
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
            cidr_blocks = ["10.0.2.0/24"]
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
    cidr_blocks = [aws_subnet.private_subnet.cidr_block]
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
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    security_groups = [aws_security_group.vpc_endpoints.id]
  }
}

# Security Group for EC2 instance using SSM
resource "aws_security_group" "tailscale_P2P" {
  name        = "Tailscale_P2P"
  description = "Allow Tailscale P2P traffic"
  vpc_id      = aws_vpc.honeypot_vpc.id

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 3478
    to_port     = 3478
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 41641
    to_port     = 41641
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}