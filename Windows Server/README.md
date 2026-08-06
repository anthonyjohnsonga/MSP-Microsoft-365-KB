# Windows Server

This folder contains reference guides for on-premises Windows Server roles that sit underneath a Microsoft 365 tenant — Active Directory Domain Services, DNS, and the infrastructure that hybrid identity depends on.

---

## Active Directory

### [Active Directory FSMO Recovery Guide](./Active%20Directory/Active%20Directory%20FSMO%20Recovery%20Guide.md)

An 11-phase runbook for recovering a domain when a domain controller holding FSMO roles is permanently lost and no usable backup exists. Covers isolating the dead DC so it can never rejoin, verifying SYSVOL/NETLOGON and replication health on the survivors before touching anything, temporarily elevating to Enterprise/Schema Admins, and seizing all five roles with `Move-ADDirectoryServerOperationMasterRole -Force`. Continues through metadata cleanup in ADUC and Sites and Services, stale DNS record removal, repairing a malformed `_msdcs` delegation (the "missing glue A record" error) with `Add-DnsServerZoneDelegation`, correcting DNS client settings and every downstream system still pointing at the dead IP, and re-establishing the time hierarchy on the new PDC Emulator against external NTP. Ends with a full `dcdiag`/`repadmin` validation pass, removal of the temporary privileged memberships, and guidance on building a clean replacement DC. Uses a fictional three-DC `example.local` environment throughout.
