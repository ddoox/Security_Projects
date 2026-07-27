# Instances

resource "aws_instance" "honeypot" {
  ami           = data.aws_ami.latest_honeypot_image.id
  instance_type = "t3.micro"
  count         = 5
  vpc_security_group_ids = [
    aws_security_group.allow_ssh_honeypot.id,
    aws_security_group.wazuh_agent_ports.id,
    aws_security_group.allow_egress_internet.id,
    aws_security_group.tailscale_p2p.id
  ]
  key_name          = var.key_name
  subnet_id         = aws_subnet.public_subnet.id
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
