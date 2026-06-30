# 📓 Project Progress Log

This document serves as a chronological record of the development process, milestones achieved, and technical challenges resolved during the creation of this project.



---

### Terraform Introduction and AWS Setup
* **Week:** Week 1
* **Status:** In Progress

**🎯 Objectives:**
* Learn Terraform Basics
* Write environment setup in Terraform - EC2, VPC, Security Groups, Internet Gateway, Elastic IP

**✅ Accomplishments:**
* Basics of Terraform - 2 EC2s deployed via IaC
* Packer - vendor independent(HashiCorp) tool for building AMI Images
* Wazuh Manager + Agent deployment and connection

**🐛 Challenges & Troubleshooting:**
* *Issue:* Saving AMI state with minimizing cloud costs - Stopping EC2 between sessions will generate costs(EIP, EBS), but configuring everything every time from scratch will drive me crazy  
* *Solution / Workaround:* Create custom AMI or search for automated solution -> HashiCorp Packer vs EC2 Image Builder -> Packer as vendor independent solution

* *Issue:* How to connect to Wazuh in the Cloud Native phase?
* *Solution / Workaround:* Easiest way - traffic through Internet via forwarded port, also most insecure(Wazuh instance will have to be public available) -> SSH port forwarding, better security, especially with Security Group restricting access only to my home IP, a bit more tricky -> https://aws.amazon.com/blogs/aws/new-port-forwarding-using-aws-system-manager-sessions-manager/ - harder to configure but even more secure method


1st bigger success - Wazuh Server/indexer/dashboard connected with agent, both on EC2s, manager accessed via SSH tunneling port 
![[Wazuh_dashboard_after_installation.png]]