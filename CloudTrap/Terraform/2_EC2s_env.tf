
provider "aws" {
  region = "us-east-1"
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

# resource "aws_route_table" "private_route_table" {
#     vpc_id = aws_vpc.honeypot_vpc.id
# }

# Temporary NAT Gateway for private subnet access to the Internet
# resource "aws_eip" "nat_eip" {
#   domain = "vpc"
# }

# resource "aws_nat_gateway" "honeypot_nat" {
#     allocation_id = aws_eip.nat_eip.id
#     subnet_id     = aws_subnet.public_subnet.id
# }

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

resource "aws_instance" "wazuh" {
    # ami           = "ami-08f44e8eca9095668"
    ami = data.aws_ami.latest_wazuh_image.id
    instance_type = "m7i-flex.large"
    vpc_security_group_ids = [
        aws_security_group.allow_ssh_wazuh.id,
        aws_security_group.temporary_allow_Internet.id,
        aws_security_group.allow_inbound_http.id,
        aws_security_group.wazuh_manager_ports.id
    ]
    key_name = var.key_name
    subnet_id = aws_subnet.private_subnet.id
    availability_zone = var.availability_zone
    private_ip = var.wazuh_manager_ip

    root_block_device {
    volume_size           = 30    # Rozmiar dysku w gigabajtach (GB)
    volume_type           = "gp3" # Nowszy, bardziej wydajny i tańszy standard niż gp2
    delete_on_termination = true  # Dysk zostanie usunięty przy niszczeniu instancji
  }
}

resource "aws_instance" "honeypot" {
    # ami           = "ami-08f44e8eca9095668"
    ami = data.aws_ami.latest_honeypot_image.id
    instance_type = "t3.micro"
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
    private_ip = var.honeypot_ip
}


# Outputs

output "honeypot_public_IP" {
    value = aws_instance.honeypot.public_ip
}

output "honeypot_private_IP" {
    value = aws_instance.honeypot.private_ip
}

output "wazuh_public_IP" {
    value = aws_instance.wazuh.public_ip
}

output "wazuh_private_IP" {
    value = aws_instance.wazuh.private_ip
}
