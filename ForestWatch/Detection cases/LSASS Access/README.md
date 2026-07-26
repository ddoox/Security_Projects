# LSASS Access (T1003.001)

## Summary

Detection of credential dumping via access to `lsass.exe`, using Sysmon Event 10 (ProcessAccess) forwarded to Wazuh. The default Wazuh ruleset silently suppressed these events, so the corresponding rule had to be overridden and a custom high-severity rule added, followed by tuning to reduce noise.

## Attack execution

Mimikatz (old version) does not work on a default Windows Server 2025 installation, so `procdump` was used to dump `lsass.exe` instead.

## Telemetry

Sysmon was reconfigured to log Event 10 when `TargetImage=lsass.exe`. Even after that, no alert was triggered: the default Wazuh ruleset contains rule 61612 with `level="0"`, which was successfully muting the Sysmon alerts to prevent noise - Wazuh ignores all such events by default.

```
  <rule id="61612" level="0">
    <if_sid>61600</if_sid>
    <field name="win.system.eventID">^10$</field>
    <description>Sysmon - Event 10: $(win.eventdata.targetImage) process accessed by $(win.eventdata.sourceImage)</description>
    <options>no_full_log</options>
    <group>sysmon_event_10,</group>
  </rule>
```

This rule had to be overwritten.

## Detection rule

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
```

## Tuning & false positives

After overriding rule 61612, dumping `lsass.exe` was detected successfully, but the alert generated a lot of noise and had to be fine-tuned. Following the Elastic guide, access attempts with privileges insufficient to dump the process (`PROCESS_VM_READ` — `0x0010`) are ignored: https://www.elastic.co/guide/en/security/8.19/suspicious-lsass-process-access.html

This reduced the number of false positives, but one remained visible — the Wazuh agent itself. An extra rule was added to disable the alert when `SourceImage` matches the Wazuh agent path.

```
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

![](../../Images/Pasted%20image%2020260714182907.png)

*Wazuh alerts showing detection of Mimikatz and procdump accessing `lsass.exe`, with the Wazuh agent's own access filtered out by rule 100301.*

## Lessons learned

The default Wazuh ruleset can silently suppress relevant telemetry: rule 61612 is enabled by default with `level="0"`, so Sysmon Event 10 events are ignored and no alert is raised even when Sysmon is correctly configured. Default rulesets need to be verified before assuming a detection gap lies in the agent or Sysmon configuration.

## Limitations

The Wazuh agent is whitelisted by executable path only. In a real-world scenario, additional integrity checks should be implemented to verify whitelisted processes.
