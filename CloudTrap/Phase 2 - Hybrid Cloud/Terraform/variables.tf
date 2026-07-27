variable "region" {
  description = "Region for resources"
  default     = "us-east-1"
}

variable "availability_zone" {
  description = "Availability zone for the instances"
  default     = "us-east-1a"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  default     = "10.0.2.0/24"
}

variable "ssh_port" {
  description = "Port for bait SSH access"
  default     = "22"
}

variable "honeypot_true_ssh_port" {
  description = "Port for true SSH access"
  default     = "22222"
}

variable "key_name" {
  description = "Name of the SSH key pair"
  default     = "My_SSH_Pair" # Replace with your own key pair name
}

variable "wazuh_manager_ip" {
  description = "Tailnet IP address of the Wazuh manager"
  default     = "100.73.81.69" # Replace with your own Wazuh tailnet IP
}

variable "honeypot_hostnames" {
  type    = list(string)
  default = ["prod-db-01", "mail-server", "gateway-03", "dev-redis", "prod-db-02", "test-web-01"]
}

variable "honeypot_users" {
  type    = list(string)
  default = ["admin", "root", "kali", "root", "root", "admin"]
}

variable "honeypot_passwords" {
  type    = list(string)
  default = ["admin123", "toor", "kali", "N:~@kxU{f1s@)Y.J", "stroller_evolution_peroxide_sleek_gambling_clay", "*"]
}

variable "tailscale_authkey" {
  type      = string
  sensitive = true
}
