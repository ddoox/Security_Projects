Nice to remember: After getting ticket, it is saved in memory. Used klist purge delete them, so rule testing is possible again

It was easy to write detection rule, but it was not so easy to get it working. On ADDC first try = catch by Wazuh. From client side - nothing. Events 4769 with encryption 0x17 were generated on ADDC, but weren't present on ADDC. First potential cause - dual stack IP Address formatting:
![[Pasted image 20260715165352.png]]


Events from ADDC and client are exactly the same - version 2.

tcpdump on on wazuh manager showing almost same traffic in case of kerberoasting

After enabling Wazuh archieve I can see that the log is generated and send to manger, so it have to be dropped later:
![[Pasted image 20260716170343.png]]

Compared both logs in wazuh logtest, but in both case I've got "no decoder matched".

Yeah, so kind of embarrassing, a short google search saved me from discovering a wheel from the beginning... https://groups.google.com/g/wazuh/c/g1EqZ0ssLYU -

![[Pasted image 20260716174954.png]]



![[Pasted image 20260716175417.png]]