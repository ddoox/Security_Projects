<group name="windows, active_directory, custom_rules,">

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




  <!-- Rule 1: Fast Password Spraying - 15 attempts in 2 mins - 1 alert per 60 sec(ignore="60") -->
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

  <!-- Rule 2: Fast Password Spraying success - Successful Logon from IP where Password Spraying was detected before-->
  <rule id="100211" level="16" timeframe="600">
    <!-- If Fast spraying is detected(rule 100210) and from the same IP (<same_field>) successful logon is detected (rule 100111)-->
    <if_matched_sid>100210</if_matched_sid>
    <if_sid>100111</if_sid>
    <same_field>win.eventdata.ipAddress</same_field>
    <description>ADDC: Compromised Account from Password Spraying! Account $(win.eventdata.targetUserName) from IP: $(win.eventdata.ipAddress)</description>
    <mitre>
      <id>T1078</id>
    </mitre>
    <group>compromised_account, high_priority,</group>
  </rule>


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
  
  
    <!-- Rule 5: lsass.exe access -->
  <rule id="100300" level="16" ignore="3">
    <!-- Rule 61612 = Sysmon - Event 10-->
    <if_sid>61612</if_sid>
    <field name="win.eventdata.targetImage" type="pcre2">(?i)lsass</field>
    <field negate="yes" name="win.eventdata.grantedAccess" type="pcre2">0x1000|0x1400|0x101400|0x101000|0x101001|0x100000|0x100040|0x3200|0x40|0x3200|0x3000|0x3600|0x2000</field>
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
  
  
  

</group>