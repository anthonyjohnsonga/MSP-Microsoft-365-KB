# Active Directory PDC Windows Time Repair Runbook

**Applies to:** Windows Server 2016 and later AD DS; on-premises Hyper-V virtual domain controllers and domain-joined Windows members.

**Scope:** Repair an incorrect time source on the forest-root PDC emulator, then verify the domain time hierarchy. Cloud-hosted DCs require provider-specific guidance.

**Last Updated:** October 6, 2026

Use this when the forest-root PDC emulator reports `VM IC Time Synchronization Provider`, `Local CMOS Clock`, or an unapproved upstream source. For lasting role-aware policy, use the [Windows Time Baseline Runbook](./Active%20Directory%20Windows%20Time%20Baseline%20Runbook.md). For a PDC role transfer or DC replacement, use the [DC Change Runbook](./Active%20Directory%20Windows%20Time%20DC%20Change%20Runbook.md).

## 1. Prerequisites and Capture

- Run commands in elevated PowerShell on the indicated machine. Use administrative rights on the DC and Hyper-V host, and delegated Group Policy edit rights if policy controls time.
- Have the Active Directory PowerShell module available for discovery; `netdom query fsmo` is an alternative for the current domain only.
- Agree on upstream NTP sources and the change window. Large corrections can affect authentication and application workloads.
- Allow DNS resolution and W32Time traffic to approved upstream sources: **UDP 123 source and destination**. Allow inbound UDP 123 on DCs from domain clients as required by the time hierarchy.
- No Microsoft 365 add-on license is required; normal Windows Server licensing applies.

On the affected DC, save the following output in the private change record:

```powershell
w32tm /query /source
w32tm /query /configuration
w32tm /query /status /verbose
w32tm /query /peers
gpresult /r /scope computer
reg query HKLM\SYSTEM\CurrentControlSet\Services\W32Time\TimeProviders\VMICTimeProvider /v Enabled
```

Record the current Hyper-V integration-service state and back up any GPO you will edit. Capture `Type`, `NtpServer`, `AnnounceFlags`, and provider settings from the effective configuration for rollback.

**MSP note:** Check each customer forest separately. Keep customer names, server names, addresses, and diagnostic output in private documentation.

## 2. Identify the Forest-Root PDC and Policy Owner

Run from a domain-joined administration machine with the AD module:

```powershell
$rootDomain = (Get-ADForest).RootDomain
Get-ADDomain -Identity $rootDomain | Select-Object DNSRoot, PDCEmulator
```

Confirm you are connected to that PDC before changing upstream NTP. In a multi-domain forest, child-domain PDCs normally follow the domain hierarchy; do not apply the external-NTP procedure to every PDC.

Review `w32tm /query /configuration` and the applied GPO report. If time settings show `(Policy)`, repair the controlling GPO under **Computer Configuration > Policies > Administrative Templates > System > Windows Time Service > Time Providers** using the baseline runbook. Local `w32tm /config` commands cannot override policy. Resolve competing policies or management scripts first.

## 3. Remove Hyper-V Host Time as the DC Source

For an on-premises Hyper-V DC, use **Hyper-V Manager > VM Settings > Integration Services > Time Synchronization**. Microsoft documents shutting down the VM before disabling this setting; schedule the interruption, clear the checkbox, and start the VM.

Review the setting for other virtual DCs as well, because the PDC role can move. Follow the hypervisor vendor's guidance for other platforms and provider-specific guidance for Azure.

After startup, query the source again. If the guest still selects the VM provider, first confirm the correct VM integration service was disabled. If disabling the guest provider is also required by the approved virtualization design, record its previous value and run on that DC:

```powershell
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\TimeProviders\VMICTimeProvider' -Name Enabled -Value 0
Restart-Service w32time
```

A standalone Hyper-V host should have its own approved upstream time configuration. A domain-joined host normally follows the domain hierarchy. Avoid a circular dependency in which the PDC takes time from a host that takes time from that PDC.

## 4. Restore Approved Upstream NTP

**Policy-managed PDC:** Correct the winning policy, then run on the PDC:

```powershell
gpupdate /target:computer /force
Restart-Service w32time
w32tm /resync /rediscover
```

**Locally managed PDC:** Use the following only after confirming policy does not control these settings. Replace all fictional peers with approved, reachable sources before running:

```powershell
w32tm /config /manualpeerlist:"ntp1.example.net,0x8 ntp2.example.net,0x8 ntp3.example.net,0x8" /syncfromflags:manual /reliable:yes /update
Restart-Service w32time
w32tm /resync /rediscover
```

`0x8` selects NTP client mode. Microsoft recommends three or more peers for Windows Server 2016 and later; with only two, configure one as fallback (`0xA`, combining client mode and UseAsFallbackOnly). Test each approved peer:

```powershell
w32tm /stripchart /computer:ntp1.example.net /samples:5 /dataonly
```

Stripchart uses an ephemeral UDP source port, so a response alone does not prove that W32Time service traffic is allowed. Confirm service resynchronization and firewall logs.

Review the effective NTP server provider and `AnnounceFlags` against the approved baseline. `/reliable:yes` is a local setting that does not follow the FSMO role. Microsoft documents situations where `AnnounceFlags` should be `0xA` rather than `0x5`, including unreliable upstream connectivity and fixed SpecialPollInterval polling. Do not assume advertising reliability proves synchronization health.

## 5. Verify the PDC and Downstream Members

On the PDC:

```powershell
w32tm /query /source
w32tm /query /configuration
w32tm /query /status /verbose
w32tm /query /peers
w32tm /monitor
```

Verify the PDC first. On other DCs and representative domain members, check source, effective configuration, and status. If a machine has an incorrect local manual configuration and policy does not control it, restore the hierarchy:

```powershell
w32tm /config /syncfromflags:DOMHIER /update
Restart-Service w32time
w32tm /resync /rediscover
```

For a former PDC or another DC incorrectly marked reliable, also run `w32tm /config /reliable:no /update` and verify the effective configuration. For policy-managed machines, repair the appropriate NT5DS policy instead.

### Verification Checklist

- [ ] Forest-root PDC source is an approved upstream NTP source.
- [ ] PDC effective configuration shows `Type: NTP` and the intended peers.
- [ ] Status shows a recent successful synchronization, acceptable offset for the customer's requirements, and no unsynchronized leap indicator (`3`). Leap indicator `0` is typical; it alone does not prove health.
- [ ] Other DCs and sampled domain members show `Type: NT5DS` and a healthy domain source; trace the chain to the forest-root PDC.
- [ ] The PDC no longer selects the VM provider or a free-running/local clock.
- [ ] Recheck after policy refresh and a suitable observation period; inspect **Event Viewer > Windows Logs > System** for Time-Service errors.
- [ ] Record the final configuration and follow up with the role-aware baseline so a future PDC transfer does not leave stale manual settings.

## 6. Troubleshooting and Rollback

| Symptom | Action |
|---|---|
| No time data available | Check peer DNS, UDP 123 service traffic, peer availability, and Time-Service events. |
| Settings revert | Identify the winning GPO or management script; repair its configuration. |
| VM provider remains selected | Confirm the VM identity, integration-service state, and guest provider state. |
| Service runs but source is a local clock | Check recent successful sync and offset; a running service is insufficient. |
| Large correction is rejected | Review effective phase-correction limits and events. Plan recovery for the measured offset; do not remove limits blindly. |

If the repair fails:

1. Restore the known-good GPO backup or the recorded local peer list, synchronization type, reliability, and provider settings. Disabling a GPO link alone may not restore earlier local values.
2. Restore the recorded Hyper-V integration and guest-provider state if those changes must be reverted; use the approved VM shutdown/start procedure when required.
3. Refresh policy where applicable, restart W32Time, resynchronize, and repeat Section 5. Restoring the original broken configuration is not successful recovery; escalate if no known-good source is available.
4. If the PDC role moved during recovery, return the former holder to the approved NT5DS configuration and remove stale local reliability settings. Follow the DC Change Runbook before further role changes.

**Validation status:** Commands reviewed against Microsoft documentation; execution in a customer tenant or AD DS lab is still required before adopting this as a tested customer procedure.

## Sources

- Microsoft Learn: [How the Windows Time Service works](https://learn.microsoft.com/en-us/windows-server/networking/windows-time-service/how-the-windows-time-service-works)
- Microsoft Learn: [Windows Time Service tools and settings](https://learn.microsoft.com/en-us/windows-server/networking/windows-time-service/windows-time-service-tools-and-settings)
- Microsoft Learn: [Configure an authoritative time server](https://learn.microsoft.com/en-us/troubleshoot/windows-server/active-directory/configure-authoritative-time-server)
- Microsoft Learn: [Virtualizing domain controllers with Hyper-V](https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/get-started/virtual-dc/virtualized-domain-controllers-hyper-v)
