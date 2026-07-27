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

variable "private_subnet_cidr" {
  description = "CIDR block for the private subnet"
  default     = "10.0.1.0/24"
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
  description = "IP address of the Wazuh manager"
  type        = string
}
