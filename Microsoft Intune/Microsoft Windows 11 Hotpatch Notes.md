# Windows 11 Hotpatch

Reference Notes

---

## Overview

Windows 11 Hotpatch allows quality updates to be applied to devices without requiring a reboot. Updates are applied in-memory, reducing disruption to end users. This capability is available on qualifying devices running Windows 11 24H2 or later.

---

## Quality Updates

Quality updates keep devices secure and stable without changing the Windows version. They are released on the second Tuesday of each month — commonly known as Patch Tuesday — and are cumulative, meaning each release contains all previous fixes.

**What quality updates include:**
- Security patches — fixes for vulnerabilities in Windows and its components
- Cumulative updates — all previous fixes rolled into a single package
- Driver updates — hardware compatibility and stability improvements
- .NET Framework updates — runtime and security fixes for .NET

**What quality updates do not include:**
- Feature updates — major Windows version upgrades (e.g. 23H2 to 24H2) are managed separately under a Feature Update policy in Intune

Within the hotpatch model, quality updates are split into two types:
- **Baseline updates** (January, April, July, October) — require a reboot
- **Hotpatch updates** (all remaining months) — apply rebootlessly

> A device must have the current baseline installed before hotpatch updates for that quarter will apply.

---

## Device Prerequisites

A device must meet **all** of the following requirements before hotpatch updates will apply:

- Running Windows 11 24H2 (minimum required version)
- Latest baseline (quarterly) update installed
- Virtualization Based Security (VBS) enabled
- Memory Integrity (HVCI) enabled

> **Note:** Enabling VBS/Memory Integrity for the first time requires a one-time reboot. After that, it persists and does not affect subsequent hotpatch months.

---

## Annual Update Schedule

| Month | Type | Month | Type | Month | Type |
|-------|------|-------|------|-------|------|
| **Jan** | Baseline (reboot required) | **Feb** | Hotpatch (rebootless) | **Mar** | Hotpatch (rebootless) |
| **Apr** | Baseline (reboot required) | **May** | Hotpatch (rebootless) | **Jun** | Hotpatch (rebootless) |
| **Jul** | Baseline (reboot required) | **Aug** | Hotpatch (rebootless) | **Sep** | Hotpatch (rebootless) |
| **Oct** | Baseline (reboot required) | **Nov** | Hotpatch (rebootless) | **Dec** | Hotpatch (rebootless) |

**4 baseline months per year — 8 hotpatch months per year**

---

## Intune Configuration

Two policies are required to enable hotpatch on managed devices: one to enforce the VBS security requirement, and one to configure Windows Update for Business to deliver quality updates.

### Policy 1 — Enable Virtualization Based Security (VBS)

**Navigation path:**

1. Intune Admin Center
2. Devices > Windows > Configuration
3. Policies > Create new policy
4. Platform: `Windows 10 and later`
5. Profile: `Settings Catalog`
6. Name the policy — e.g. `Win - OIB - SC - Virtualization Based Security - E - v1.0`
7. Add setting: **Virtualization Based Technology**
8. Enable: **Hypervisor Protected Code Integrity** — select `Enable without UEFI lock`

> **Important:** Use `Enable without UEFI lock` — UEFI lock makes the setting irreversible without physical access, which prevents remote troubleshooting and reimaging.

---

### Policy 2 — Windows Quality Update Policy

**Navigation path:**

1. Intune Admin Center
2. Manage Updates > Windows Updates
3. Quality Updates > Create
4. Select: **Windows Quality Update Policy**
5. Name the policy — e.g. `Win - OIB - WUfB - Quality Updates - E - v1.0`
6. Setting: **Allow Quality Updates**
7. Enable **Windows Data Processing** (off by default — must be manually enabled)
8. Assign groups > Review and Create

> **Windows Data Processing:** Enabling this grants Microsoft access to additional Windows Update diagnostic data to improve update targeting and reliability. Review client compliance requirements before enabling — some regulated industries (healthcare, finance, defense contractors) may have restrictions.
