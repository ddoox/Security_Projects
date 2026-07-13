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
  

</group>