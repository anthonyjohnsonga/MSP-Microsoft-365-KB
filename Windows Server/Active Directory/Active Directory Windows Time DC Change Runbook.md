# Active Directory Windows Time DC Change Runbook

**Applies to:** Windows Server AD DS in a single-domain forest and domain-joined Windows members.
**Scope:** Windows Time configuration and validation. Multi-domain forests require a separate design; external NTP normally belongs on the forest-root PDC. This pair supplements an approved AD DS migration plan.
**Last Updated:** October 4, 2026

**Companion:** [Baseline](./Active%20Directory%20Windows%20Time%20Baseline%20Runbook.md) then [DC Change](./Active%20Directory%20Windows%20Time%20DC%20Change%20Runbook.md).

---

## 1. Overview

### 1.1 Which procedure do I need?

| Situation | Procedures to follow |
|---|---|
| Adding a second DC, no role changes | 3 (Add a DC) only |
| Moving the PDC role between existing DCs | 4 (Transfer the PDC role) only |
| **Replacing a DC** (new server or OS, old one retired) | 3, then 4, then 5 (Retire the old DC) |
| Old DC failed and will never return | 6 (Emergency seizure), then validate |

Section 2 (Pre-Checks) applies to every row.

### 1.2 How the time config follows the role

the baseline companion created two GPOs on the Domain Controllers OU, each filtered by WMI:

| GPO | Filter | Result |
|---|---|---|
| `Time - PDC Emulator - Authoritative NTP` | `DomainRole = 5` | Applies to the current PDC emulator: Type NTP, upstream sources |
| `Time - Non-PDC DCs - NT5DS` | `DomainRole = 4` | Applies to every other DC: Type NT5DS |

When the role moves, the filters re-evaluate at the next policy refresh (every 5 minutes on DCs by default, or immediately with `gpupdate /force`). The new holder gets authoritative NTP. The old holder drops back to NT5DS.

### 1.3 What the GPOs cannot do

They cannot fix the following. This runbook checks all three:

- An upstream firewall that allows UDP 123 only from the old DC's IP
- A DC that never received the GPO because SYSVOL has not replicated
- A hypervisor overriding W32Time on the VM

---



### Operational safeguards

- Use elevated local administrator rights for local service changes, delegated GPO rights for policy edits, and role-specific AD permissions for FSMO changes. Domain roles normally require Domain Admins, domain naming Enterprise Admins, and schema Schema Admins; remove temporary elevation after validation.
- Back up affected GPOs and capture effective configuration before changes. Disabling a link alone may not restore historical local settings; verify the effective configuration after rollback.
- No Microsoft 365 add-on license is required for these AD DS time checks; normal Windows Server licensing applies. Assess each customer forest independently and keep customer configuration and validation output private.
- Stripchart uses an ephemeral UDP source port; W32Time uses UDP 123 as source and destination. Stripchart success alone does not prove service connectivity. Confirm firewall logs, service resync, and recent successful synchronization.
- Hyper-V integration-service guidance here applies to on-premises virtual DCs. Review VMware and cloud provider guidance before changing guest time integration; do not apply a blanket Azure change.
- A subsecond offset is an example operational target, not a universal Windows accuracy guarantee.
- Review effective AnnounceFlags and historical /reliable:yes settings. Do not copy AnnounceFlags 5 blindly; Microsoft documents cases requiring 0xA for unreliable upstream synchronization or special polling. Enabling the NTP server provider alone does not establish a healthy time source.
- A GPO folder in SYSVOL alone does not prove convergence: compare policy versions and contents and verify the applied policy report.
- Before emergency seizure, follow the [FSMO Recovery Guide](./Active%20Directory%20FSMO%20Recovery%20Guide.md), verify a healthy surviving writable DC, and isolate the failed holder. Rebuild it before returning it to service.
- repadmin /syncall /AdeP requests replication across sites; confirm bandwidth and the approved change window.

## 2. Pre-Checks (All Procedures)

> Complete these **before** promoting a DC or transferring any role. Record results in the ticket.

### 2.1 Baseline confirmed

- [ ] Both time GPOs exist and are linked to the Domain Controllers OU (`Time - PDC Emulator - Authoritative NTP` and `Time - Non-PDC DCs - NT5DS`)
- [ ] Both WMI filters exist and are attached to the correct GPOs
- [ ] Current PDC emulator is syncing from the approved NTP source:

```powershell
Get-ADDomain | Select-Object PDCEmulator
w32tm /query /source        # run on the PDC emulator
```

If any item fails, stop and complete the baseline companion first.

### 2.2 Directory health

Run on the current DC (and on the new DC once it is promoted).

```powershell
dcdiag /v
repadmin /replsummary
repadmin /showrepl
```

- [ ] No unresolved replication errors
- [ ] `dcdiag` passes for connectivity, services, and DNS

### 2.3 SYSVOL replication (critical)

The new DC can only apply a GPO it has received. Skipping this check is the most common reason the role transfer appears to work but the new PDC has no authoritative NTP config.

On the **new DC**:

```powershell
Get-SmbShare | Where-Object Name -in 'SYSVOL','NETLOGON'
dcdiag /test:sysvolcheck /test:advertising
dfsrmig /getglobalstate
```

- [ ] `SYSVOL` and `NETLOGON` shares exist
- [ ] `dfsrmig` reports **Eliminated** (FRS retired). If it does not, address that before continuing.
- [ ] The new DC's `SYSVOL\<domain>\Policies` folder contains the GUID folders for both time GPOs (compare to the current DC)

### 2.4 Firewall readiness

- [ ] Outbound **UDP 123** from the **new** DC to the approved NTP sources is allowed
- [ ] If the firewall permits NTP per source IP, the new DC's IP is added **before** the role transfer
- [ ] Test from the new DC:

```powershell
w32tm /stripchart /computer:ntp1.example.net /samples:5 /dataonly
```

- [ ] Windows Firewall rule `Active Directory Domain Controller - W32Time (NTP-UDP-In)` is enabled on the new DC

### 2.5 Virtualization time sync

If the new DC is a VM:

- [ ] Hyper-V: **Time synchronization** integration service **disabled on the new DC VM** (and confirmed disabled on the old DC). Disable it on every DC VM, not only the PDC emulator.
- [ ] VMware: **Synchronize guest time with host** disabled, including periodic sync, checked against the approved guest time design
- [ ] Cloud VM (Azure or similar): provider time integration checked against your standard
- [ ] After the role transfer, the new PDC does **not** show `VM IC Time Synchronization Provider` as its source

### 2.6 Clock check on the new server

Before promotion, confirm the new server is already accurate.

```powershell
w32tm /query /source
$pdc = (Get-ADDomain).PDCEmulator
w32tm /stripchart /computer:$pdc /samples:3 /dataonly
```

- [ ] Source is a healthy domain controller selected through NT5DS
- [ ] Offset is small (well under a second)

### 2.7 Inventory devices that use the old DC for NTP

NT5DS domain members follow the hierarchy automatically. Static settings on other devices do not.

Check and list any device pointing at the old DC's IP or name:

- [ ] Firewall / router
- [ ] Switches and wireless controllers
- [ ] NAS and backup appliances
- [ ] Hypervisor hosts
- [ ] Phone system
- [ ] Door access, cameras, alarm panels
- [ ] Printers or other devices with a time server setting

If reusing an IP address, plan the cutover after the old server is offline and verify DNS, firewall, and appliance behavior. Address reuse does not replace this inventory.

### 2.8 Backups and approvals

- [ ] System state or full VM backup of the current DC verified
- [ ] Change approved and window scheduled
- [ ] Client notified

---

## 3. Procedure: Add a DC (No Role Change)

Use this when adding a second DC for redundancy or as step one of a replacement.

### 3.1 Promote the new DC

Promote through Server Manager or `Install-ADDSDomainController`. Join the existing domain and let it replicate.

### 3.2 Confirm placement

- [ ] The new DC's computer object is in the **Domain Controllers** OU (promotion does this automatically)
- [ ] It is **not** in a member server OU, where the member server time GPO would apply

### 3.3 Confirm the time GPOs applied

On the new DC:

```powershell
gpupdate /force
(Get-CimInstance Win32_ComputerSystem).DomainRole
gpresult /r /scope computer
```

- [ ] `DomainRole` returns `4`
- [ ] `gpresult` shows `Time - Non-PDC DCs - NT5DS` as **applied**
- [ ] `gpresult` shows `Time - PDC Emulator - Authoritative NTP` as **denied (WMI filter)**. This is expected.

### 3.4 Validate time

```powershell
w32tm /resync /rediscover
w32tm /query /source
w32tm /query /configuration
```

- [ ] Source is a healthy DC in the NT5DS hierarchy; it need not select the PDC directly
- [ ] Type shows `NT5DS`

### 3.5 Record

- [ ] New DC added to client documentation
- [ ] If the work ends here (no replacement), the procedure is complete

---

## 4. Procedure: Transfer the PDC Emulator Role

Use this to move the PDC emulator role from the old DC (**DC01**) to the new DC (**DC02**). Complete Section 2 and, for new servers, Section 3 first.

### 4.1 Pre-transfer state check

```powershell
netdom query fsmo
```

- [ ] DC01 holds the PDC emulator role
- [ ] DC02 reports `DomainRole = 4`
- [ ] DC02 uses a healthy NT5DS source (Section 3.4 passed); a direct DC01 source is not required

### 4.2 Transfer the role

Typically all FSMO roles move together during a replacement. Run from any DC with the AD module:

```powershell
# PDC emulator only
Move-ADDirectoryServerOperationMasterRole -Identity "DC02" -OperationMasterRole PDCEmulator

# Or all five roles
Move-ADDirectoryServerOperationMasterRole -Identity "DC02" -OperationMasterRole PDCEmulator,RIDMaster,InfrastructureMaster,SchemaMaster,DomainNamingMaster
```

Do **not** use `-Force`. Per Microsoft's documentation, `-Force` attempts a transfer first and can seize the role if transfer fails. Use it only under Procedure 6.

Use the server's **short name** for `-Identity` (as above). Microsoft documents a known issue where the cmdlet fails when an FQDN is supplied.

- [ ] Command completed without errors
- [ ] Confirm:

```powershell
netdom query fsmo
```

All moved roles now show DC02.

### 4.3 Force policy re-evaluation (both servers)

The role change is not instant for Windows Time. The WMI filter reads each DC's own view of who holds the role, so let AD replicate the change first. In a single site this is usually quick:

```powershell
repadmin /syncall /AdeP
netdom query fsmo
```

If DC01 still reports `DomainRole = 5` shortly after the transfer, it has not yet seen the change. Wait or re-run replication before concluding something is wrong. Then run on **both** DCs:

```powershell
gpupdate /force
w32tm /config /update
w32tm /resync /rediscover
```

If a source does not change, restart the service per your change procedure:

```powershell
Restart-Service w32time
w32tm /resync /rediscover
```

### 4.4 Validate: new PDC (DC02)

```powershell
(Get-CimInstance Win32_ComputerSystem).DomainRole
w32tm /query /source
w32tm /query /configuration
w32tm /query /status /verbose
w32tm /query /peers
```

- [ ] `DomainRole` returns `5`
- [ ] Source is one of the **approved NTP servers**
- [ ] Source is **not** `Local CMOS Clock`, `Free-running System Clock`, or `VM IC Time Synchronization Provider`
- [ ] Type is `NTP` with the expected NtpServer list, coming from policy
- [ ] Recent successful sync and small offset

### 4.5 Validate: old PDC (DC01)

```powershell
(Get-CimInstance Win32_ComputerSystem).DomainRole
w32tm /query /source
w32tm /query /configuration
```

- [ ] `DomainRole` returns `4`
- [ ] Source is a healthy DC in the hierarchy whose upstream chain reaches DC02
- [ ] Type is `NT5DS`
- [ ] Ignore any `NtpServer` entry still displayed. NT5DS does not use it. What matters is `Type` and the source.

> This is the check that catches a missing or unlinked `Time - Non-PDC DCs - NT5DS` GPO. If DC01 is still on NTP, fix it now while DC01 is still available.

### 4.6 Validate: the rest of the environment

```powershell
w32tm /monitor
```

- [ ] Both DCs show small offsets
- [ ] A member server shows a DC as its source (`w32tm /query /source`)
- [ ] A workstation shows a DC as its source
- [ ] Event Viewer: System log has no recent `W32Time` errors on either DC. Event ID 36 (no sync for an extended period), 47 (no valid response from a manual peer), 129 (domain peer discovery error), and 134 (manual peer DNS resolution error) are the ones to look for. Event IDs 35 and 37 indicate valid time data is being received.

### 4.7 Update dependent devices

- [ ] Devices listed in Section 2.7 updated to point to the new DC (or to the same upstream source as the PDC)
- [ ] DNS and DHCP-delivered NTP options updated if used
- [ ] Verified at least one appliance is syncing from the new source

---

## 5. Procedure: Retire the Old DC (Demotion Gate)

> **Do not demote DC01 until every box in Sections 4.4 to 4.7 is checked.** If DC01 is not back on NT5DS, or DC02 is not syncing from the upstream source, you have found the problem while it is still easy to fix.

### 5.1 Soak period

- [ ] Let the new configuration run for the period agreed in the ticket (a full business day is a reasonable minimum)
- [ ] Re-run Sections 4.4 and 4.5 after the soak

### 5.2 Other decommission checks (non-time)

Out of scope for this runbook but required before demotion:

- [ ] DHCP scopes, DNS client settings, and forwarders no longer point only at DC01
- [ ] DC02 is a global catalog and DNS server with replicated zones
- [ ] Services, shares, and scripts that reference DC01 by name or IP are updated
- [ ] No FSMO roles remain on DC01 (`netdom query fsmo`)

### 5.3 Demote

Demote with Server Manager or `Uninstall-ADDSDomainController`, then remove DC01 from the domain and decommission.

### 5.4 Post-demotion validation

```powershell
netdom query fsmo
dcdiag /v
w32tm /query /source        # on DC02
w32tm /monitor
```

- [ ] DC02 is the PDC emulator and syncing from the approved source
- [ ] No references to DC01 remain in AD metadata, DNS, or the firewall NTP rules (remove DC01's firewall NTP allowance as cleanup)
- [ ] Client documentation updated: new PDC holder, DC names, date

---

## 6. Procedure: Emergency Seizure (Old DC Lost)

Use only when the PDC holder has failed and **will not return**. Seizure is a last resort. Never bring the old DC back online afterward.

### 6.1 Seize the role

```powershell
Move-ADDirectoryServerOperationMasterRole -Identity "DC02" -OperationMasterRole PDCEmulator -Force
```

Use the short name for `-Identity`. Seize any other roles held by the failed DC the same way, then complete metadata cleanup of the failed DC.

### 6.2 Time-specific steps

- [ ] Run Section 4.3 on DC02, then validate with Section 4.4
- [ ] Confirm the firewall allows UDP 123 from DC02 (Section 2.4). The failed DC's firewall rule will not help.
- [ ] Restore any remaining DC to NT5DS via GPO 2 (Section 4.5)
- [ ] Update dependent devices (Section 4.7)

---

## 7. Rollback

### 7.1 Role transfer problems before demotion

If the new PDC cannot reach upstream NTP or shows the wrong source, and cannot be fixed quickly:

1. Transfer the PDC emulator role **back** to the old DC (Section 4.2 with the DCs reversed).
2. Run Section 4.3 on both servers.
3. Re-validate with Section 4.4 and 4.5 (roles reversed).
4. Fix the cause (firewall, SYSVOL, virtualization sync), then retry.

### 7.2 After demotion

Rollback is not possible by role transfer. Use the baseline companion Section 6 (manual `w32tm` configuration) on DC02 to restore service, then correct the GPO or firewall issue. Reverse any manual `/reliable:yes` or `/manualpeerlist` setting afterwards (see the cleanup note in the baseline companion Section 6), since those are local values that do not follow the role.

---

## 8. Troubleshooting

| Symptom | Likely cause | What to check |
|---|---|---|
| New PDC has no NTP source after transfer | UDP 123 blocked for the new DC | Firewall rule for DC02's IP (Section 2.4); `w32tm /stripchart` from DC02 |
| New PDC shows `Local CMOS Clock` | GPO 1 not applied | `gpresult /r /scope computer` on DC02; confirm `DomainRole = 5` and SYSVOL replication |
| New PDC shows `VM IC Time Synchronization Provider` | Hypervisor sync overriding | Disable the integration service (Section 2.5) |
| Old PDC still on NTP after transfer | GPO 2 missing, not linked, or not refreshed | Confirm GPO 2 exists and is linked; `DomainRole` returns `4`; `gpupdate /force` |
| Old PDC still shows `Type: NTP` or a manual source | Leftover local config, GPO 2 not applying | `w32tm /query /configuration`; confirm GPO 2 applied and `Type` is `NT5DS` |
| GPO missing on new DC | SYSVOL not replicated | `dcdiag /test:sysvolcheck`, `dfsrmig /getglobalstate`, check Policies folder |
| Role change not picked up | Policy refresh timing | `gpupdate /force`, `w32tm /config /update`, `w32tm /resync /rediscover` |
| Appliances drifted after DC01 retired | Static NTP pointing at DC01 | Section 2.7 inventory and Section 4.7 update |
| Time correct on DCs but wrong on workstations | Workstation source or GPO conflict | `w32tm /query /source` on a workstation, `gpresult` for conflicting time GPOs |

---

## 9. Completion Checklist

- [ ] Section 2 pre-checks completed and recorded
- [ ] New DC applied the correct time GPO for its role
- [ ] PDC emulator role transferred (or confirmed unchanged)
- [ ] New PDC syncing from the approved NTP source
- [ ] Old DC returned to NT5DS before demotion
- [ ] Dependent devices updated
- [ ] Old DC retired and firewall rules cleaned up (if replacing)
- [ ] Client documentation updated with the new DC names, PDC holder, and date
- [ ] Ticket closed with validation output attached (`w32tm` source and configuration from both DCs)

---

## Appendix A: Quick Command Reference

| Task | Command |
|---|---|
| Find FSMO holders | `netdom query fsmo` |
| Check a DC's role | `(Get-CimInstance Win32_ComputerSystem).DomainRole` (4 = DC, 5 = PDC emulator) |
| Transfer PDC role | `Move-ADDirectoryServerOperationMasterRole -Identity "DC02" -OperationMasterRole PDCEmulator` |
| Seize PDC role | Same command with `-Force` (last resort) |
| Policy applied? | `gpresult /r /scope computer` |
| Force policy refresh | `gpupdate /force` |
| Re-read time config | `w32tm /config /update` |
| Re-find time source | `w32tm /resync /rediscover` |
| Current source | `w32tm /query /source` |
| Effective config | `w32tm /query /configuration` |
| Detailed status | `w32tm /query /status /verbose` |
| Compare DCs | `w32tm /monitor` |
| Test an NTP server | `w32tm /stripchart /computer:<server> /samples:5 /dataonly` |
| Replication health | `repadmin /replsummary` |
| SYSVOL health | `dcdiag /test:sysvolcheck`, `dfsrmig /getglobalstate` |

## Sources

- [Windows Time tools and settings](https://learn.microsoft.com/en-us/windows-server/networking/windows-time-service/windows-time-service-tools-and-settings)
- [How Windows Time works](https://learn.microsoft.com/en-us/windows-server/networking/windows-time-service/how-the-windows-time-service-works)
- [Configure an authoritative time server](https://learn.microsoft.com/en-us/troubleshoot/windows-server/active-directory/configure-authoritative-time-server)
- [Virtualized domain controllers on Hyper-V](https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/get-started/virtual-dc/virtualized-domain-controllers-hyper-v)
- [Win32_ComputerSystem DomainRole](https://learn.microsoft.com/en-us/windows/win32/cimwin32prov/win32-computersystem)
- [Move-ADDirectoryServerOperationMasterRole](https://learn.microsoft.com/en-us/powershell/module/activedirectory/move-addirectoryserveroperationmasterrole?view=windowsserver2025-ps)
