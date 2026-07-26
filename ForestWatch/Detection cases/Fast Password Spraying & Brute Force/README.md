# Fast Password Spraying (T1110.003) & Brute Force(T1110.001)

## Summary

Password spraying against the lab domain (ad.lab) was first attempted over SMB, but it was not possible to generate a large volume of failed authentication attempts. Windows Server 2025 enables an SMB Authentication Rate Limiter by default, which throttles rapid failed logons. Switching the spraying protocol from SMB to LDAP worked. Rules detect attack and successful login after attacking attempts.

## Attack execution

All runs were performed from Kali with netexec against the domain controller at 192.168.122.122.

Only the first few accounts are processed; most of the remaining attempts fail with "NETBIOS connection timed out" as the SMB Authentication Rate Limiter throttles the run. Displayed passwords are only used in lab.

![](../../Images/Pasted%20image%2020260712174826.png)

The later attempts used netexec as well, but over LDAP. First, a list of passwords was tested against the single account client1 - every attempt was rejected until the correct password !@#QWE123qwe succeeded.

![](../../Images/Pasted%20image%2020260726173848.png)

Then a single password, !@#QWE123qwe, was sprayed across the full domain user list, which produced a hit on ad.lab\Administrator.

![](../../Images/Pasted%20image%2020260726173932.png)

## Telemetry

Wazuh view for the successful brute-force run.

![](../../Images/Pasted%20image%2020260726173826.png)

Wazuh view for the successful password spraying run.

![](../../Images/Pasted%20image%2020260726174106.png)



## Detection rule

Building blocks — failed and successful network logons:

```
  <!-- Failed Network Logons -->
  <rule id="100110" level="3">
    <if_sid>60122</if_sid>
    <description>ADDC: Failed Network Logon - Account $(win.eventdata.targetUserName)</description>
  </rule>

  <!-- Successful Network Logons -->
  <rule id="100111" level="3">
    <if_sid>92652</if_sid>
    <field name="win.eventdata.logonType">^3$</field>
    <description>ADDC: Successful Network Logon - Account $(win.eventdata.targetUserName)</description>
  </rule>
```

Spraying: many different accounts failing from one IP, then a successful logon from that same IP.

```
  <!-- Rule 1: Fast Password Spraying - 15 attempts in 2 mins - 1 alert per 60 sec (ignore="60") -->
  <rule id="100210" level="14" frequency="15" timeframe="120" ignore="60">
    <if_matched_sid>100110</if_matched_sid>
    <same_field>win.eventdata.ipAddress</same_field>
    <different_field>win.eventdata.targetUserName</different_field>
    <field name="win.eventdata.targetUserName" type="pcre2" negate="yes">(?i)ANONYMOUS LOGON</field>
    <description>ADDC: Fast Password Spraying. More than 15 failed logons in 2 minutes from IP: $(win.eventdata.ipAddress)</description>
    <mitre>
      <id>T1110.003</id>
    </mitre>
    <group>authentication_failures,</group>
  </rule>

  <!-- Rule 2: Fast Password Spraying success - Successful Logon from IP where Password Spraying was detected before -->
  <rule id="100211" level="16" timeframe="600">
    <!-- If Fast spraying is detected (rule 100210) and from the same IP (<same_field>) successful logon is detected (rule 100111) -->
    <if_matched_sid>100210</if_matched_sid>
    <if_sid>100111</if_sid>
    <same_field>win.eventdata.ipAddress</same_field>
    <description>ADDC: Compromised Account from Password Spraying! Account $(win.eventdata.targetUserName) from IP: $(win.eventdata.ipAddress)</description>
    <mitre>
      <id>T1078</id>
    </mitre>
    <group>compromised_account, high_priority,</group>
  </rule>
```

Brute force: the same account failing repeatedly from one IP, then a successful logon for that account from that IP.

```
  <!-- Rule 3: Brute Force from same IP -->
  <rule id="100212" level="14" frequency="5" timeframe="600">
    <!-- If Failed login (rule 100110) from the same IP (<same_field>) is detected more than 5 times in 10 minutes -->
    <if_matched_sid>100110</if_matched_sid>
    <same_field>win.eventdata.ipAddress</same_field>
    <same_field>win.eventdata.targetUserName</same_field>
    <description>ADDC: Brute Force from from IP: $(win.eventdata.ipAddress) detected</description>
    <mitre>
      <id>T1110.001</id>
    </mitre>
    <group>authentication_failures,</group>
  </rule>

  <!-- Rule 4: Successful Brute Force from same IP -->
  <rule id="100213" level="16" timeframe="600">
    <if_matched_sid>100212</if_matched_sid>
    <if_sid>100111</if_sid>
    <same_field>win.eventdata.ipAddress</same_field>
    <same_field>win.eventdata.targetUserName</same_field>
    <description>ADDC: Successful Brute Force! Account $(win.eventdata.targetUserName) from from IP: $(win.eventdata.ipAddress) breached</description>
    <mitre>
      <id>T1078</id>
    </mitre>
    <group>compromised_account, high_priority,</group>
  </rule>
```

## Tuning & false positives

ANONYMOUS LOGON is excluded from the spraying rule (100210) via a negated pcre2 match on targetUserName. Rule 100210 also uses ignore="60, limiting it to one alert per 60 seconds.

## Lessons learned

Windows Server 2025 ships with the SMB Authentication Rate Limiter enabled by default, so SMB is not a reliable transport for generating high-rate failed-logon telemetry. LDAP is a viable alternative for this test.

## Limitations

This was the first rule written for Wazuh; its purpose was to introduce myself to the Wazuh environment. The rule is therefore very basic and has a number of flaws: it does not cover slow attacks (which would require a longer timeframe) or other logon types, as it is based only on 4624/4625 network logons (type 3). Also if compromise of accounts would be done before detecting threshold - the successful logon would not create alert.
