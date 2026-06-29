resource "aws_security_group" "allow_ssh" {
    name        = "allow_ssh"
    description = "Allow SSH inbound traffic"
    vpc_id      = aws_vpc.honeypot_vpc.id
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
