# 📓 Project Progress Log

This document serves as a record of the development process, milestones achieved, and technical challenges resolved during the creation of this project.



---

### Goal
* **Week:** 1
* **Status:** In Progress

**🎯 Objectives:**
* Install Win Server + Clients and configure AD Domain.
* Configure Tailscale + Wazuh agents
* 

**✅ Accomplishments:**
* 
* 

**🐛 Decisions and Issues:**
* *Issue:* I couldn't generate a lot of smb failed attempts
* *Solution:* There is enabled by default SMB Authentication Rate Limiter on Windows Server 2025 - switching to LDAP instead worked

* * *Issue:* I couldn't create lsass.exe process rule
* *Solution:* Mimikatz is not working on default Win 2025 installation -> Used procdump -> Reconfigured sysmon to log Event 10 when TargetImage=lsass.exe -> 



Using an old laptop with 32GB RAM + Cockpit to host Windows Server Desktop be like:  
![[Pasted image 20260709164045.png]]
- - -


![[Pasted image 20260709174057.png]]

![[Pasted image 20260709180728.png]]


![[Pasted image 20260711145549.png]]