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

  # Fail the build if the variable is empty
  validation {
    condition     = length(var.wazuh_manager_ip) > 0
    error_message = "TF_VAR_wazuh_manager_ip is not set. Run ./scripts/build_and_deploy.sh, or export it before calling packer build."
  }
}

variable "region" {
  type    = string
  default = "us-east-1"
}

source "amazon-ebs" "wazuh" {
  ami_name      = "wazuh-server-{{timestamp}}"
  instance_type = "m7i-flex.large"
  region        = var.region
  
  source_ami_filter {
    filters = {
      name                = "al2023-ami-2023.*-x86_64"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
      architecture         = "x86_64"
    }
    most_recent = true
    owners      = ["amazon"]
  }

  launch_block_device_mappings {
    device_name           = "/dev/xvda"
    volume_size           = 30
    volume_type           = "gp3"
    delete_on_termination = true
  }

  ssh_username = "ec2-user"
}

source "amazon-ebs" "honeypot" {
  ami_name      = "honeypot-{{timestamp}}"
  instance_type = "t3.micro"
  region        = var.region
  
  source_ami_filter {
    filters = {
      name                = "al2023-ami-2023.*-x86_64"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
      architecture         = "x86_64"
    }
    most_recent = true
    owners      = ["amazon"]
  }
  ssh_username = "ec2-user"
}

build {
  name = "wazuh-project"
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
      "curl -sO https://packages.wazuh.com/4.14/wazuh-install.sh",
      "sudo bash ./wazuh-install.sh -a",
      "sudo sed -i 's/^enabled=1/enabled=0/' /etc/yum.repos.d/wazuh.repo",
      "sudo tar -xvf wazuh-install-files.tar wazuh-install-files/wazuh-passwords.txt",
      "sudo mv wazuh-install-files/wazuh-passwords.txt /root/wazuh-passwords.txt",
      "sudo chmod 600 /root/wazuh-passwords.txt",
      "sudo rm -rf wazuh-install.sh wazuh-install-files.tar wazuh-install-files"
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
      "sudo WAZUH_MANAGER=\"$WAZUH_MANAGER\" dnf install 'wazuh-agent-4.14.*' -y",
      "sudo systemctl enable wazuh-agent",
      "sudo sed -i 's/^enabled=1/enabled=0/' /etc/yum.repos.d/wazuh.repo",
      
      "sudo sed -i 's/#Port 22/Port 22222/' /etc/ssh/sshd_config",
      "sudo systemctl enable sshd",
      
      "sudo dnf install python3.11 -y",
      "sudo mkdir -p /opt/cowrie",
      "sudo chown ec2-user:ec2-user /opt/cowrie",
      "python3.11 -m venv /opt/cowrie/cowrie-env",
      "/opt/cowrie/cowrie-env/bin/pip install --upgrade pip",
      "/opt/cowrie/cowrie-env/bin/pip install cowrie",
      "cd /opt/cowrie && /opt/cowrie/cowrie-env/bin/cowrie init",

      "echo -e '[Unit]\nDescription=Cowrie Honeypot\nAfter=network.target\n\n[Service]\nType=forking\nUser=ec2-user\nGroup=ec2-user\nWorkingDirectory=/opt/cowrie\nEnvironment=PATH=/opt/cowrie/cowrie-env/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin\nExecStart=/opt/cowrie/cowrie-env/bin/cowrie start\nRestart=on-failure\n\n[Install]\nWantedBy=multi-user.target' | sudo tee /etc/systemd/system/cowrie.service",
      "sudo systemctl enable cowrie",
      
      "echo -e '<ossec_config>\\n  <localfile>\\n    <log_format>json</log_format>\\n    <location>/opt/cowrie/var/log/cowrie/cowrie.json</location>\\n  </localfile>\\n</ossec_config>' | sudo tee -a /var/ossec/etc/ossec.conf",


      "sudo dnf install nftables -y",
      "sudo tee /etc/sysconfig/nftables.conf > /dev/null <<'EOF'\nflush ruleset\n\ntable ip nat {\n  chain prerouting {\n    type nat hook prerouting priority 0; policy accept;\n    tcp dport 22 redirect to :2222\n  }\n}\nEOF",
      "sudo nft -c -f /etc/sysconfig/nftables.conf",
      "sudo systemctl enable nftables"
    ]
  }

}
