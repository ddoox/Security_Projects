
provider "aws" {
  region = "us-east-1"
}

# Networking

resource "aws_vpc" "honeypot_vpc" {
    cidr_block = "10.0.0.0/16"
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

resource "aws_instance" "wazuh" {
    ami = data.aws_ami.latest_wazuh_image.id
    instance_type = "m7i-flex.large"
    vpc_security_group_ids = [
        aws_security_group.wazuh_manager_ports.id,
        aws_security_group.ec2_ssm_outbound.id
    ]
    key_name = var.key_name
    subnet_id = aws_subnet.private_subnet.id
    availability_zone = var.availability_zone
    private_ip = var.wazuh_manager_ip
    iam_instance_profile = aws_iam_instance_profile.ssm_instance_profile.name

    root_block_device {
    volume_size           = 30    
    volume_type           = "gp3"
    delete_on_termination = true 
  }
}

resource "aws_instance" "honeypot" {
    ami = data.aws_ami.latest_honeypot_image.id
    instance_type = "t3.micro"
    count = 3
    vpc_security_group_ids = [
        aws_security_group.allow_ssh_honeypot.id, 
        aws_security_group.allow_external_icmp.id,
        aws_security_group.allow_inbound_http.id,
        aws_security_group.temporary_allow_Internet.id,
        aws_security_group.wazuh_agent_ports.id
    ]
    key_name = var.key_name
    subnet_id = aws_subnet.public_subnet.id
    availability_zone = var.availability_zone
}


# Outputs

output "honeypot_public_IPs" {
    value = aws_instance.honeypot[*].public_ip
}

output "honeypot_private_IPs" {
    value = aws_instance.honeypot[*].private_ip
}

output "wazuh_public_IP" {
    value = aws_instance.wazuh.public_ip
}

output "wazuh_private_IP" {
    value = aws_instance.wazuh.private_ip
}


output "wazuh_instance_id" {
    value = aws_instance.wazuh.id
}
