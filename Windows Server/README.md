# Windows Server

This folder contains reference guides for on-premises Windows Server roles that sit underneath a Microsoft 365 tenant — Active Directory Domain Services, DNS, and the infrastructure that hybrid identity depends on.

---

## Active Directory

### [AD Replication (PDF)](./Active%20Directory/AD%20Replication.pdf)

A one-page visual reference explaining Active Directory replication: KCC and ISTG topology, directory partitions, SYSVOL replication through DFSR, USNs, intra-site and inter-site timing, the notify-then-pull sequence, and ports used between domain controllers.

**Inter-site timing caveat:** The PDF's statement that nothing moves across sites until the schedule opens describes default scheduled replication. Inter-site change notification can be enabled on site links; verify the actual site-link options and schedules in each customer environment. See Microsoft's [Set-ADReplicationSiteLink documentation, Example 4](https://learn.microsoft.com/en-us/powershell/module/activedirectory/set-adreplicationsitelink?view=windowsserver2025-ps#example-4-enable-change-notification-for-a-replication-site-link).

### [Active Directory Windows Time Baseline Runbook](./Active%20Directory/Active%20Directory%20Windows%20Time%20Baseline%20Runbook.md)

First in the paired workflow: assess and deploy role-aware GPOs for upstream NTP on the PDC emulator and NT5DS on other DCs and members. Includes firewall, virtualization, verification, and rollback checks.

### [Active Directory Windows Time DC Change Runbook](./Active%20Directory/Active%20Directory%20Windows%20Time%20DC%20Change%20Runbook.md)

Use after the baseline for time validation during DC additions, PDC transfers, and replacements. Covers pre-checks, policy convergence, dependent appliances, demotion gates, rollback, and emergency recovery handoff.

### [Active Directory PDC Windows Time Repair Runbook](./Active%20Directory/Active%20Directory%20PDC%20Windows%20Time%20Repair%20Runbook.md)

Repair companion for an incorrect forest-root PDC time source. Covers Hyper-V integration, policy versus local configuration, approved upstream NTP, downstream verification, and rollback.

### [Active Directory FSMO Recovery Guide](./Active%20Directory/Active%20Directory%20FSMO%20Recovery%20Guide.md)

An 11-phase runbook for recovering a domain when a domain controller holding FSMO roles is permanently lost and no usable backup exists. Covers isolating the dead DC so it can never rejoin, verifying SYSVOL/NETLOGON and replication health on the survivors before touching anything, temporarily elevating to Enterprise/Schema Admins, and seizing all five roles with `Move-ADDirectoryServerOperationMasterRole -Force`. Continues through metadata cleanup in ADUC and Sites and Services, stale DNS record removal, repairing a malformed `_msdcs` delegation (the "missing glue A record" error) with `Add-DnsServerZoneDelegation`, correcting DNS client settings and every downstream system still pointing at the dead IP, and re-establishing the time hierarchy on the new PDC Emulator against external NTP. Ends with a full `dcdiag`/`repadmin` validation pass, removal of the temporary privileged memberships, and guidance on building a clean replacement DC. Uses a fictional three-DC `example.local` environment throughout.
