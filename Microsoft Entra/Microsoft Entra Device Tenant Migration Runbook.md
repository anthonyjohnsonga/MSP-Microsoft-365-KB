# Entra ID Device Tenant-to-Tenant Migration Runbook

**Applies to:** Microsoft Entra ID (device join), Microsoft Intune  
**Scope:** Moving a single Entra ID (Azure AD) joined Windows device from one tenant (**Company A**) to another (**Company B**), landing it under Company B's Intune management. Covers cloud-only Entra-joined devices; hybrid (on-prem AD) devices need the extra safeguard called out at the end.  
**Last Updated:** July 2026

---

## Overview

When a client is acquired, rebranded, or split off, their existing Windows devices are still joined to the old tenant and managed by the old tenant's Intune. You can't just sign in with the new tenant's account — the stale Entra join, MDM enrollment, and any Autopilot registration will fight you. This runbook is the clean cutover sequence: strip Company A first, leave the join cleanly on the machine, then join and enroll into Company B, with verification at each step.

**MSP note:** Do this per-device and confirm each `dsregcmd /status` before moving on. Rushing the source-tenant removal is what leaves stale device objects and Autopilot re-provisioning surprises months later.

---

## 1. Source Tenant (Company A) — Clean Removal First

- Intune (Company A) → **Devices** → select machine → **Retire** (preserves the user profile/local data, strips MDM management and company data/apps tied to Company A).
- Wait for retire to complete, then delete the device object from **Entra ID (Company A)** so it doesn't leave a stale registration.
- If the device has any Company A Conditional Access / Compliance dependencies, confirm those won't block sign-in elsewhere before you pull the plug.

---

## 2. On the Machine

- Sign out of the Company A work account.
- Elevated command prompt:

```cmd
dsregcmd /leave
```

  This clears the Entra join state cleanly (**Settings > Accounts > Disconnect** alone is unreliable).
- Reboot, then confirm the join is gone:

```cmd
dsregcmd /status
```

  Look for `AzureAdJoined : NO`.

---

## 3. Target Tenant (Company B) — Join and Enroll

- **Settings > Accounts > Access work or school > Join this device to Microsoft Entra ID**, sign in with the Company B account.
- Reboot, verify `dsregcmd /status` shows `AzureAdJoined : YES` with Company B's `TenantId`.
- If auto-enrollment is on for Company B, Intune enrollment should trigger automatically — confirm the device lands in Company B's Intune and picks up the right baseline / Conditional Access policies.

---

## 4. Autopilot Check

- If this machine was Autopilot-registered under Company A (or Company A's associated partner/reseller), **deregister it there first**. Otherwise it'll try to re-provision against the old tenant during any future OOBE/reset.

---

## 5. User Data / Profile

- The local profile isn't migrated automatically — the user gets a fresh profile on first Company B sign-in unless you use a profile migration tool.
- If OneDrive was syncing under Company A, pause sync and note the folder path before cutover, then reconfigure OneDrive under Company B post-join.

---

## Verification / Testing Checklist

- [ ] Device shows **Retired** and is deleted from Company A's Entra ID.
- [ ] `dsregcmd /status` → `AzureAdJoined : NO` after `dsregcmd /leave` and reboot.
- [ ] `dsregcmd /status` → `AzureAdJoined : YES` with Company B's `TenantId`.
- [ ] Device appears in Company B's Intune and shows compliant / policies applied.
- [ ] Autopilot registration under Company A is removed (no old-tenant re-provisioning).
- [ ] OneDrive reconfigured and syncing under the Company B account.

---

## Open Question Before Execution

Confirm whether this machine is **also on-prem AD-joined (hybrid)** or purely cloud Entra-joined. If hybrid, the sequence needs an extra safeguard so `dsregcmd /leave` doesn't disturb the local domain trust — leave the on-prem domain separately and coordinate with the source tenant's Entra Connect / Cloud Sync before running the leave.

---

## Sources

- Microsoft Learn: [dsregcmd command](https://learn.microsoft.com/en-us/entra/identity/devices/troubleshoot-device-dsregcmd)
- Microsoft Learn: [Remove devices by using wipe, retire, or manually unenrolling](https://learn.microsoft.com/en-us/mem/intune/remote-actions/devices-wipe)
- Microsoft Learn: [Deregister a device from Windows Autopilot](https://learn.microsoft.com/en-us/autopilot/registration-overview)
