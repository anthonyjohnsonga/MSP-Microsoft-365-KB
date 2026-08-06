# Active Directory Recovery Guide
## Recovering When the FSMO Role Holder Is Permanently Offline

**Applies to:** Windows Server 2016–2025 Active Directory Domain Services; any forest/domain functional level supporting the `ActiveDirectory` PowerShell module  
**Scope:** Seizing FSMO roles, cleaning failed-DC metadata and DNS, and re-establishing time hierarchy after a domain controller is permanently lost with no usable backup. Assumes at least one healthy writable DC survives. Does not cover forest recovery from total loss, authoritative SYSVOL restore, or DSRM-based restores.  
**Last Updated:** August 2026

---

### Example environment

This guide uses fictional names and addresses:

| System | Role | IP address | Status |
|---|---|---:|---|
| `EXAMPLE-DC01` | Original FSMO role holder | `192.168.10.10` | Permanently offline |
| `EXAMPLE-DC02` | Surviving domain controller | `192.168.10.11` | Online |
| `EXAMPLE-DC03` | Surviving domain controller | `192.168.10.12` | Online |
| Domain | `example.local` |  |  |

## Purpose

Use this procedure when:

- A domain controller has permanently failed.
- The failed server held one or more FSMO roles.
- No usable backup of the failed DC exists.
- At least one other writable domain controller remains online.
- The failed DC will not be restored or reconnected using its old Windows installation.

> **Critical warning:** After FSMO roles are seized, never reconnect the failed DC using its original Active Directory installation. If the hardware is repaired, wipe and reinstall Windows before returning it to the domain.

---

## Phase 1: Confirm the current condition

### 1. Permanently isolate the failed DC

Make sure the failed server cannot unexpectedly return to the network.

For a physical server:

- Disconnect its network cables.
- Leave it powered off.
- Label it so another technician does not reconnect it.

For a virtual server:

- Power off the VM.
- Disconnect its virtual network adapter.
- Do not restore an old snapshot after completing the recovery.

### 2. Identify the current FSMO role holders

Run from a surviving DC:

```powershell
netdom query fsmo
```

Example failed state:

```text
Schema master               EXAMPLE-DC01.example.local
Domain naming master        EXAMPLE-DC01.example.local
PDC                         EXAMPLE-DC01.example.local
RID pool manager            EXAMPLE-DC01.example.local
Infrastructure master       EXAMPLE-DC01.example.local
```

### 3. List all domain controllers

```powershell
Get-ADDomainController -Filter * |
    Select-Object HostName, IPv4Address, Site, IsGlobalCatalog, OperatingSystem
```

Also run:

```powershell
nltest /dclist:example.local
```

The failed server may still appear because its Active Directory metadata has not yet been removed.

---

## Phase 2: Verify the surviving DCs

Do not seize FSMO roles until the surviving domain controllers have been checked.

### 4. Confirm SYSVOL and NETLOGON

Run on each surviving DC:

```powershell
net share
```

Confirm these shares exist:

```text
NETLOGON
SYSVOL
```

You can also test them remotely:

```powershell
dir \\EXAMPLE-DC02\SYSVOL
dir \\EXAMPLE-DC02\NETLOGON

dir \\EXAMPLE-DC03\SYSVOL
dir \\EXAMPLE-DC03\NETLOGON
```

### 5. Check replication

Run:

```powershell
repadmin /replsummary
```

Then check each surviving DC:

```powershell
repadmin /showrepl EXAMPLE-DC02
repadmin /showrepl EXAMPLE-DC03
```

Failures involving the dead `EXAMPLE-DC01` are expected.

The important requirement is that:

- `EXAMPLE-DC02` replicates successfully with `EXAMPLE-DC03`.
- `EXAMPLE-DC03` replicates successfully with `EXAMPLE-DC02`.
- All Active Directory naming contexts replicate successfully between the survivors.

Typical naming contexts include:

```text
DC=example,DC=local
CN=Configuration,DC=example,DC=local
CN=Schema,CN=Configuration,DC=example,DC=local
DC=DomainDnsZones,DC=example,DC=local
DC=ForestDnsZones,DC=example,DC=local
```

### 6. Run initial health checks

```powershell
dcdiag /e /test:Advertising /test:Services /test:SysVolCheck /test:NetLogons /test:Replications
```

A healthy surviving DC should pass:

- Connectivity
- Advertising
- Services
- SYSVOL
- NETLOGON
- Replications

---

## Phase 3: Prepare administrative permissions

### 7. Confirm required group memberships

To seize all five FSMO roles, use an account with:

- Domain Admins
- Enterprise Admins
- Schema Admins

Check the current security token:

```powershell
whoami /groups | findstr /i "Domain Admins Enterprise Admins Schema Admins"
```

If the required groups are missing, temporarily add the administrative account:

```powershell
Add-ADGroupMember `
    -Identity "Enterprise Admins" `
    -Members "admin.account"

Add-ADGroupMember `
    -Identity "Schema Admins" `
    -Members "admin.account"
```

Sign completely out of Windows and sign back in. Opening a new PowerShell window does not refresh the existing logon token.

Verify again:

```powershell
whoami /groups | findstr /i "Domain Admins Enterprise Admins Schema Admins"
```

---

## Phase 4: Seize the FSMO roles

### 8. Choose the new role holder

Select the healthiest surviving DC.

The selected server should preferably:

- Be a writable DC.
- Be a Global Catalog.
- Run DNS.
- Have reliable power and storage.
- Have clean replication.
- Be located in the primary site.

For this example, all roles will be seized by:

```text
EXAMPLE-DC02
```

### 9. Seize all five roles

Run on `EXAMPLE-DC02` in elevated PowerShell:

```powershell
Import-Module ActiveDirectory

Move-ADDirectoryServerOperationMasterRole `
    -Identity "EXAMPLE-DC02" `
    -OperationMasterRole SchemaMaster,DomainNamingMaster,PDCEmulator,RIDMaster,InfrastructureMaster `
    -Force
```

The command may first attempt a normal transfer. Because the original holder is offline, it will then seize the roles.

Approve any confirmation prompts.

### 10. Verify the seizure

```powershell
netdom query fsmo
```

Expected result:

```text
Schema master               EXAMPLE-DC02.example.local
Domain naming master        EXAMPLE-DC02.example.local
PDC                         EXAMPLE-DC02.example.local
RID pool manager            EXAMPLE-DC02.example.local
Infrastructure master       EXAMPLE-DC02.example.local
```

Verify directly through the Active Directory module:

```powershell
Get-ADForest |
    Select-Object SchemaMaster, DomainNamingMaster
```

```powershell
Get-ADDomain |
    Select-Object PDCEmulator, RIDMaster, InfrastructureMaster
```

Do not begin metadata cleanup until all five roles show the new DC.

---

## Phase 5: Remove the failed DC

### 11. Remove the failed DC from Active Directory

Open **Active Directory Users and Computers**.

1. Open the **Domain Controllers** organizational unit.
2. Right-click `EXAMPLE-DC01`.
3. Select **Delete**.
4. Confirm that the DC is permanently offline.
5. Confirm removal even though it cannot be demoted normally.

### 12. Check Active Directory Sites and Services

Open **Active Directory Sites and Services** and browse to:

```text
Sites
└── Default-First-Site-Name
    └── Servers
```

Confirm `EXAMPLE-DC01` is removed.

If it remains:

1. Delete its `NTDS Settings` object.
2. Delete the `EXAMPLE-DC01` server object.

### 13. Force replication

```powershell
repadmin /syncall /AdeP
```

Then:

```powershell
repadmin /replsummary
```

The failed server should no longer appear.

Expected result:

```text
Source DSA       fails/total
EXAMPLE-DC02     0 / 5
EXAMPLE-DC03     0 / 5

Destination DSA  fails/total
EXAMPLE-DC02     0 / 5
EXAMPLE-DC03     0 / 5
```

Verify the DC list:

```powershell
Get-ADDomainController -Filter * |
    Select-Object HostName, IPv4Address, Site, IsGlobalCatalog
```

```powershell
nltest /dclist:example.local
```

Only the surviving DCs should appear.

---

## Phase 6: Clean up DNS

### 14. Remove stale records

Open DNS Manager and inspect:

```text
Forward Lookup Zones
├── example.local
└── _msdcs.example.local
```

Remove records that belong specifically to the failed DC:

- Host A record
- AAAA record
- PTR record
- NS record
- LDAP SRV records
- Kerberos SRV records
- Global Catalog SRV records
- GUID-based CNAME under `_msdcs`
- Entries on the zone’s Name Servers tab

Do not delete records belonging to the surviving DCs.

### 15. Verify the `_msdcs` delegation

Check the delegation stored in the parent zone:

```powershell
Get-DnsServerResourceRecord `
    -ZoneName "example.local" `
    -Name "_msdcs" `
    -RRType NS
```

Check the NS records in the separate forest zone:

```powershell
Get-DnsServerResourceRecord `
    -ZoneName "_msdcs.example.local" `
    -RRType NS
```

Only the surviving DCs should appear.

Example:

```text
EXAMPLE-DC02.example.local.
EXAMPLE-DC03.example.local.
```

### 16. Repair a malformed delegation if necessary

A common DNS diagnostic error is:

```text
Missing glue A record
```

This means the `_msdcs` delegation has an NS record but is missing the associated IP address information.

First confirm the separate AD-integrated child zone exists:

```powershell
Get-DnsServerZone -Name "_msdcs.example.local"
```

If the delegation is malformed and cannot be removed through the delegation cmdlet, check whether the parent-zone records exist:

```powershell
Get-DnsServerResourceRecord `
    -ZoneName "example.local" `
    -Name "_msdcs"
```

If necessary, remove the malformed NS records from the parent zone and recreate the delegation.

Create the first delegation entry:

```powershell
Add-DnsServerZoneDelegation `
    -ComputerName "EXAMPLE-DC02" `
    -Name "example.local" `
    -ChildZoneName "_msdcs" `
    -NameServer "EXAMPLE-DC02.example.local." `
    -IPAddress "192.168.10.11" `
    -PassThru
```

Create the second entry:

```powershell
Add-DnsServerZoneDelegation `
    -ComputerName "EXAMPLE-DC02" `
    -Name "example.local" `
    -ChildZoneName "_msdcs" `
    -NameServer "EXAMPLE-DC03.example.local." `
    -IPAddress "192.168.10.12" `
    -PassThru
```

Verify:

```powershell
Get-DnsServerZoneDelegation `
    -ComputerName "EXAMPLE-DC02" `
    -Name "example.local" `
    -ChildZoneName "_msdcs" |
    Format-List *
```

Then replicate and test:

```powershell
repadmin /syncall /AdeP
Clear-DnsClientCache
dcdiag /test:dns /e
```

Expected result:

```text
example.local passed test DNS
```

---

## Phase 7: Correct DNS client configuration

### 17. Check DNS server addresses

Run on both surviving DCs:

```powershell
Get-DnsClientServerAddress -AddressFamily IPv4 |
    Where-Object ServerAddresses |
    Format-Table InterfaceAlias, ServerAddresses -AutoSize
```

Remove the failed DC’s address from all DNS client settings.

Example configuration:

#### EXAMPLE-DC02

```text
Preferred DNS: 192.168.10.12
Alternate DNS: 192.168.10.11
```

#### EXAMPLE-DC03

```text
Preferred DNS: 192.168.10.11
Alternate DNS: 192.168.10.12
```

Do not configure public DNS servers directly on a domain controller’s network adapter.

Configure public resolvers as DNS forwarders in DNS Manager instead.

Also remove the failed DC’s IP from:

- DHCP option 006
- Static server configurations
- Hypervisors
- Firewalls
- Network switches
- VPN configurations
- Printers
- Applications using LDAP
- Monitoring systems
- Backup applications

---

## Phase 8: Configure the new PDC time source

### 18. Check the current time source

Run on the new PDC Emulator:

```powershell
w32tm /query /source
w32tm /query /status
```

A virtual DC may initially report:

```text
VM IC Time Synchronization Provider
```

The forest-root PDC Emulator should use a reliable external NTP source.

### 19. Configure external NTP

Run on the new PDC:

```powershell
w32tm /config `
    /manualpeerlist:"time.cloudflare.com,0x8 time.google.com,0x8" `
    /syncfromflags:manual `
    /reliable:yes `
    /update
```

Restart the Windows Time service:

```powershell
Restart-Service w32time
```

Force synchronization:

```powershell
w32tm /resync /rediscover
```

Verify:

```powershell
w32tm /query /source
w32tm /query /status
w32tm /query /peers
```

A healthy result should show:

- One of the configured external peers as the source.
- A recent successful synchronization.
- Both peers in an active state.
- A reasonable stratum.

Example:

```text
Source: time.google.com,0x8
Stratum: 2
```

If it continues using the VM integration provider, review the VM’s Hyper-V Integration Services time-synchronization setting.

### 20. Configure the other DC to follow the domain hierarchy

Run on the non-PDC domain controller:

```powershell
w32tm /config /syncfromflags:domhier /reliable:no /update
Restart-Service w32time
w32tm /resync /rediscover
```

Verify:

```powershell
w32tm /query /source
w32tm /query /status
```

---

## Phase 9: Final validation

### 21. Run complete replication checks

```powershell
repadmin /syncall /AdeP
repadmin /replsummary
repadmin /showrepl EXAMPLE-DC02
repadmin /showrepl EXAMPLE-DC03
```

Expected:

```text
0 replication failures
```

### 22. Run Active Directory health checks

```powershell
dcdiag /e /test:Advertising /test:Services /test:SysVolCheck /test:NetLogons /test:Replications
```

Both DCs should pass all selected tests.

### 23. Run DNS checks

```powershell
dcdiag /test:dns /e
```

Expected:

```text
EXAMPLE-DC02 passed test DNS
EXAMPLE-DC03 passed test DNS
example.local passed test DNS
```

### 24. Confirm FSMO roles

```powershell
netdom query fsmo
```

All roles should point to the selected new FSMO holder.

### 25. Confirm the final DC list

```powershell
nltest /dclist:example.local
```

```powershell
Get-ADDomainController -Filter * |
    Select-Object HostName, IPv4Address, Site, IsGlobalCatalog
```

Only active DCs should appear.

---

## Phase 10: Remove temporary permissions

After recovery is complete, remove the administrative account from temporary high-privilege groups:

```powershell
Remove-ADGroupMember `
    -Identity "Enterprise Admins" `
    -Members "admin.account" `
    -Confirm:$false
```

```powershell
Remove-ADGroupMember `
    -Identity "Schema Admins" `
    -Members "admin.account" `
    -Confirm:$false
```

Sign out and back in to remove those privileges from the active security token.

---

## Phase 11: Build a replacement DC

Do not reuse the failed DC’s original Windows installation.

To add a replacement:

1. Install Windows Server cleanly.
2. Assign a static IP.
3. Point DNS to the surviving domain controllers.
4. Join the server to the domain.
5. Install Active Directory Domain Services and DNS.
6. Promote it as an additional domain controller.
7. Enable Global Catalog.
8. Confirm SYSVOL and NETLOGON.
9. Verify replication.
10. Configure monitoring and backups.

Using a new hostname is generally safer than immediately reusing the old DC’s name.

---

## Post-recovery checklist

- [ ] Failed DC permanently isolated
- [ ] Surviving DCs replicate successfully
- [ ] SYSVOL and NETLOGON available
- [ ] FSMO roles seized
- [ ] FSMO ownership verified
- [ ] Failed DC metadata removed
- [ ] Active Directory Sites and Services cleaned
- [ ] Stale DNS records removed
- [ ] `_msdcs` delegation tested
- [ ] DNS glue records repaired if necessary
- [ ] Failed DNS server IP removed from DHCP
- [ ] Failed DNS server IP removed from static systems
- [ ] DNS diagnostics pass
- [ ] New PDC uses external NTP
- [ ] Secondary DC follows domain time hierarchy
- [ ] Temporary privileged memberships removed
- [ ] Backups configured and tested
- [ ] Replacement DC planned or deployed

## Recovery summary

The lack of a backup for the failed DC does not automatically mean the Active Directory domain is lost. When healthy writable domain controllers remain, they normally retain replicated copies of users, groups, computers, Group Policy data and AD-integrated DNS.

The safe recovery process is:

```text
Verify survivors
→ Seize FSMO roles
→ Remove failed DC metadata
→ Repair DNS
→ Verify replication
→ Configure PDC time
→ Run final health checks
→ Build a clean replacement
```

The failed DC must never be reintroduced using its original Active Directory installation after FSMO seizure.

---

## Sources

- Microsoft Learn: [Transfer or seize Operation Master roles in AD DS](https://learn.microsoft.com/en-us/troubleshoot/windows-server/active-directory/transfer-or-seize-operation-master-roles-in-ad-ds)
- Microsoft Learn: [View and transfer FSMO roles](https://learn.microsoft.com/en-us/troubleshoot/windows-server/active-directory/view-transfer-fsmo-roles)
- Microsoft Learn: [Clean up Active Directory Domain Controller server metadata](https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/deploy/ad-ds-metadata-cleanup)
- Microsoft Learn: [Planning operations master role placement](https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/plan/planning-operations-master-role-placement)
- Microsoft Learn: [`Move-ADDirectoryServerOperationMasterRole`](https://learn.microsoft.com/en-us/powershell/module/activedirectory/move-addirectoryserveroperationmasterrole)
- Microsoft Learn: [`Add-DnsServerZoneDelegation`](https://learn.microsoft.com/en-us/powershell/module/dnsserver/add-dnsserverzonedelegation)
- Microsoft Learn: [`dcdiag`](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/dcdiag)
- Microsoft Learn: [`netdom query`](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/netdom-query)
- Microsoft Learn: [`repadmin`](https://learn.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2012-R2-and-2012/cc770963(v=ws.11))
- Microsoft Learn: [Windows Time Service tools and settings](https://learn.microsoft.com/en-us/windows-server/networking/windows-time-service/windows-time-service-tools-and-settings)
- Microsoft Learn: [Configure systems for high accuracy time](https://learn.microsoft.com/en-us/windows-server/networking/windows-time-service/configuring-systems-for-high-accuracy)
