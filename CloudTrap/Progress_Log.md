# 📓 Project Progress Log

This document serves as a record of the development process, milestones achieved, and technical challenges resolved during the creation of this project.



### Phase 2 Completed - Break for AD project - Phase 3 & 4 TBD after AD




### Move Wazuh Manager to home environment
* **Week:** 2
* **Status:** Done

**🎯 Objectives:**
* Move Wazuh Manager KVM on home server for AWS Cost reduction
* Create Tailscale connection between AWS and home lab

**✅ Accomplishments:**
* Fully automated honeypots deployment with Tailscale connectivity via IaC

**🐛 Decisions:**
* *Issue:* Secure Networking - I have to find a way for agents to communicate with Wazuh without excessive exposure of the home server to the public Internet 
* *Solution:* WireGuard Tunnel vs SSM Tunneling vs Cloudflare Tunnel vs Tailscale:
	* Wireguard - Hardcore approach closest to my ICT heart, BUT I would need extra EC2 instance to be gateway + Elastic IP(I don't have static IP from ISP and my home server is always behind VPN which sometimes rotate IP) <-- routing would not be a problem, but it would generate extra cost + I would have to pay for it even when not in use to not "have fun" with reconfiguring agents and home configs
	* SSM Tunneling - Works great for accessing Wazuh on EC2, but it is not tool for sending massive amounts of logs(beside the fact that I would have to search for a ways to reverse the tunnel direction)
	* Cloudflare Tunnel - Sounded interesting, but after research it's not the answer. Interesting part "Instead of exposing a public IP, you install a lightweight daemon called `cloudflared` on your server" - but designed mostly for HTTP/S, can be used for other tcp traffic also, but there is better alternative for my type of project - Tailscale
	* Tailscale - It has ACLs! Who doesn't love(and hate when they are not working) ACLs? Also can use the special auth keys for ephemeral instances - ideal solution for my Terraform + Packer(I hope to reach level when I only specify the number of running instances in Terraform and a few moments later I'll see them active in Manager ) --> Okay, so kinda WireGuard after all: ![[Pasted image 20260703181426.png]]


Example IaC outcome:


![[Pasted image 20260705164345.png]]



![[Pasted image 20260705163905.png]]


![[Pasted image 20260705163928.png]]


![[Pasted image 20260711145701.png]]

---

### Terraform Introduction and AWS Setup
* **Week:** Week 1
* **Status:** Done

**🎯 Objectives:**
* Learn Terraform Basics
* Write environment setup in Terraform - EC2, VPC, Security Groups, Internet Gateway, Elastic IP

**✅ Accomplishments:**
* Basics of Terraform - 2 EC2s deployed via IaC
* Packer - vendor independent(HashiCorp) tool for building AMI Images
* Wazuh Manager + Agent deployment and connection
* Phase 1 done - Wazuh Manager and Cowrie honeypot deployed on EC2s with secure access to Wazuh via AWS Systems Manager
* Observed brute force attacks and analyzed crypto miner dropped on one instance

**🐛 Decisions:**
* *Issue:* Saving AMI state with minimizing cloud costs - Stopping EC2 between sessions will generate costs(EC2, EIP, EBS), but configuring everything every time from scratch will drive me crazy  
* *Solution:* Create custom AMI or search for automated solution -> HashiCorp Packer vs EC2 Image Builder -> Packer as vendor independent solution -> Terraform for whole infrastructure and Packer AMI images for latest builds

* *Issue:* How to connect to Wazuh in the Cloud Native phase?
* *Solution:* Easiest way - access through Internet, also most insecure(Wazuh instance will have to be publicly available) -> SSH port forwarding, better security, especially with Security Group restricting access only to my home IP, a bit more tricky -> https://aws.amazon.com/blogs/aws/new-port-forwarding-using-aws-system-manager-sessions-manager/ - much harder to configure(VPC Endpoint, EC2 role, SSM plugin) but even more secure method - professional approach



1st bigger success - Wazuh Server/indexer/dashboard connected with agent, both on EC2s, manager accessed via SSH forwarded port 

![Wazuh_Dashboard](Wazuh_dashboard_after_installation.png)


Wazuh acces without Internet access
![[Pasted image 20260702170740.png]]


~3h later:
![[Pasted image 20260702201341.png]]


Logs from 17:35 - configuration checks. Real brute force attacks started from 19:18.
![[Pasted image 20260702201418.png]]

![[Pasted image 20260702201554.png]]

Some IPs
![[Pasted image 20260702202207.png]]


Few more hotspots before leaving setup for night:
![[Pasted image 20260702205900.png]]
=======




![[Pasted image 20260703171321.png]]


![[Pasted image 20260703171404.png]]

![[Pasted image 20260703171421.png]]
![[Pasted image 20260703171210.png]]


https://hybrid-analysis.com/sample/94f2e4d8d4436874785cd14e6e6d403507b8750852f7f2040352069a75da4c00


![[Pasted image 20260703172224.png]]


Next day:
![[Pasted image 20260704164117.png]]


![[Pasted image 20260704164454.png]]


![[Pasted image 20260716190606.png]]