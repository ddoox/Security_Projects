resource "aws_instance" "wazuh" {
  ami           = data.aws_ami.latest_wazuh_image.id
  instance_type = "m7i-flex.large"
  vpc_security_group_ids = [
    aws_security_group.wazuh_manager_ports.id,
    aws_security_group.ec2_ssm_outbound.id
  ]
  subnet_id            = aws_subnet.private_subnet.id
  availability_zone    = var.availability_zone
  private_ip           = var.wazuh_manager_ip
  iam_instance_profile = aws_iam_instance_profile.ssm_instance_profile.name

  root_block_device {
    volume_size           = 30
    volume_type           = "gp3"
    delete_on_termination = true
  }
}

resource "aws_instance" "honeypot" {
  ami           = data.aws_ami.latest_honeypot_image.id
  instance_type = "t3.micro"
  count         = 3
  vpc_security_group_ids = [
    aws_security_group.allow_ssh_honeypot.id,
    aws_security_group.allow_external_icmp.id,
    aws_security_group.allow_egress_internet.id,
    aws_security_group.wazuh_agent_ports.id
  ]
  key_name          = var.key_name
  subnet_id         = aws_subnet.public_subnet.id
  availability_zone = var.availability_zone
}
