# Golden Ticket (T1558.001)

## Summary

The hardest case so far. Generating a Golden Ticket after DCSync is easy, but detecting it is complicated, so what follows is a best-effort solution. Detecting Golden Ticket usage is very hard — it is far easier and more reliable to catch the attack during the earlier steps of the chain than to detect it once the ticket is already in use.

All values below come from a disposable lab domain (`ad.lab`) that no longer exists.

## Attack execution

Hashes from DCSync:

```
NTLM (RC4): 43f9957375842a9b29d4f4f9858980c6
AES256: 0421895c35289c3f672fbeb6e7d19e1fffe375d1efc27d5fb3d8eb7e71b2cf07
AES128: 8af6b46bbe001b83c23ddde92b1c42d0
```

User SID:

![](../../Images/Pasted%20image%2020260719131742.png)

Domain SID (base SID, without the trailing RID):

```
S-1-5-21-2796247975-2542141470-1193687965
```

Golden tickets:

![](../../Images/Pasted%20image%2020260719134543.png)


I couldn't get access to the DC using the generated ticket. After usage it was denied and deleted from the client cache.

![](../../Images/Pasted%20image%2020260719134828.png)


After some research I found the patch which introduced PACRequestorEnforcement. My Mimikatz was too old and didn't include the PAC_REQUESTOR structure.

Retrying the attack using Impacket, which includes PAC info (run from Linux, since bypassing Defender on a non-administrator user was out of scope for this lab):

![](../../Images/Pasted%20image%2020260719152744.png)


New thing learned — Kerberos drops tickets when the clock dispersion is too large:

![](../../Images/Pasted%20image%2020260719153223.png)


After a fight with the clock (timesyncd was altering the time synchronization done by ntpdate) I gained access to the ADDC via Golden Ticket:

![](../../Images/Pasted%20image%2020260719154950.png)


To reproduce both PAC failure modes on demand, two more tickets were generated.

Ticket without correct structure resulting in event 37:

```
sudo impacket-ticketer -aesKey 0421895c35289c3f672fbeb6e7d19e1fffe375d1efc27d5fb3d8eb7e71b2cf07 \
 -domain ad.lab \
 -domain-sid S-1-5-21-2796247975-2542141470-1193687965 \
 -user-id 500 \
 -old-pac \  <-- Event 37 trigger
 Administrator
```

Ticket without correct SID resulting in event 38:

```
sudo impacket-ticketer -aesKey 0421895c35289c3f672fbeb6e7d19e1fffe375d1efc27d5fb3d8eb7e71b2cf07 \
 -domain ad.lab \
 -domain-sid S-1-5-21-2796247975-2542141470-1193687965 \
 -user-id 1200 \  <-- Event 38 trigger, Built-in Administrator has RID=500
 Administrator
```

The error returned to a client using an unknown user is the same as in the previous failed attempts, but no distinct Event ID is generated.

![](../../Images/Pasted%20image%2020260720173451.png)


## Telemetry

The Mimikatz PAC problem was confirmed by checking Wazuh alerts, where a default rule caught Event ID 37:

![](../../Images/Pasted%20image%2020260719135140.png)


Event 37 as seen on the ADDC for the ticket generated with `-old-pac`:

![](../../Images/Pasted%20image%2020260720175122.png)


Event 38 as seen on the ADDC for the ticket generated with the wrong RID:

![](../../Images/Pasted%20image%2020260720175135.png)


Successful Golden Ticket usage also triggered a default Wazuh rule:

![](../../Images/Pasted%20image%2020260719155331.png)


I spent some more time on understanding the patch and how events 37 and 38 work. I was trying to use a Golden Ticket with the user FakeAdmin and wrongly expected an event to be generated. PAC_REQUESTOR is validated after checking the account in AD, so when using an account that didn't exist no Kerberos event could be generated (with PACRequestorEnforcement set to 2 — Enforcement).

To sum up everything related to the PAC update:

- Ticket without the new PAC structure generates Event 37 — ticket without requestor
- Ticket without matching SID generates Event 38 — requestor mismatch
- Ticket with an unknown user does not create any event and returns KDC_ERR_TGT_REVOKED to the requestor
- The only way to create a working Golden Ticket is to have the correct RID and username of an existing user

## Detection rule

```
    <!-- Rule 10: Detect Failed Golden Ticket attempt or misconfig - missing PAC -->
  <rule id="100601" level="13">
    <if_sid>61102</if_sid>  
    <field name="win.system.eventID">^37$</field>
    <field name="win.system.providerName">^Microsoft-Windows-Kerberos-Key-Distribution-Center</field>
    <description>Possible Golden Ticket attempt: KDC PAC validation failure (Event 37) - TGT without new PAC</description>
    <mitre>
      <id>T1558.001</id>
    </mitre>
  </rule>
    
    <!-- Rule 11: Detect Failed Golden Ticket attempt or misconfig - wrong RID - search by group(other approach, broader but more costly) not other wazuh rule -->
  <rule id="100602" level="13">
    <if_group>windows</if_group>  
    <field name="win.system.eventID">^38$</field>
    <field name="win.system.providerName">^Microsoft-Windows-Kerberos-Key-Distribution-Center</field>
    <description>Possible Golden Ticket attempt: KDC PAC validation failure (Event 38) - TGT without correct SID</description>
    <mitre>
      <id>T1558.001</id>
    </mitre>
  </rule>

    <!-- Rule 12: Detect common commands used in Golden Ticket acquire -->
  <rule id="100603" level="13">
    <if_sid>61603</if_sid> <!-- Sysmon Event 1: Process Creation -->  
    <field name="win.eventdata.commandLine" type="pcre2">(?i)kerberos::golden|kerberos::ptt|ticketer\.py|KRB5CCNAME</field>
    <description>Golden Ticket attempt: Common tooling detected</description>
    <mitre>
      <id>T1558.001</id>
    </mitre>
  </rule>

    <!-- Rule 13: Successful service ticket requests -->
  <rule id="100604" level="3">
    <if_sid>60106, 92651</if_sid>
    <field name="win.system.eventID">^4769$</field>
    <description>ADDC: Kerberos ticket service granted</description>
  </rule>
  
    <!-- Rule 14: Same account requesting tickets from different IPs -->
 <rule id="100605" level="14" timeframe="900">
    <if_matched_sid>100604</if_matched_sid>
    <same_field>win.eventdata.targetUserName</same_field>
    <different_field>win.eventdata.ipAddress</different_field>
    <field name="win.eventdata.targetUserName" negate="yes" type="pcre2">\$@</field>
    <description>Possible ticket reuse: $(win.eventdata.targetUserName) using Kerberos tickets from multiple hosts, last $(win.eventdata.ipAddress)</description>
    <mitre>
      <id>T1550.003</id>
    </mitre>
  </rule>  

```

Rules 100601 and 100602 firing on events 37 and 38:

![](../../Images/Pasted%20image%2020260721184132.png)

The next implemented rule detects Mimikatz/Impacket usage from a Windows client:

![](../../Images/Pasted%20image%2020260725120818.png)

The better rule detects that the same account was accessed from different IPs:

![](../../Images/Pasted%20image%2020260725134655.png)


## Tuning & false positives

During testing I discovered one more dependency which showed how weak the rules for events 37 and 38 are: the event was triggered only once per multiple requests. To generate new events and test the rules I had to use different SPNs — instead of only impacket-psexec I also used impacket-GetADUsers and impacket-wmiexec, which bypassed Windows duplicate suppression.

The different-IP rule would probably generate some noise in a real environment and would need fine tuning.

## Lessons learned

- Kerberos drops tickets when the clock dispersion is too large; on the attacking host timesyncd was altering the synchronization done by ntpdate.
- PAC_REQUESTOR is validated only after the account is checked in AD, so a ticket for a non-existent account produces no Kerberos event at all.
- A working Golden Ticket requires the correct SID and username of an existing privileged account.
- Detecting Golden Ticket usage is very hard — catching the earlier steps of the attack chain is far easier and more reliable.

## Limitations

- The tooling rule is a weak approach: when the command is not executed in a shell it won't detect it. It can catch one-liners, but mimikatz -> kerberos::golden remains undetected, and it can be bypassed by changing the tool name.
- The best rule would require coding outside Wazuh, i.e. a cache of 4768 events (TGT requests) and a check whether a ticket is used more than 10 hours later without being renewed or a new TGT being created.
- This solution will be revisited after the full attack chain of the project is complete.
