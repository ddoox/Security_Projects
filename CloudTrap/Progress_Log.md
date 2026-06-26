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
* 
* 

**🐛 Challenges & Troubleshooting:**
* *Issue:* Saving AMI state with minimizing cloud costs - Stopping EC2 between sessions will generate costs(EIP, EBS), but configuring everything every time from scratch will drive me crazy  
* *Solution / Workaround:* Create custom AMI or search for automated solution -> 

**⏭️ Next Steps:**
* 

---

## 📖 Log Entries

### 2026-06-26 - AWS Foundation and IaC Setup
* **Cycle / Week:** Week 1
* **Status:** Completed

**🎯 Objectives:**
* Secure the new AWS account.
* Establish the foundational networking infrastructure using Terraform.

**✅ Accomplishments:**
* Enabled MFA for the root account and configured AWS Budgets with hard limits to control Free Tier usage.
* Created a dedicated IAM user with programmatic access.
* Wrote initial Terraform configuration (`main.tf`, `network.tf`) defining the VPC, public subnet, and Internet Gateway.

**🐛 Challenges & Troubleshooting:**
* *Issue:* Encountered an authentication error when running `terraform init`.
* *Solution / Workaround:* Discovered the local AWS CLI profile was not pointing to the newly generated Access Keys. Resolved by running `aws configure` and applying the correct credentials.

**⏭️ Next Steps:**
* Define Security Groups for Wazuh (TCP/443 restriction) and the Cowrie Honeypot (TCP/22 open).
* Write Terraform resource blocks for both EC2 instances (t3.large and t2.micro) and apply the configuration.