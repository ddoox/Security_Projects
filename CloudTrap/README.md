# [Placeholder_name_todo_later]

Placeholder_name_todo_later is a cybersecurity lab deployed on AWS, designed to capture, log, and analyze real-world cyber threats.

Built entirely with Infrastructure as Code (Terraform), this project provisions a **Cowrie honeypot** to attract malicious actors via SSH/Telnet, and a **Wazuh SIEM** for real-time threat detection and log analysis.

**Architecture Evolution:**
- **Phase 1: Full Cloud Deployment (Current):** Both the honeypot and the Wazuh SIEM are hosted on AWS. To maintain a strong security posture, the architecture utilizes private AWS VPC networking. All telemetry data flows securely between the honeypot and the SIEM over internal IP addresses, ensuring the Wazuh manager remains completely hidden and protected from the public internet.

- **Phase 2: Hybrid Architecture (Planned):** The Wazuh manager will be migrated to home server. To secure rest of the network I plan to use KVM on my home server and WireGuard VPN tunnel to securely route logs from AWS honeypot to the local network - nice to learn and interesting use case of hybrid cloud.


**Key features:**
- Automated cloud provisioning using Terraform.
- Interactive SSH honeypot to capture brute-force attacks and malicious payloads.
- Centralized SIEM logging and custom detection rules.
- Secure, isolated networking with planned hybrid VPN integration.