data "aws_ami" "latest_honeypot_image" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "name"
    values = ["honeypot-*"]
  }
}

data "aws_ami" "latest_wazuh_image" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "name"
    values = ["wazuh-server-*"]
  }
}
