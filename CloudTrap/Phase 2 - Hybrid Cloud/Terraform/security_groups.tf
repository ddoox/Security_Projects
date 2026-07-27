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

# Rules below are redundant, can be used when allow_egress_internet is removed(disabling download capabilties on honeypots other than via ssh)
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

resource "aws_security_group" "tailscale_p2p" {
  name        = "tailscale_p2p"
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
