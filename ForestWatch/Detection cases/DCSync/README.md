# DCSync (T1003.006)

## Summary

Detection of DCSync — credential replication from a Domain Controller — based on Windows Event 4662 forwarded to Wazuh. The primary rule matches the DS-Replication-Get-Changes-All extended right (1131f6ad-9c07-11d1-f79f-00c04fc2dcd2), which is the property that actually allows access to password hashes. A second, lower-severity rule covers the remaining replication properties as complementary information.

All values below come from a disposable lab domain (`ad.lab`) that no longer exists.

## Attack execution

By default, regular users do not have sufficient permissions to replicate the Domain Controller.

![](../../Images/Pasted%20image%2020260718155254.png)


After the replication permission was granted to a regular user, the account gained the privileges required to perform DCSync successfully.

![](../../Images/Pasted%20image%2020260718155349.png)


## Telemetry

A baseline check was performed first, to confirm that events were being collected correctly.

![](../../Images/Pasted%20image%2020260718145611.png)

No alerts for event 4662 were generated in Wazuh, so the next step was to inspect the Event Viewer on the AD DC.

![](../../Images/Pasted%20image%2020260718150040.png)


The event containing the GUID for DS-Replication-Get-Changes-All — shown in the Windows description as 1131f6ad-9c07-11d1-f79f-00c04fc2dcd2 — is present in the Event Viewer.

![](../../Images/Pasted%20image%2020260718150456.png)


Based on the Kerberoasting case, the next step was not to debug every stage of the communication chain, but to first look for rules that keep the dashboard free of noise (level=0 — no alert generated).

![](../../Images/Pasted%20image%2020260718151424.png)

## Detection rule

```
  
    <!-- Rule 8: Detect DCSync -->
  <rule id="100501" level="14">
    <if_sid>60103</if_sid>
    <field name="win.system.eventID">^4662$</field>
    <field name="win.eventdata.accessMask">0x100</field>
    <field name="win.eventdata.properties" type="pcre2">1131f6ad-9c07-11d1-f79f-00c04fc2dcd2</field>
    <field name="win.eventdata.subjectUserName" negate="yes" type="pcre2">\$$|^MSOL_</field>
    <description>Possible DCSync: Event 4662 with DS-Replication-Get-Changes-All detected from user $(win.eventdata.subjectUserName)</description>
    <mitre>
      <id>T1003.006</id>
    </mitre>
  </rule>
  
    <!-- Rule 9: Detect Replication without Get-Changes-All -->
  <rule id="100502" level="8">
    <if_sid>60103</if_sid>
    <field name="win.system.eventID">^4662$</field>
    <field name="win.eventdata.properties" type="pcre2">1131f6aa-9c07-11d1-f79f-00c04fc2dcd2|89e95b76-444d-4c62-991a-0facbeda640c</field>
    <field name="win.eventdata.properties" negate="yes" type="pcre2">1131f6ad-9c07-11d1-f79f-00c04fc2dcd2</field>
    <field name="win.eventdata.subjectUserName" negate="yes" type="pcre2">\$$|^MSOL_</field>
    <description>Possible DCSync: Event 4662 without DS-Replication-Get-Changes-All detected from user $(win.eventdata.subjectUserName)</description>
    <mitre>
      <id>T1003.006</id>
    </mitre>
  </rule>
  

```

## Tuning & false positives

The properties 1131f6aa-9c07-11d1-f79f-00c04fc2dcd2 and 89e95b76-444d-4c62-991a-0facbeda640c also suggest DCSync, and were initially added to a single rule covering all GUIDs.

![](../../Images/Pasted%20image%2020260718161203.png)


They were ultimately excluded from the primary rule, because only DS-Replication-Get-Changes-All actually allows access to password hashes. A separate rule with a lower level was created to provide complementary information.

![](../../Images/Pasted%20image%2020260718161312.png)


![](../../Images/Pasted%20image%2020260718161344.png)

After final research, both rules were modified to exclude accounts matching ^MSOL_, which are used by Azure AD Connect.

## Lessons learned

When filtering, it is better not to use a "between" range with equal boundaries: a start range of 14 and an end range of 14 returned empty results.

![](../../Images/Pasted%20image%2020260718152328.png)


Using the "is" operator for the same value displays the alert correctly.

![](../../Images/Pasted%20image%2020260718152450.png)

## Limitations

There are no MSOL_ accounts in the lab, so the Azure AD Connect exclusion is untested; it is included to cover hybrid cloud deployments where such accounts can exist.
