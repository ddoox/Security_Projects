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

variable "wazuh_manager_ip" {
    description = "IP address of the Wazuh manager"
    type        = string
}

variable "honeypot_ip" {
    description = "IP address of the honeypot"
    type        = string
}