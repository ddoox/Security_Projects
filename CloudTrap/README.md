# CloudTrap

CloudTrap is a cybersecurity lab deployed on AWS, designed to capture, log, and analyze real-world cyber threats.

Built entirely with Infrastructure as Code (Terraform), this project provisions a Cowrie honeypot to attract malicious actors via SSH/Telnet, and a Wazuh SIEM for real-time threat detection and log analysis.

**Architecture Evolution:**
- **Phase 1: Full Cloud Deployment (Done):** Both the honeypot and the Wazuh SIEM are hosted on AWS. To maintain a strong security posture, the architecture utilizes private AWS VPC networking. All telemetry data flows securely between the honeypot and the SIEM over internal IP addresses, ensuring the Wazuh manager remains completely hidden and protected from the public internet.

- **Phase 2: Hybrid Architecture (Done):** The Wazuh manager is migrated to a home server on a KVM instance. Honeypots use Tailscale to send logs from AWS to the home network over a WireGuard VPN connection.

**Key features:**
- Automated cloud provisioning using Terraform.
- Interactive SSH honeypot to capture brute-force attacks and malicious payloads.
- Centralized SIEM logging and custom detection rules.
- Secure, isolated networking with hybrid VPN integration.

The lab ran exposed to the public internet. Real brute-force traffic, a
successful login and a dropped crypto-miner payload are documented in
[**FINDINGS.md**](./FINDINGS.md)

## Architectural decisions

### Accessing Wazuh in the cloud-native phase — AWS Session Manager Port Forwarding

Three options were on the table. Exposing the dashboard over the internet was the easiest and the worst: the Wazuh instance would need to be publicly reachable. SSH port forwarding was better, especially with a Security Group restricting access to a single home IP, but still required an open port. The chosen approach was [Session Manager port forwarding](https://aws.amazon.com/blogs/aws/new-port-forwarding-using-aws-system-manager-sessions-manager/) — harder to set up (VPC endpoints, an EC2 IAM role, the SSM plugin) but the instance needs neither a public IP nor an open inbound port.

### Preserving machine state without paying for idle infrastructure — HashiCorp Packer

Stopping EC2 instances between sessions still bills for EC2, Elastic IPs and EBS, but rebuilding everything by hand each time was not sustainable either. The answer was to create custom AMIs. Packer won over EC2 Image Builder because it is vendor-independent. 

### Log transport from AWS to the home lab — Tailscale

Once the Wazuh Manager moved to a home server, agents in AWS needed a way to reach it without exposing that server to the public internet. Four options were compared:

- **"Clean" WireGuard** — closest to the ICT approach I like, but it would need a dedicated EC2 gateway plus an Elastic IP. My ISP gives me no static address and the home server sits behind a VPN that rotates IPs. Routing would be manageable, but the standing cost of an always-on gateway was not convincing enough for me + tearing it down would mean re-configuring agents and home configs every time.
- **SSM tunneling** — works well for reaching Wazuh on EC2, but it is not a tool for shipping large volumes of logs, and the tunnel direction would have to be reversed.
- **Cloudflare Tunnel** — the cloudflared daemon model is appealing (no public IP needed), but it is designed primarily for HTTP/S. Usable for other TCP traffic, though not the best fit here.
- **Tailscale** — ACLs, plus ephemeral auth keys that suit Terraform and Packer perfectly: the goal is to declare a number of instances in Terraform and see them register with the Manager moments later. And as bonus - data plane is done via WireGuard.

