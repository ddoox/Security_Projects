# Kerberoasting (T1558.003)

## Summary

Detection of Kerberoasting based on Windows event 4769 (Kerberos service ticket request) with RC4 ticket encryption (0x17). Writing the detection rule itself was easy; getting it to fire in Wazuh was not. Events were generated on the ADDC and reached the Wazuh manager, but no alert was raised. The root cause was a default Wazuh rule that muted the event at level 0.

## Attack execution

After a ticket is requested, it is cached in memory. Use klist purge to delete cached tickets so the rule can be tested again.

## Telemetry

On the first try from the ADDC the activity was caught by Wazuh. From the client side, nothing was raised. Events 4769 with encryption type 0x17 were generated on the ADDC, but were not present in Wazuh.

The first suspected cause was the dual-stack IP address formatting:

![](../../Images/Pasted%20image%2020260715165352.png)


Events from the ADDC and the client are exactly the same — version 2. A tcpdump on the Wazuh manager showed almost identical traffic in the Kerberoasting case.

After enabling Wazuh archives, the log could be seen as generated and sent to the manager, so it had to be dropped later in the pipeline:

![](../../Images/Pasted%20image%2020260716170343.png)

Both logs were compared in Wazuh logtest, but in both cases the result was "no decoder matched".

## Detection rule

The event was muted (level 0) by a default Wazuh rule — see https://groups.google.com/g/wazuh/c/g1EqZ0ssLYU

![](../../Images/Pasted%20image%2020260716174954.png)


After creating a custom rule with if_sid equal to the muted rule, Kerberoasting with RC4 was detected correctly:

![](../../Images/Pasted%20image%2020260716175417.png)


```
  <!-- Rule 7: Detect Kerberos service ticket with RC4-HMAC encryption -->
  <rule id="100401" level="14" ignore="3">
    <if_sid>60106, 92651</if_sid>
    <field name="win.system.eventID">^4769$</field>
    <field name="win.eventdata.ticketEncryptionType">^0x17$</field>
    <description>Possible Kerberoasting: RC4 TGS request detected from $(win.eventdata.ipAddress)</description>
    <mitre>
      <id>T1558.003</id>
    </mitre>
  </rule>

```
## Lessons learned

- Tickets are cached in memory after being requested; purge them with klist purge between test runs.
- A missing alert does not necessarily mean a broken log pipeline. Enabling archives proved the event reached the manager, and the actual cause was a default rule set to level 0.
- Checking existing default rules (and a quick search of the Wazuh community) resolved the issue faster than rebuilding the analysis from scratch.

## Limitations

- Rule only catching RC4 - attacker using AES is not detected.