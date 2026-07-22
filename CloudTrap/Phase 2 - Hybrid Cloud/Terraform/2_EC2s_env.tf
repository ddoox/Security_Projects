
provider "aws" {
  region = "us-east-1"
}

variable "tailscale_authkey" {
  type      = string
  sensitive = true
}

# Networking

resource "aws_vpc" "honeypot_vpc" {
    cidr_block = "10.0.0.0/16"
    # Enable DNS for VPC Endpoints
    enable_dns_support   = true
    enable_dns_hostnames = true
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
    # route {
    #         cidr_block     = "0.0.0.0/0"
    #         nat_gateway_id = aws_nat_gateway.honeypot_nat.id
    #     }
}

resource "aws_route_table_association" "public_route_table_association" {
    subnet_id      = aws_subnet.public_subnet.id
    route_table_id = aws_route_table.public_route_table.id
}  

resource "aws_route_table_association" "private_route_table_association" {
    subnet_id      = aws_subnet.private_subnet.id
    route_table_id = aws_route_table.private_route_table.id
}


# Instances

resource "aws_instance" "honeypot" {
    ami = data.aws_ami.latest_honeypot_image.id
    instance_type = "t3.micro"
    count = 5
    vpc_security_group_ids = [
        aws_security_group.allow_ssh_honeypot.id, 
        aws_security_group.wazuh_agent_ports.id,
        aws_security_group.tailscale_P2P.id
    ]
    key_name = var.key_name
    subnet_id = aws_subnet.public_subnet.id
    availability_zone = var.availability_zone

    user_data = <<-EOF
              #!/bin/bash
              
              # Variables
              TS_AUTHKEY="${var.tailscale_authkey}" 
              INSTANCE_HOSTNAME="cloudtrap-honeypot-${count.index}-$(date +%m%d%y-%H%M%S)"

              HOSTNAME="${var.honeypot_hostnames[count.index % length(var.honeypot_hostnames)]}"
              USER="${var.honeypot_users[count.index % length(var.honeypot_users)]}"
              PASSWORD="${var.honeypot_passwords[count.index % length(var.honeypot_passwords)]}"
            
              sed -i "s/^hostname = svr04/hostname = $HOSTNAME/" /opt/cowrie/etc/cowrie.cfg
              echo "$USER:0:$PASSWORD" > /opt/cowrie/etc/userdb.txt
              chown ec2-user:ec2-user /opt/cowrie/etc/cowrie.cfg /opt/cowrie/etc/userdb.txt


              # Set hostname for the instance
              hostnamectl set-hostname $INSTANCE_HOSTNAME
              
              # Tailscale registration
              tailscale up --authkey=$TS_AUTHKEY --hostname=$INSTANCE_HOSTNAME --accept-routes=false
              
              sleep 5
              
              systemctl enable wazuh-agent
              systemctl start wazuh-agent
              systemctl enable cowrie
              systemctl start cowrie

              EOF

}


# Outputs

output "honeypot_public_IPs" {
    value = aws_instance.honeypot[*].public_ip
}

output "honeypot_private_IPs" {
    value = aws_instance.honeypot[*].private_ip
}
