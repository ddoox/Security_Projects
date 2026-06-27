
provider "aws" {
  region = "us-east-1"
}

variable "availability_zone" {
  description = "Availability zone for the instances"
  default     = "us-east-1a"
}

variable "ssh_port" {
  description = "Port for SSH access"
  default     = "22"
}

variable "key_name" {
    description = "Name of the SSH key pair"
    default     = "My_SSH_Pair"
}


# Networking

resource "aws_vpc" "honeypot_vpc" {
    cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "private_subnet" {
    vpc_id     = aws_vpc.honeypot_vpc.id
    cidr_block = "10.0.1.0/24"
    availability_zone = var.availability_zone

}

resource "aws_subnet" "public_subnet" {
    vpc_id     = aws_vpc.honeypot_vpc.id
    cidr_block = "10.0.2.0/24"
    availability_zone = var.availability_zone
    map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "honeypot_igw" {
    vpc_id = aws_vpc.honeypot_vpc.id
}

resource "aws_route_table" "public_route_table" {
    vpc_id = aws_vpc.honeypot_vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.honeypot_igw.id
    }
}

resource "aws_route_table" "private_route_table" {
    vpc_id = aws_vpc.honeypot_vpc.id
}

resource "aws_route_table_association" "public_route_table_association" {
    subnet_id      = aws_subnet.public_subnet.id
    route_table_id = aws_route_table.public_route_table.id
}  

resource "aws_route_table_association" "private_route_table_association" {
    subnet_id      = aws_subnet.private_subnet.id
    route_table_id = aws_route_table.private_route_table.id
}


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


# Instances

resource "aws_instance" "wazuh" {
    ami           = "ami-08f44e8eca9095668"
    instance_type = "t3.micro"
    vpc_security_group_ids = [aws_security_group.allow_ssh.id]
    key_name = var.key_name
    subnet_id = aws_subnet.private_subnet.id
    availability_zone = var.availability_zone
}

resource "aws_instance" "honeypot" {
    ami           = "ami-08f44e8eca9095668"
    instance_type = "t3.micro"
    vpc_security_group_ids = [aws_security_group.allow_ssh.id, aws_security_group.allow_external_icmp.id]
    key_name = var.key_name
    subnet_id = aws_subnet.public_subnet.id
    availability_zone = var.availability_zone
}


# Outputs

output "wazuh_public_IP" {
    value = aws_instance.wazuh.public_ip
}

output "wazuh_private_IP" {
    value = aws_instance.wazuh.private_ip
}

output "honeypot_public_IP" {
    value = aws_instance.honeypot.public_ip
}

