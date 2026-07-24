So far it will be the hardest case. The generation of golden ticket is easy after DCSync, but detection is complicated and for this is presenting best-effort solution.

Hashes from DCSync:
```
NTLM (RC4): 43f9957375842a9b29d4f4f9858980c6
AES256: 0421895c35289c3f672fbeb6e7d19e1fffe375d1efc27d5fb3d8eb7e71b2cf07
AES128: 8af6b46bbe001b83c23ddde92b1c42d0
```
User SID
![](../../Images/Pasted%20image%2020260719131742.png)

Domain SID(without user part)
```
S-1-5-21-2796247975-2542141470-1193687965
```

Golden tickets
![](../../Images/Pasted%20image%2020260719134543.png)

I couldn't get access to the DC using the generated ticket. After usage it was denied and deleted from client cache
![](../../Images/Pasted%20image%2020260719134828.png)

After some research I've found the patch which introduced PACRequestorEnforcement. My Mimikatz was too old and didn't include PAC_REQUESTOR structure. I've confirmed it by checking Wazuh alerts, where default rule caught Event ID 37 
![](../../Images/Pasted%20image%2020260719135140.png)

Retrying attack using impacket which includes PAC info(from linux as omitting Defender on non-Administrator user was tiresome and not the point of this lab)
![](../../Images/Pasted%20image%2020260719152744.png)

New thing learned - Kerberos is dropping tickets when there is too big clock dispersion 
![](../../Images/Pasted%20image%2020260719153223.png)

After a fight with a clock(timesyncd was altering time synchronization from ntpdate) I've gained access to ADDC via Golden Ticket
![](../../Images/Pasted%20image%2020260719154950.png)

This triggered default rule from Wazuh
![](../../Images/Pasted%20image%2020260719155331.png)


I've spent some more time on understanding the patch and how the events 37 and 38 works. I was trying to use golden ticket with user FakeAdmin and was wrongly expecting event to be generated. PAC_REQUESTOR is validated after checking account in AD, so when I was using account that didn't exists there couldn't be generated any Kerberos event(with PACRequestorEnforcement set to 2(Enforcement)).


So to sum up everything with PAC update:
- Ticket without new PAC structure generates Event 37 - Ticket without requestor
- Ticket without matching SID generates Event 38 - Requestor mismatch
- Ticket with unknown user don't create any event and returns KDC_ERR_TGT_REVOKED to requestor
- Only possible way to create Golden Ticket is to have correct SID and username for existing user with privileged access 


Ticket without correct structure resulting with event 37
```
sudo impacket-ticketer -aesKey 0421895c35289c3f672fbeb6e7d19e1fffe375d1efc27d5fb3d8eb7e71b2cf07 \
 -domain ad.lab \
 -domain-sid S-1-5-21-2796247975-2542141470-1193687965 \
 -user-id 500 \
 -old-pac \  <-- Event 37 trigger
 Administrator
```

![](../../Images/Pasted%20image%2020260720175122.png)

Ticket without correct structure resulting with event 37
```
sudo impacket-ticketer -aesKey 0421895c35289c3f672fbeb6e7d19e1fffe375d1efc27d5fb3d8eb7e71b2cf07 \
 -domain ad.lab \
 -domain-sid S-1-5-21-2796247975-2542141470-1193687965 \
 -user-id 1200 \  <-- Event 38 trigger, Built-in Administrator has RID=500
 Administrator
```

![](../../Images/Pasted%20image%2020260720175135.png)


Error returned to client using unknown user is the same as in previous failed attempts, but no distinct Event ID is generated.
![](../../Images/Pasted%20image%2020260720173451.png)

During testing I've discovered one more dependency which showed me how weak are the rules for the Events 37 and 38 - The Event was triggered only once per multiple requests. To generate new events to test the rules I've had to use different SPNs - instead only impacket-psexec I've used also impacket-GetADUsers and impacket-wmiexec which omitted Windows duplicate suppression. 

![](../../Images/Pasted%20image%2020260721184132.png)










Final rules:
- TBD: Correlation between 
- Rules for Event ID 37/38 as warning signal that there was attempt with badly configured offensive tool


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
    
    <!-- Rule 11: Detect Failed Golden Ticket attempt or misconfig - wrong RID - search by group not other wazuh rule -->
  <rule id="100602" level="13">
    <if_group>windows</if_group>  
    <field name="win.system.eventID">^38$</field>
    <field name="win.system.providerName">^Microsoft-Windows-Kerberos-Key-Distribution-Center</field>
    <description>Possible Golden Ticket attempt: KDC PAC validation failure (Event 38) - TGT without correct SID</description>
    <mitre>
      <id>T1558.001</id>
    </mitre>
  </rule>
```