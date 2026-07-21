
I had to overwrite default Wazuh rule 61612 - it's enabled by default with level 0. That means the Wazuh ignore all such events

```
  <rule id="61612" **level="0"**>
    <if_sid>61600</if_sid>
    <field name="win.system.eventID">^10$</field>
    <description>Sysmon - Event 10: $(win.eventdata.targetImage) process accessed by $(win.eventdata.sourceImage)</description>
    <options>no_full_log</options>
    <group>sysmon_event_10,</group>
  </rule>
```

After this dumping lsass.exe was detected successfully, but I had to fine-tune the alert as there was a lot of noise. Looking at Elastic guide I've implemented ignoring attempts with privileges not enough to dump the process(PROCESS_VM_READ - 0x0010)- https://www.elastic.co/guide/en/security/8.19/suspicious-lsass-process-access.html

After this, there were less false positives, but one was still visible - Wazuh agent... Added one extra rule for disabling alert if SourceImage was equal to Wazuh agent path(in real case scenario additional integrity checks should be implemented to check whitelisted processes)

```
    <!-- Rule 5: lsass.exe access -->
  <rule id="100300" level="16" ignore="3">
    <!-- Rule 61612 = Sysmon - Event 10-->
    <if_sid>61612</if_sid>
    <field name="win.eventdata.targetImage" type="pcre2">(?i)lsass</field>
    <field negate="yes" name="win.eventdata.grantedAccess" type="pcre2">0x1000|0x1400|0x101400|0x101000|0x101001|0x100000|0x3200|0x40|0x3000|0x3600</field>
    <description>Sysmon: Potential lsass.exe dump - High privilege access</description>
    <mitre>
      <id>T1003.001</id>
    </mitre>
  </rule>
  
    <!-- Rule 6: Allow Wazuh access lsass.exe without alert -->
  <rule id="100301" level="0" >
    <if_sid>100300</if_sid>
    <field name="win.eventdata.sourceImage" type="pcre2">^(?i)C:\\\\Program Files \(x86\)\\\\ossec-agent\\\\wazuh-agent\.exe$</field>
    <description>Sysmon: Potential lsass.exe dump - Disable alert for Wazuh access</description>
    <mitre>
      <id>T1003.001</id>
    </mitre>
  </rule>


```


Detection of mimikatz and procdump on lsass.exe. Wazuh was filtered from reappearing via Rule 6:
![](../../Images/Pasted%20image%2020260714182907.png)
