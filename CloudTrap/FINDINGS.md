# 🔎 CloudTrap — Findings

A chronological account of what the Cowrie honeypot actually collected. Basic Cowrie rules - [`cowrie_rules.xml`](./cowrie_rules.xml).

## Phase 1 — Full Cloud (Wazuh + Cowrie on EC2)

Wazuh Manager and the Cowrie honeypot ran on separate EC2 instances inside the same VPC. Telemetry flowed over private addresses only, and the dashboard was never exposed to the public internet.

### 30 June 2026 — first working stack

Wazuh server, indexer and dashboard came up with one agent attached, reachable through an SSH forwarded port. 

Wazuh dashboard after installation

![Wazuh_Dashboard](Images/Wazuh_dashboard_after_installation.png)

The manager instance was confirmed to have no route to the internet 

SSM session and port forwarding against an air-gapped instance

![](Images/Pasted%20image%2020260702170740.png)

### 2 July 2026 — first full day of traffic

Entries from 17:35 were still configuration checks. Real brute force traffic started at 19:18. 

MITRE ATT&CK dashboard for the first attack window

![](Images/Pasted%20image%2020260702201418.png)

Raw failed-login events from a five-minute window

![](Images/Pasted%20image%2020260702201554.png)

Two of the attacking addresses were checked against external sources. VirusTotal flagged 91.92.40.35 as malicious by 10 out of 91 vendors, with a community score of −4. AbuseIPDB showed 192.3.1.46 with 362 reports from 191 distinct sources, first seen 25 April 2026 and most recently two hours before the screenshot, all in the Brute-Force and SSH categories.
VirusTotal and AbuseIPDB lookups for two attacking addresses

![](Images/Pasted%20image%2020260702202207.png)

After that the count of instances was increased in Terraform, which after executing spawned extra EC2s.

![](Images/Pasted%20image%2020260702205900.png)

### 3 July 2026

The next day brought the first high severity and critical alert.

![](Images/Pasted%20image%2020260703171321.png)


At 16:40:08 an attacker from 129.45.84.205 logged in successfully as root/root.

![](Images/Pasted%20image%2020260703171404.png)

Two minutes later, at 16:42:32, the same session executed a payload.

```
chmod +x ./.7616826122278932283/sshd; nohup ./.7616826122278932283/sshd 211.90.219.149 103.186.97.118 160.191.89.7 43.226.36.171 42.4.62.108 185.27.121.34 183.224.79.111 103.61.122.197 159.203.108.2 161.129.211.56 23.251.57.59 203.186.60.250 148.72.168.29 143.198.24.202 159.203.120.106 121.228.250.70 103.210.22.17 43.226.44.17 178.105.116.233 123.58.212.100 65.181.92.228 101.36.228.201 122.228.86.100 45.118.144.36 106.13.167.239 43.226.45.124 203.189.196.168 103.121.91.144 202.129.205.122 183.56.198.150 51.15.19.10 118.122.147.195 36.163.199.22 60.165.124.241 88.151.34.218 125.39.148.118 106.12.145.153 183.136.170.167 171.80.9.148 114.218.57.21 59.110.83.71 45.8.133.228 188.166.211.175 160.250.133.79 123.182.141.59 106.13.209.152 143.198.27.218 185.148.3.161 177.136.246.131 141.148.140.182 113.56.35.44 &
```

![](Images/Pasted%20image%2020260703171421.png)


The dropped file was hashed on the honeypot by cowrie itself:

```
94f2e4d8d4436874785cd14e6e6d403507b8750852f7f2040352069a75da4c00
```

Just to be sure sha256sum was calculated of the dropped binary

![](Images/Pasted%20image%2020260703171210.png)

Hybrid Analysis report for the dropped binary

![](Images/Pasted%20image%2020260703172224.png)

### 4 July 2026 

Critical alerts jumped from 1 to 21 in a day.

![](Images/Pasted%20image%2020260704164117.png)

Four behaviours stand out:

- System reconnaissance — uname -a, uname -s -v -n -r -m, cat /proc/cpuinfo, ifconfig, echo Hi | cat -n
- Checking for miners — ps | grep '[Mm]iner' and ps -ef | grep '[Mm]iner'
- Services stealing  — locate D877F783D5D3EF8Cs (Telegram Session) and a single ls -la across TelegramDesktop/tdata paths, /dev/ttyGSM\*, /dev/ttyUSB-mod\*, /var/spool/sms/\*, /var/log/smsd.log, /etc/smsd.conf, /usr/bin/qmuxd, /var/qmux_connect_socket, /etc/config/simman, /dev/modem\* and /var/config/sms/\* 

Exported command input events

![](Images/Pasted%20image%2020260704164454.png)

---

## Phase 2 — Hybrid Cloud (Wazuh at home, honeypots in AWS over Tailscale)

The manager moved to a KVM guest on a home server to cut AWS cost. Honeypots reach it over Tailscale.

### 5 July 2026

A single terraform apply created ten honeypot instances.

Terraform apply output

![](Images/Pasted%20image%2020260705164345.png)

All ten instances registered with Tailscale as ephemeral nodes alongside the wazuh node.

![](Images/Pasted%20image%2020260705163905.png)

The same fleet appeared in Wazuh as ten active agents. Their reported IP addresses are the 100.x Tailscale addresses, confirming that logs travel through the tunnel.

![](Images/Pasted%20image%2020260705163928.png)

### 11 July 2026 

A custom Cowrie dashboard over the full dataset gives the shape of the campaign.
![](Images/Pasted%20image%2020260716190606.png)

---

## Malware samples collected

| Phase | SHA-256 | Links |
|---|---|---|
| Phase 1 (and again in Phase 2) | 94f2e4d8d4436874785cd14e6e6d403507b8750852f7f2040352069a75da4c00 | [VirusTotal](https://www.virustotal.com/gui/file/94f2e4d8d4436874785cd14e6e6d403507b8750852f7f2040352069a75da4c00) · [Hybrid Analysis](https://hybrid-analysis.com/sample/94f2e4d8d4436874785cd14e6e6d403507b8750852f7f2040352069a75da4c00) |
| Phase 2 | a8460f446be540410004b1a8db4083773fa46f7fe76fa84219c93daa1669f8f2 | [VirusTotal](https://www.virustotal.com/gui/file/a8460f446be540410004b1a8db4083773fa46f7fe76fa84219c93daa1669f8f2) |
| Phase 2 | 9e5b93d3095f577136717e6aae8b51fea50d66ef9123eedccfc23b8faebf6d6c | [VirusTotal](https://www.virustotal.com/gui/file/9e5b93d3095f577136717e6aae8b51fea50d66ef9123eedccfc23b8faebf6d6c) |

All three are pending analysis in the Malware Analysis Lab that is planned.