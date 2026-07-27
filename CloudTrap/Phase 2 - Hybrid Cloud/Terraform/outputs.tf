output "honeypot_public_IPs" {
  value = aws_instance.honeypot[*].public_ip
}

output "honeypot_private_IPs" {
  value = aws_instance.honeypot[*].private_ip
}
