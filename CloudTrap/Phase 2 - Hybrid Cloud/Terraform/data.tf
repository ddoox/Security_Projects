data "aws_ami" "latest_honeypot_image" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "name"
    values = ["honeypot-*"]
  }
}
