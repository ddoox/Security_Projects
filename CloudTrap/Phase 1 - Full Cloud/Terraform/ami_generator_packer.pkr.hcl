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

  launch_block_device_mappings {
    device_name           = "/dev/xvda" # Domyślna nazwa dla Amazon Linux 2023
    volume_size           = 30          # Zwiększ na minimum 30-50 GB
    volume_type           = "gp3"
    delete_on_termination = true
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
      // "sudo systemctl enable wazuh-indexer wazuh-manager filebeat wazuh-dashboard",      
      // "sudo mkdir -p /etc/systemd/system/wazuh-dashboard.service.d /etc/systemd/system/filebeat.service.d",
      // "printf '[Unit]\\nAfter=wazuh-indexer.service\\nWants=wazuh-indexer.service\\n' | sudo tee /etc/systemd/system/wazuh-dashboard.service.d/wait-indexer.conf",
      // "printf '[Unit]\\nAfter=wazuh-indexer.service\\nWants=wazuh-indexer.service\\n' | sudo tee /etc/systemd/system/filebeat.service.d/wait-indexer.conf",
      // "sudo systemctl daemon-reload"
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
      "sudo systemctl enable wazuh-agent",
      
      "sudo sed -i 's/#Port 22/Port 22222/' /etc/ssh/sshd_config",
      "sudo systemctl enable sshd",
      
      "sudo dnf install python3.11 -y",
      "sudo mkdir -p /opt/cowrie",
      "sudo chown ec2-user:ec2-user /opt/cowrie",
      "python3.11 -m venv /opt/cowrie/cowrie-env",
      "/opt/cowrie/cowrie-env/bin/pip install --upgrade pip",
      "/opt/cowrie/cowrie-env/bin/pip install cowrie",
      "cd /opt/cowrie && /opt/cowrie/cowrie-env/bin/cowrie init",

      "echo -e '[Unit]\nDescription=Cowrie Honeypot\nAfter=network.target\n\n[Service]\nType=simple\nUser=ec2-user\nGroup=ec2-user\nWorkingDirectory=/opt/cowrie\nEnvironment=PATH=/opt/cowrie/cowrie-env/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin\nExecStart=/opt/cowrie/cowrie-env/bin/cowrie start\nRestart=on-failure\n\n[Install]\nWantedBy=multi-user.target' | sudo tee /etc/systemd/system/cowrie.service",
      "sudo systemctl enable cowrie",
      
      "sudo dnf install nftables -y",
      "sudo systemctl enable nftables",
      "sudo nft add table ip nat",
      "sudo nft add chain ip nat prerouting { type nat hook prerouting priority 0 \\; }",
      "sudo nft add rule ip nat prerouting tcp dport 22 redirect to 2222",
      "sudo sh -c 'nft list ruleset > /etc/sysconfig/nftables.conf'"    ]
  }

}