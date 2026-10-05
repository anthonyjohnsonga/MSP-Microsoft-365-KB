# Active Directory Windows Time Baseline Runbook

**Applies to:** Windows Server AD DS in a single-domain forest and domain-joined Windows members.
**Scope:** Windows Time configuration and validation. Multi-domain forests require a separate design; external NTP normally belongs on the forest-root PDC. This pair supplements an approved AD DS migration plan.
**Last Updated:** October 4, 2026

**Companion:** [Baseline](./Active%20Directory%20Windows%20Time%20Baseline%20Runbook.md) then [DC Change](./Active%20Directory%20Windows%20Time%20DC%20Change%20Runbook.md).

---

## 1. Overview

### 1.1 The problem

The PDC emulator is a **role**, not a permanent server. If upstream NTP is configured manually on the current PDC emulator, that configuration does not follow the role when it moves. The old holder keeps its NTP settings and the new holder has none. The result can be Kerberos failures, trust errors, certificate problems, and misleading event timelines.

### 1.2 The design in one line

Configure the **role**, not the server.

### 1.3 Target time hierarchy

```text
Approved upstream NTP sources
            |
            v
PDC emulator                    <- Type: NTP   (GPO 1)
            |
            v
Other domain controllers        <- Type: NT5DS (GPO 2)
            |
            v
Member servers and workstations <- Type: NT5DS (GPO 3)
```

### 1.4 GPOs in this baseline

| GPO | Name | Linked to | WMI filter | Type |
|---|---|---|---|---|
| 1 | `Time - PDC Emulator - Authoritative NTP` | **Domain Controllers** OU | `DomainRole = 5` | NTP |
| 2 | `Time - Non-PDC DCs - NT5DS` | **Domain Controllers** OU | `DomainRole = 4` | NT5DS |
| 3 | `Time - Member Servers - NT5DS` | Member server OU(s) | None | NT5DS |

### 1.5 Single-DC clients (most MSP environments)

With one DC, that server is the PDC emulator and always evaluates as `DomainRole = 5`.

- **GPO 1 applies** and is the only one doing work today.
- **GPO 2 never applies** until a second DC exists.
- **Build both anyway.** When a second DC is added or the DC is replaced, the time configuration follows the role with no extra work. See the DC change companion.

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

## 2. Prerequisites

- [ ] Domain Admin (or delegated Group Policy create/link rights) in the target domain
- [ ] GPMC and the Active Directory PowerShell module available (RSAT or run on a DC)
- [ ] Approved upstream NTP sources agreed with the client (see 3.3)
- [ ] Change approval / maintenance window recorded in the ticket
- [ ] Current state documented (Section 3)

> **Time impact:** Applying these GPOs changes the NTP config on the PDC emulator. A mistake can cause time drift, so make the change in business hours with a plan to verify, not at 5 PM on Friday.

---

## 3. Assessment

### 3.1 Environment facts

Record these in the ticket or client documentation.

| Item | Value |
|---|---|
| Domain name | |
| Number of DCs | |
| PDC emulator holder | |
| DCs physical or virtual? Hypervisor? | |
| Existing GPOs configuring Windows Time | |
| Approved NTP sources | |

### 3.2 Discovery commands

**Identify the DCs**

```powershell
Get-ADDomainController -Filter * | Select-Object Name, HostName, Site, IPv4Address, OperatingSystem
```

**Identify the PDC emulator**

```powershell
Get-ADDomain | Select-Object PDCEmulator
# or
netdom query fsmo
```

**Check the current time source and config on each DC**

```powershell
w32tm /query /source
w32tm /query /configuration
reg query HKLM\SYSTEM\CurrentControlSet\Services\W32Time\Parameters /v Type
reg query HKLM\SYSTEM\CurrentControlSet\Services\W32Time\Parameters /v NtpServer
```

**Find existing GPOs that configure Windows Time**

```powershell
Get-GPO -All | ForEach-Object {
    $xml = Get-GPOReport -Guid $_.Id -ReportType Xml
    if ($xml -match 'Windows Time Service' -or $xml -match 'W32Time') {
        [pscustomobject]@{ GPO = $_.DisplayName; Id = $_.Id }
    }
}
```

Review each hit. Existing time GPOs must be removed, merged into this design, or explicitly scoped so they do not conflict.

### 3.3 Choose upstream NTP sources

Agree on sources with the client. Common choices:

- The firewall or a network time appliance already syncing to a trusted source
- A public pool or vendor source (for example `pool.ntp.org` or `time.windows.com`), using several names for redundancy
- A GPS-based or internal stratum source for regulated environments

Microsoft recommends three or more peers for Windows Server 2016 and later. Replace these fictional peers with approved sources. If only two peers are available, configure one as fallback with UseAsFallbackOnly (0x2).

### 3.4 Check network connectivity to the NTP sources

From the PDC emulator:

```powershell
w32tm /stripchart /computer:ntp1.example.net /samples:5 /dataonly
```

- [ ] Responses returned from each NTP source
- [ ] Outbound **UDP 123** allowed from the PDC emulator (and every DC that could hold the role)

### 3.5 Check virtualization time sync

If a DC is a VM, host time sync can fight W32Time.

- [ ] Hyper-V: check **Time synchronization** under Integration Services for the DC VM
- [ ] VMware: check **Synchronize guest time with host** in VM options and VMware Tools
- [ ] Host time sync **disabled for every DC VM**, not only the current PDC emulator. The PDC role can move, and Microsoft guidance is for virtual DCs to use the domain time hierarchy rather than the host clock.
- [ ] Hyper-V PowerShell (optional): `Get-VMIntegrationService -VMName "DC01" -Name "Time Synchronization"` to check, `Disable-VMIntegrationService -VMName "DC01" -Name "Time Synchronization"` to disable
- [ ] After the change, `w32tm /query /source` on the PDC does **not** show `VM IC Time Synchronization Provider`

> This is one of the most common real-world causes of drift on small-client DCs.

---

## 4. Build

### 4.1 Create the WMI filters

In **GPMC > Forest > Domains > _your domain_ > WMI Filters**, create two filters. Namespace: `root\CIMv2`.

| Filter name | Query |
|---|---|
| `DomainRole - PDC Emulator` | `SELECT * FROM Win32_ComputerSystem WHERE DomainRole = 5` |
| `DomainRole - Non-PDC DC` | `SELECT * FROM Win32_ComputerSystem WHERE DomainRole = 4` |

Reference values: `4` = backup domain controller, `5` = primary domain controller (PDC emulator).

**Verify on each DC:**

```powershell
(Get-CimInstance Win32_ComputerSystem).DomainRole
```

- [ ] The PDC emulator returns `5`
- [ ] All other DCs return `4`

### 4.2 GPO 1: PDC emulator (authoritative NTP)

1. Create GPO **`Time - PDC Emulator - Authoritative NTP`**.
2. **Link it only to the Domain Controllers OU.**
3. Set **WMI Filtering** to `DomainRole - PDC Emulator`.
4. Edit the GPO: **Computer Configuration > Policies > Administrative Templates > System > Windows Time Service > Time Providers**.

| Setting | State | Values |
|---|---|---|
| Enable Windows NTP Client | Enabled | |
| Configure Windows NTP Client | Enabled | **Type:** `NTP`. **NtpServer:** `ntp1.example.net,0x8 ntp2.example.net,0x8 ntp3.example.net,0x8` (replace with approved sources, space-separated) |
| Enable Windows NTP Server | Enabled | |

> **Scoping note:** Link this GPO to the Domain Controllers OU only. Do not also link it at the domain root. The WMI filter would still limit it to the PDC emulator, but a single, obvious link keeps the design easy to audit.

> **Flag note:** 0x8 selects client mode with adaptive polling. 0x9 adds SpecialInterval; review SpecialPollInterval and authoritative-server guidance before choosing it.

### 4.3 GPO 2: Non-PDC DCs (NT5DS)

1. Create GPO **`Time - Non-PDC DCs - NT5DS`**.
2. Link it to the **same** Domain Controllers OU.
3. Set **WMI Filtering** to `DomainRole - Non-PDC DC`.
4. Edit the GPO under the same path as above.

| Setting | State | Values |
|---|---|---|
| Enable Windows NTP Client | Enabled | |
| Configure Windows NTP Client | Enabled | **Type:** `NT5DS` |

**Why this GPO matters:** after a PDC role transfer, GPO 1 gives the new holder its NTP config. GPO 2 returns the **old** holder to NT5DS. Without it, the old holder keeps its outdated NTP settings.

> In a single-DC environment, create this GPO anyway. It does nothing until a second DC exists.

### 4.4 GPO 3: Member servers (NT5DS)

Recommended. Corrects historical manual peer lists, standardizes new builds, and makes intended state visible in GP reporting.

1. Create GPO **`Time - Member Servers - NT5DS`**.
2. Link it to the member server OU(s). **Do not link it to the Domain Controllers OU.** Do not link at the domain root unless you have confirmed what else is under it.
3. Configure:

| Setting | State | Values |
|---|---|---|
| Enable Windows NTP Client | Enabled | |
| Configure Windows NTP Client | Enabled | **Type:** `NT5DS` |

> **Check first:** some servers (for example a server with a hardware time source, or a non-domain appliance VM) may need to be excluded.

### 4.5 Clean up conflicting settings

- [ ] Existing time GPOs from Section 3.2 removed, unlinked, or scoped so they cannot overlap with GPOs 1 to 3
- [ ] Old manual configuration noted (do not rely on it being gone; policy takes precedence when applied)
- [ ] Any competing management agent, script, or local time policy identified and reconciled with this GPO design

### 4.6 Firewall readiness

- [ ] Outbound **UDP 123** from the PDC emulator to the approved NTP sources
- [ ] If the firewall allows NTP **per source IP**, allow every DC that could hold the PDC role, not only today's holder
- [ ] Windows Firewall on DCs allows inbound NTP (the built-in rule `Active Directory Domain Controller - W32Time (NTP-UDP-In)` should be enabled)

> The GPO moves the Windows configuration with the role. It cannot move a firewall rule.

---

## 5. Apply and Validate

### 5.1 Apply policy

On the PDC emulator, then each other DC:

```powershell
gpupdate /force
Restart-Service w32time        # only if your change procedure allows it
w32tm /config /update
w32tm /resync /rediscover
```

### 5.2 Validate on the PDC emulator

```powershell
w32tm /query /source
w32tm /query /configuration
w32tm /query /status /verbose
w32tm /query /peers
```

**Expected:**

- [ ] Source is one of the approved NTP servers (not `Local CMOS Clock`, not `Free-running System Clock`, not `VM IC Time Synchronization Provider`)
- [ ] Configuration shows `Type: NTP` and your NtpServer list, marked as coming from policy
- [ ] `NtpServer` provider enabled
- [ ] Status shows a recent successful sync and a small offset

### 5.3 Validate on other DCs (if present)

- [ ] `w32tm /query /source` returns a healthy DC in the NT5DS hierarchy; trace its upstream chain to the PDC and approved NTP source
- [ ] `w32tm /query /configuration` shows `Type: NT5DS`

### 5.4 Validate on a member server and a workstation

- [ ] `w32tm /query /source` returns a domain controller
- [ ] `gpresult /h "$env:TEMP\TimePolicy.html"` shows the expected time GPO (servers) applied

### 5.5 Check the clocks agree

```powershell
w32tm /monitor
```

- [ ] Offsets between DCs are small (well under a second)

### 5.6 Record the result

- [ ] Final state recorded in the ticket and client documentation (PDC holder, NTP sources, GPO names, date)
- [ ] Baseline noted in the client's documentation so the DC change companion can be used for any later DC change

---

## 6. Rollback

If time becomes unstable after the change:

1. **Disable the GPO link** for the GPO you changed (GPO 1 first if the PDC is affected).
2. Run `gpupdate /force` on the affected server.
3. Restore a known good configuration manually if needed:

```powershell
# On the PDC emulator only
w32tm /config /manualpeerlist:"ntp1.example.net,0x8 ntp2.example.net,0x8 ntp3.example.net,0x8" /syncfromflags:manual /reliable:yes /update
Restart-Service w32time
w32tm /resync /rediscover
```

```powershell
# On any other DC or member server
w32tm /config /syncfromflags:domhier /reliable:no /update
Restart-Service w32time
w32tm /resync /rediscover
```

4. Re-validate with Section 5.
5. Document what failed before retrying.

> **Clean up after a manual rollback:** `/reliable:yes` and `/manualpeerlist` set **local** values on that server. They do not follow the PDC role. Once the GPO is working again, reverse them on that server (`w32tm /config /reliable:no /update`, then confirm `Type` and source in Section 5), or a later PDC transfer can leave the old holder with stale settings.

---

## 7. Troubleshooting

| Symptom | Likely cause | What to check |
|---|---|---|
| PDC shows `Local CMOS Clock` or `Free-running System Clock` | No reachable NTP source, or policy not applied | UDP 123 outbound, `w32tm /stripchart`, `gpresult` on the PDC |
| PDC shows `VM IC Time Synchronization Provider` | Hyper-V host time sync overriding | Disable the integration service for the VM (Section 3.5) |
| Policy not applying to the PDC | WMI filter or link scope | Confirm link to the Domain Controllers OU, `DomainRole` returns `5`, GPO shows in `gpresult /r` |
| Old PDC still on NTP after role move | GPO 2 missing, not linked, or not refreshed | Confirm GPO 2 exists and `DomainRole` returns `4` on the old holder, then `gpupdate /force` |
| Other DC using an external or unsynchronized source | GPO 2 not applied, or local manual config | `w32tm /query /configuration`: confirm `Type` is `NT5DS` and GPO 2 applied. An `NtpServer` entry shown under NT5DS is ignored and harmless. |
| Large time offset | Service stopped, wrong source, or firewall | `w32tm /query /status /verbose`, `w32tm /query /peers` |
| Time service running but wrong time | Running service does not prove sync | Check the source and offset, not just the service state |
| Settings keep reverting | Competing GPO | Re-run the GPO search in Section 3.2 and check `gpresult` for the winning GPO |

---

## 8. Common Mistakes

- Configuring NTP manually on the current PDC only
- Creating GPO 1 but not GPO 2
- Allowing UDP 123 only from the current PDC's IP
- Assuming a running W32Time service means time is syncing
- Leaving old manual peer lists or competing GPOs in place
- Ignoring hypervisor time sync on virtual DCs
- Validating the displayed clock rather than the source and offset

---

## Appendix A: Command Reference

| Task | Command |
|---|---|
| Find the PDC emulator | `Get-ADDomain \| Select-Object PDCEmulator` or `netdom query fsmo` |
| Check this machine's role | `(Get-CimInstance Win32_ComputerSystem).DomainRole` |
| Current time source | `w32tm /query /source` |
| Effective configuration | `w32tm /query /configuration` |
| Detailed status | `w32tm /query /status /verbose` |
| Configured peers | `w32tm /query /peers` |
| Compare DCs | `w32tm /monitor` |
| Test an NTP server | `w32tm /stripchart /computer:<server> /samples:5 /dataonly` |
| Refresh policy | `gpupdate /force` |
| Re-read config | `w32tm /config /update` |
| Re-find source | `w32tm /resync /rediscover` |
| GPO report | `gpresult /h "$env:TEMP\TimePolicy.html"` |

## Sources

- [Windows Time tools and settings](https://learn.microsoft.com/en-us/windows-server/networking/windows-time-service/windows-time-service-tools-and-settings)
- [How Windows Time works](https://learn.microsoft.com/en-us/windows-server/networking/windows-time-service/how-the-windows-time-service-works)
- [Configure an authoritative time server](https://learn.microsoft.com/en-us/troubleshoot/windows-server/active-directory/configure-authoritative-time-server)
- [Virtualized domain controllers on Hyper-V](https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/get-started/virtual-dc/virtualized-domain-controllers-hyper-v)
- [Win32_ComputerSystem DomainRole](https://learn.microsoft.com/en-us/windows/win32/cimwin32prov/win32-computersystem)
- [Move-ADDirectoryServerOperationMasterRole](https://learn.microsoft.com/en-us/powershell/module/activedirectory/move-addirectoryserveroperationmasterrole?view=windowsserver2025-ps)
