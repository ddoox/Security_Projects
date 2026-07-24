# ForestWatch

ForestWatch is a Windows Active Directory detection engineering lab, designed to simulate common AD attacks and build custom SIEM detections around them.

Built on a Windows Server 2025 domain with joined clients, this project uses **Sysmon** for endpoint telemetry and a **Wazuh SIEM** for centralized log collection, custom rule development, and alerting. Each attack is executed hands-on, then detected, tuned, and mapped to MITRE ATT&CK — with the full debugging journey documented in per-technique case studies.

**Lab Architecture:**
- **Domain Controller:** Windows Server 2025 (ADDC) generating security and directory-service events.
- **Clients:** Domain-joined Windows hosts used to launch attacks and generate authentication traffic.
- **Telemetry:** Sysmon deployed on endpoints for process and handle-access visibility (e.g. Event 10 for `lsass.exe` access).
- **SIEM:** Wazuh manager collecting logs over a Tailscale-connected network, running a custom detection ruleset.

**Detection Cases (implemented):**
- **Fast Password Spraying** — many failed network logons across distinct accounts from one IP `(T1110.003)`, with a follow-up rule flagging a successful logon from the same IP as a compromised account `(T1078)`.
- **Brute Force** — repeated failed logons against a single account from one IP `(T1110.001)`, plus a successful-breach correlation rule `(T1078)`.
- [**LSASS Access / Credential Dumping**](./Detection%20cases/lsass.exe%20access) — detecting high-privilege handle access to `lsass.exe` via Sysmon Event 10, overriding Wazuh's muted default rule and tuning out low-privilege and Wazuh-agent noise `(T1003.001)`.
- [**Kerberoasting**](./Detection%20cases/Kerberoast) — detecting RC4 (`0x17`) TGS requests via Event 4769, including the decoder/logtest troubleshooting that made client-side events visible `(T1558.003)`.
- [**DCSync**](./Detection%20cases/DCSync) — detecting `DS-Replication-Get-Changes-All` via Event 4662 access masks and property GUIDs, with a complementary lower-severity rule for partial replication `(T1003.006)`.
- [**Golden Ticket**](./Detection%20cases/Golden%20Ticket) — a best-effort detection study covering the PAC Requestor enforcement patch (Events 37/38) and the limits of forged-ticket detection on a patched DC `(T1558.001)`.

**Key features:**
- Custom Wazuh detection rules mapped to MITRE ATT&CK techniques.
- Multi-stage correlation (attack attempt → successful compromise) for spraying and brute force.
- Endpoint visibility with Sysmon, including credential-access detection.
- Documented detection-engineering process: attack execution, tuning, false-positive suppression, and lessons learned.

The complete custom ruleset lives in [`AD_Lab_rules.md`](./AD_Lab_rules.md). Development notes and challenges are tracked in [`Progress_Log.md`](./Progress_Log.md).

**Roadmap:**
- Lateral Movement detection.
- GPO Abuse detection.
- Expanding toward full Cyber Kill Chain coverage.
