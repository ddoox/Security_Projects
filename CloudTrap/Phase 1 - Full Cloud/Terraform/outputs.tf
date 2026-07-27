output "honeypot_public_IPs" {
  value = aws_instance.honeypot[*].public_ip
}

output "honeypot_private_IPs" {
  value = aws_instance.honeypot[*].private_ip
}

output "wazuh_public_IP" {
  value = aws_instance.wazuh.public_ip # As Wazuh is configured to not have a public IP, this should return nothing
}

output "wazuh_private_IP" {
  value = aws_instance.wazuh.private_ip
}

output "wazuh_instance_id" {
  value = aws_instance.wazuh.id
}
