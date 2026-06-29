packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.8"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

variable "wazuh_manager_ip" {
  type    = string
  default = env("TF_VAR_wazuh_manager_ip")
}

source "amazon-ebs" "wazuh" {
  ami_name      = "wazuh-server-{{timestamp}}"
  instance_type = "m7i-flex.large"
  region        = "us-east-1"
  
  source_ami_filter {
    filters = {
      name                = "al2023-ami-2023.*-x86_64"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
      architecture         = "x86_64"
    }
    most_recent = true
    owners      = ["amazon"] # Official Amazon account ID
  }
  ssh_username = "ec2-user"
}

source "amazon-ebs" "honeypot" {
  ami_name      = "honeypot-{{timestamp}}"
  instance_type = "t3.micro"
  region        = "us-east-1"
  
  source_ami_filter {
    filters = {
      name                = "al2023-ami-2023.*-x86_64"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
      architecture         = "x86_64"
    }
    most_recent = true
    owners      = ["amazon"] # Official Amazon account ID
  }
  ssh_username = "ec2-user"
}

build {
  name = "wazuh-server"
  sources = [
    "source.amazon-ebs.wazuh",
    "source.amazon-ebs.honeypot"
  ]

  # Common provisioner for both Wazuh and Honeypot instances
  provisioner "shell" {
    environment_vars = [
      "WAZUH_MANAGER=${var.wazuh_manager_ip}"
    ]
    inline = [
      "sudo dnf update -y",
    ]
  }
  
  # Provisioner for Wazuh instance
  provisioner "shell" {
    only = ["amazon-ebs.wazuh"]
    environment_vars = [
      "WAZUH_MANAGER=${var.wazuh_manager_ip}"
    ]
    inline = [
      "echo 'Provisioning Wazuh instance'"
    ]
  }
  
  # Provisioner for Honeypot instance
  provisioner "shell" {
    only = ["amazon-ebs.honeypot"]
    environment_vars = [
      "WAZUH_MANAGER=${var.wazuh_manager_ip}"
    ]
    inline = [
      "sudo rpm --import https://packages.wazuh.com/key/GPG-KEY-WAZUH",
      "echo -e '[wazuh]\ngpgcheck=1\ngpgkey=https://packages.wazuh.com/key/GPG-KEY-WAZUH\nenabled=1\nname=EL-$releasever - Wazuh\nbaseurl=https://packages.wazuh.com/4.x/yum/\npriority=1' | sudo tee /etc/yum.repos.d/wazuh.repo",
      "sudo WAZUH_MANAGER=\"$WAZUH_MANAGER\" dnf install wazuh-agent -y",
      "sudo systemctl daemon-reload",
      "sudo systemctl enable wazuh-agent"
    ]
  }

}