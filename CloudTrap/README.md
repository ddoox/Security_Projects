# CloudTrap

CloudTrap is a cybersecurity lab deployed on AWS, designed to capture, log, and analyze real-world cyber threats.

Built entirely with Infrastructure as Code (Terraform), this project provisions a **Cowrie honeypot** to attract malicious actors via SSH/Telnet, and a **Wazuh SIEM** for real-time threat detection and log analysis.

**Architecture Evolution:**
- **Phase 1: Full Cloud Deployment (Done):** Both the honeypot and the Wazuh SIEM are hosted on AWS. To maintain a strong security posture, the architecture utilizes private AWS VPC networking. All telemetry data flows securely between the honeypot and the SIEM over internal IP addresses, ensuring the Wazuh manager remains completely hidden and protected from the public internet.

- **Phase 2: Hybrid Architecture (Done):** The Wazuh manager is migrated to a home server on a KVM instance. Honeypots use Tailscale to send logs from AWS to the home network over a WireGuard VPN connection.

**Key features:**
- Automated cloud provisioning using Terraform.
- Interactive SSH honeypot to capture brute-force attacks and malicious payloads.
- Centralized SIEM logging and custom detection rules.
- Secure, isolated networking with planned hybrid VPN integration.


Architectonic decisions made during projects:
- Connection to Wazuh in Cloud Native phase via AWS Session Manager Port Forwarding - instances don't need a public open port or public IP