
Baseline to check if events are correctly collected
![[Pasted image 20260718145611.png]]

No alerts about event 4662 generated in Wazuh -> looking at ADDC Event Viewer:
![[Pasted image 20260718150040.png]]

 Event with GUID for P or as very intuitive Windows description says "1131f6ad-9c07-11d1-f79f-00c04fc2dcd2" is present
 ![[Pasted image 20260718150456.png]]

After small flashbacks from Kerberoasting I've learnt to not waste time debugging every step of communication but to first search for rules saving dashboard from noise(level=0 - no alert generated)
![[Pasted image 20260718151424.png]]

Nice to know in future it's better not to use "between" equal value. Start range = 14 and end range = 14 returned empty results
![[Pasted image 20260718152328.png|649]]

At the same time, when using operator "is" the alert is show
![[Pasted image 20260718152450.png]]

By default users don't have enough permissions to replicate DC
![[Pasted image 20260718155254.png]]

But after "accidentally" granting this permission to normal user, it gains the privileges and is able to perform DCSync
![[Pasted image 20260718155349.png]]

The replication is detected from user



I've tried to add extra properties 1131f6aa-9c07-11d1-f79f-00c04fc2dcd2 and 89e95b76-444d-4c62-991a-0facbeda640c which also suggest DCSync, but I've decided not to use them in primary rule, as only the one left actually is allowing to access password's hashes. I've created extra rule with lower level to add complementary information

Single rule with all GUIDs
![[Pasted image 20260718161203.png]]

After tuning
![[Pasted image 20260718161312.png]]

![[Pasted image 20260718161344.png]]

Also after final research modified rule to include ^MSOL_ <- Azure AD Connect. In the lab there are no such accounts, but they can exists in hybrid cloud solutions.

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