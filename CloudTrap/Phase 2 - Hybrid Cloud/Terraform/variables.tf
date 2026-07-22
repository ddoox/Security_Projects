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

variable "region" {
  description = "Region for resources"
  default = "us-east-1"
}

variable "availability_zone" {
  description = "Availability zone for the instances"
  default     = "us-east-1a"
}

variable "ssh_port" {
  description = "Port for SSH access"
  default     = "22"
}

variable "honeypot_ssh_port" {
  description = "Port for SSH access"
  default     = "22222"
}

variable "key_name" {
    description = "Name of the SSH key pair"
    default     = "My_SSH_Pair"
}

variable "honeypot_hostnames" {
  type    = list(string)
  default = ["prod-db-01", "mail-server", "gateway-03", "dev-redis", "prod-db-01", "test-web-01"]
}

variable "honeypot_users" {
  type    = list(string)
  default = ["admin", "root", "kali", "generated_16_char_password", "Passphrase", "admin"]
}

variable "honeypot_passwords" {
  type    = list(string)
  default = ["admin123", "toor", "kali", "N:~$kxU{f1s@)Y.J","stroller_evolution_peroxide_sleek_gambling_clay", "*"]
}