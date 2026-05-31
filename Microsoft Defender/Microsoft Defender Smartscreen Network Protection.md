# Microsoft Defender SmartScreen & Network Protection
### MSP Reference Guide — Web Filtering & Cross-Browser Enforcement

---

## Overview

Microsoft Defender SmartScreen is a cloud-based anti-phishing and anti-malware component built into Windows and Microsoft Edge. It protects users by evaluating URLs, downloaded files, and applications against Microsoft's threat intelligence in real time.

**Key limitation:** SmartScreen is Edge/Windows-native. Users on Chrome or Firefox bypass SmartScreen's URL reputation checks entirely — unless Network Protection is configured at the OS level via Microsoft Defender for Endpoint (MDE).

---

## How SmartScreen Works

SmartScreen hooks into three areas:

- **URLs/Websites** — Compares visited sites against Microsoft's dynamic list of known phishing and malware-hosting pages
- **Downloaded Files** — Checks file reputation (hash, publisher) before execution
- **Apps & Installers** — Flags unrecognized apps that lack reputation history (the "Windows protected your PC" prompt)

SmartScreen sends reputation data to Microsoft's cloud for real-time evaluation. Files or sites with no known reputation history receive a warning even if not definitively malicious — common in MSP environments when deploying niche or custom software.

---

## Browser Coverage Gap

| Browser | SmartScreen | Protection Used |
|---|---|---|
| Microsoft Edge | ✅ Native | SmartScreen |
| Google Chrome | ❌ None | Google Safe Browsing |
| Mozilla Firefox | ❌ None | Google Safe Browsing |

> **Note:** Chrome and Firefox use Google Safe Browsing, which provides comparable phishing/malware URL protection — but you lose Microsoft's threat intel layer and all MDE telemetry integration.

---

## The Solution: Network Protection via MDE

**Network Protection** operates at the Windows kernel level via the Windows Filtering Platform (WFP). It intercepts outbound connections from *any* process — including Chrome and Firefox — before traffic leaves the machine.

### How It Works

1. User types a URL in Chrome
2. Chrome initiates DNS lookup / TCP connection
3. Windows Filtering Platform intercepts the request
4. MDE sensor evaluates it against Web Content Filtering categories and IoC blocks
5. Connection is blocked or allowed — the browser just sees a failed connection

This means browser choice is irrelevant. Enforcement happens at the OS network stack.

### Requirements

- Device must be **onboarded to Microsoft Defender for Endpoint**
- Requires **MDE Plan 1, Plan 2, or Microsoft 365 Business Premium** license
- Network Protection must be set to **Block** mode (not Audit)

---

## Required Intune Policies

### Policy 1 — MDE Onboarding (EDR)

This activates the MDE sensor on the endpoint. Without this, nothing else works.

**Path:**
`Intune > Endpoint Security > Endpoint Detection & Response`

**Steps:**
1. Go to **Endpoint Security** in the Intune admin center
2. Select **Endpoint Detection & Response**
3. Click **Create Policy**
4. Platform: `Windows 10 and later` | Profile: `Endpoint Detection and Response`
5. Set **Microsoft Defender for Endpoint client configuration package type** to `Auto from connector` — Intune handles onboarding automatically via the MDE-Intune connector, no manual package download required
6. Assign to your target device group
7. Verify deployment — check **Device Status** tab shows `Succeeded`

> **Note:** Manual onboarding package download from security.microsoft.com is only needed for non-Intune deployment methods (local script, GPO, SCCM).

---

### Policy 2 — Network Protection (ASR)

This enables cross-browser web filtering enforcement at the OS level.

**Path:**
`Intune > Endpoint Security > Attack Surface Reduction`

**Steps:**
1. Go to **Endpoint Security** in the Intune admin center
2. Select **Attack Surface Reduction**
3. Click **Create Policy**
4. Platform: `Windows 10 and later` | Profile: `Attack Surface Reduction Rules`
5. Locate the setting: **Enable Network Protection**
6. Set value to: **Block** *(not Audit, not Not Configured)*
7. Assign to your target device group
8. Verify deployment — check **Device Status** tab shows `Succeeded`

> **Alternative path via Settings Catalog:**
> `Devices > Configuration > Create > Settings Catalog`
> Search: `Prevent users and apps from accessing dangerous websites`
> Located under: `Microsoft Defender Exploit Guard > Network Protection`

---

### Policy 3 — Web Content Filtering (Defender Portal)

Defines what categories of content get blocked. Enforced by Network Protection.

**Path:**
`security.microsoft.com > Settings > Endpoints > Web Content Filtering`

**Steps:**
1. Go to **security.microsoft.com**
2. Navigate to **Settings > Endpoints > Web Content Filtering**
3. Click **Add Policy**
4. Name the policy and select blocked content categories
5. Assign to a device group
6. Policy is enforced via the MDE sensor on enrolled devices

---

## Verification Checklist

Use this checklist to confirm Network Protection is active on a given machine.

| Check | Location | Expected Result |
|---|---|---|
| Device appears in MDE inventory | security.microsoft.com > Device Inventory | Status: Active |
| EDR onboarding policy applied | Intune > Endpoint Security > EDR > Device Status | Succeeded |
| Network Protection set to Block | Intune > Endpoint Security > ASR > Device Status | Succeeded |
| Sense service running on endpoint | PowerShell or Services | Running |

---

## On-Device Verification (PowerShell)

Run these on the endpoint to confirm the configuration locally:

```powershell
# Check Network Protection mode
# 0 = Disabled | 1 = Block | 2 = Audit
Get-MpPreference | Select-Object EnableNetworkProtection
```

```powershell
# Confirm MDE sensor (Sense) service is running
Get-Service -Name Sense
```

Both should return a running Sense service and `EnableNetworkProtection` value of `1`.

---

## Additional Coverage Options (Defense in Depth)

If MDE is not licensed or available, consider these browser-agnostic alternatives:

| Solution | How It Works | Examples |
|---|---|---|
| DNS-Layer Filtering | Blocks malicious domains before connection | Cisco Umbrella, Cloudflare Gateway, Quad9 |
| Web Proxy / SSL Inspection | Full traffic inspection regardless of browser | Zscaler, Netskope, Forcepoint |
| Enforce Edge via Policy | Eliminate the gap by restricting browser choice | GPO or Intune App Control |

---

## Quick Reference Summary

```
SmartScreen       = Edge/Windows native, no coverage in Chrome or Firefox
Network Protection = MDE sensor at OS level, covers ALL browsers
Required Policies  = EDR Onboarding + ASR (Network Protection: Block)
Verify With        = MDE Device Inventory + Intune Policy Status + PowerShell
```

---

*Reference guide compiled from MSP configuration discussion. Applies to Windows 10/11 endpoints managed via Microsoft Intune with MDE licensing.*
