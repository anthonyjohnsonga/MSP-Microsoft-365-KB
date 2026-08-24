# Microsoft 365 Apps for Mac — Stale Tenant Activation Fix

**Applies to:** Microsoft 365 Apps for Mac (Word, Excel, PowerPoint), macOS; any license tier that includes desktop app rights (Business Standard, Business Premium, E3/E5, Apps for business/enterprise)  
**Scope:** Word/Excel/PowerPoint stuck in view-only mode on a Mac *after* a tenant-to-tenant migration or a UPN/email change, where the license is correctly assigned and sign-in succeeds. Covers the macOS fix, the Windows equivalent, and the post-migration sweep. Not for genuinely unlicensed users, perpetual/LTSC activation failures, or the `0x0` licensing-certificate errors on out-of-support Office builds.  
**Last Updated:** August 2026

---

## Overview

**Symptom:** Word/Excel/PowerPoint show *"Ready to View Documents — your account can view documents, but it doesn't allow editing on a Mac."* The license is valid in the tenant. Outlook works fine.

**Cause:** Office preferences still point at the user's **old tenant** after a migration or email change. Office reads `OfficeActivationEmailAddress` and `TenantIDKey` out of the `com.microsoft.office` preferences domain and queries the wrong tenant for a license — auth succeeds, licensing comes back empty, and the apps drop to view-only.

The trap that burns the most time: `~/Library/Preferences/com.microsoft.office.plist` **survives an Office uninstall/reinstall.** A clean reinstall that doesn't fix it is *not* evidence against a local cache problem.

This is the device-side counterpart to the [Entra ID Device Tenant-to-Tenant Migration Runbook](../Microsoft%20Entra/Microsoft%20Entra%20Device%20Tenant%20Migration%20Runbook.md) — same migration, different stale pointer.

---

## Prerequisites

| Requirement | Detail |
|---|---|
| License | A tier with desktop app rights. Business **Basic** has no desktop rights — that's a different (expected) view-only state |
| Access | Local Terminal access as the affected user; admin (`sudo`) only for the escalation step |
| Admin side | Ability to check Entra sign-in logs for the `Microsoft Office` / `OfficeClientService` app, to confirm auth is succeeding |
| Downtime | One reboot; the user is signed out of Office during the fix |

---

## 1. Confirm it's this problem

```bash
defaults read com.microsoft.office OfficeActivationEmailAddress
defaults read com.microsoft.office TenantIDKey
```

If the address or tenant GUID is the **old** one, this runbook applies. Stop here if they're correct — it's something else.

Full dump if you want to see the stale ADAL identity blocks:

```bash
defaults read com.microsoft.office
```

Old identity blocks look like `<GUID>_ADAL-FetchInterval`, `<GUID>_ADAL-LastFetchTime`, etc.

---

## 2. Quit everything

All Office apps **plus Teams, OneDrive, and Company Portal.** Teams will re-seed the cache if it's running.

---

## 3. Clear the stale pointers

**Option A — surgical**

```bash
defaults delete com.microsoft.office OfficeActivationEmailAddress
defaults delete com.microsoft.office TenantIDKey
defaults delete com.microsoft.office TenantIDResult
```

Then remove each stale ADAL identity block (substitute the old user's GUID):

```bash
defaults delete com.microsoft.office <OLD-USER-GUID>_ADAL-FetchInterval
defaults delete com.microsoft.office <OLD-USER-GUID>_ADAL-LastFetchTime
defaults delete com.microsoft.office <OLD-USER-GUID>_ADAL-LastHash
defaults delete com.microsoft.office <OLD-USER-GUID>_ADAL-LastPolicies
```

**Option B — nuke the plist** (faster; also resets Office UI prefs)

```bash
rm -f ~/Library/Preferences/com.microsoft.office.plist
rm -f ~/Library/Group\ Containers/UBF8T346G9.Office/com.microsoft.office.plist
```

**Either way, flush the prefs cache:**

```bash
killall cfprefsd
```

**MSP note:** If you deploy Office preferences via Intune or Jamf configuration profile, an MDM-managed `OfficeActivationEmailAddress` value will be re-applied after the delete. Check for a profile scoped to the old tenant's address and fix it there first, or the machine will go stale again on the next policy refresh.

---

## 4. Reboot, then activate

Reboot. Open Word. Sign in with the **current** UPN. Choose **Work or School account** if prompted.

---

## 5. Verify

```bash
defaults read com.microsoft.office OfficeActivationEmailAddress
defaults read com.microsoft.office TenantIDKey
ls -la /Library/Preferences/com.microsoft.office.licensingV2.plist
```

Expect: new address, new tenant GUID, and `licensingV2.plist` **now exists**. That file is only written on successful activation — if it's still missing, activation didn't complete.

### Verification checklist

- [ ] `OfficeActivationEmailAddress` returns the **current** UPN
- [ ] `TenantIDKey` returns the **new** tenant GUID
- [ ] `/Library/Preferences/com.microsoft.office.licensingV2.plist` exists
- [ ] Word opens an existing document and allows editing and saving
- [ ] Excel and PowerPoint show the same (they share the licensing state)
- [ ] Outlook still connects and no re-auth loop appears
- [ ] No `<OLD-USER-GUID>_ADAL-*` keys remain in `defaults read com.microsoft.office`

---

## If that doesn't do it

Clear the license files and keychain, then repeat steps 3–4:

```bash
sudo rm -f /Library/Preferences/com.microsoft.office.licensingV2.plist
rm -rf ~/Library/Group\ Containers/UBF8T346G9.Office/Licenses
```

Keychain Access → login keychain → delete:
`Microsoft Office Identities Cache 3`, `Microsoft Office Identities Settings 3`,
`Microsoft Office Ticket Cache`, `com.microsoft.adalcache`, `MSOpenTech.ADAL.1*`,
`MicrosoftOfficeRMSCredential`, `com.microsoft.workplacejoin`

**MSP note:** Microsoft's [License Removal Tool](https://support.microsoft.com/office/how-to-remove-office-license-files-on-a-mac-b032c0f6-a431-4dad-83a9-6b727c03b193) does the license-file half of this for you and is the supportable path if you need to hand the machine back to Microsoft support. It does **not** clear `com.microsoft.office.plist`, so step 3 still applies — running the tool alone will not fix a stale tenant pointer.

**Also note:** deleting `~/Library/Group Containers/UBF8T346G9.Office/Identity` (an adjacent fix you'll find in most forum answers) removes Outlook profiles. Back up local Outlook data first, and don't reach for it before step 3 — the prefs are the actual problem here.

---

## Windows equivalent

Same failure mode, different location:

```powershell
Get-ItemProperty "HKCU:\Software\Microsoft\Office\16.0\Common\Identity" |
  Select-Object *ADUserName*, *ConnectedService*, *SignedOutADUserName*
```

Clear `HKCU\Software\Microsoft\Office\16.0\Common\Identity` and
`HKCU\Software\Microsoft\Office\16.0\Common\Licensing`, then re-activate.

To confirm which tenant the client actually licensed against before and after:

```powershell
cd "C:\Program Files\Microsoft Office\Office16"
./vnextdiag.ps1 -action list
```

The output includes the activating user's email and the associated tenant ID. Microsoft's scripted equivalent of the whole cleanup is [Reset activation state for Microsoft 365 Apps for enterprise](https://learn.microsoft.com/office/troubleshoot/activation/reset-office-365-proplus-activation-state) (`OLicenseCleanup.vbs`), also available as the SaRA `ResetOfficeActivation` scenario.

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `defaults read` returns the **correct** address and tenant | Not this problem | Stop. Check license assignment and service plan state in the admin center |
| Values return, get deleted, then come back after reboot | MDM configuration profile re-applying `OfficeActivationEmailAddress` | Fix or unscope the Intune/Jamf preference profile, then repeat step 3 |
| Prefs are correct but `licensingV2.plist` still missing | Stale license files / keychain tokens | Run the "If that doesn't do it" section, then repeat steps 3–4 |
| Auth succeeds in Entra sign-in logs, error code 0, no license written | Client querying the wrong tenant | This runbook — the sign-in log confirms it rather than contradicting it |
| Fixed by reinstall, then breaks again | Reinstall never touched the plist; something re-seeded it | Confirm Teams/OneDrive/Company Portal were quit in step 2 |
| Business **Basic** license assigned | No desktop app rights | Expected behavior, not a fault. Move the user to Business Standard or Premium |
| `Unknown error 0x0` / license certificate errors on Office 2019 for Mac | Out-of-support build in reduced functionality mode | Unrelated to tenant state. Move to a supported build or Microsoft 365 |

---

## Diagnostic notes

**The tell:** successful auth + no license files = client is querying the **wrong tenant**. Check sign-in logs for `Microsoft Office` → `OfficeClientService`. Error code 0 with no `licensingV2.plist` written is this problem, not a licensing problem.

**Don't waste time on:** license reassignment, SKU verification, Conditional Access, macOS/build version, or reinstalling Office — none of it touches this.

**Post-migration sweep:** any machine that had Office signed into the old tenant before cutover carries the same stale pointer. Run the step 1 check proactively rather than waiting for tickets.

---

## Sources

- Microsoft Learn: [Set suite-wide preferences for Office for Mac](https://learn.microsoft.com/microsoft-365-apps/mac/preferences-office) — documents `OfficeActivationEmailAddress` in the `com.microsoft.office` domain
- Microsoft Learn: [Deploy preferences for Office for Mac](https://learn.microsoft.com/microsoft-365-apps/mac/deploy-preferences-for-office-for-mac) — where `.plist` preferences live and how MDM overrides them
- Microsoft Learn: [Overview of activation for Office for Mac](https://learn.microsoft.com/microsoft-365-apps/mac/overview-of-activation-for-office-for-mac)
- Microsoft Learn: [Outlook for Mac repeatedly prompts for authentication](https://learn.microsoft.com/troubleshoot/outlook/sign-in/repeated-prompts-authentication) — the keychain entry names to clear
- Microsoft Learn: [Check the license and activation status for Microsoft 365 Apps](https://learn.microsoft.com/microsoft-365-apps/licensing-activation/vnextdiag) — `vnextdiag.ps1`
- Microsoft Learn: [Reset activation state for Microsoft 365 Apps for enterprise](https://learn.microsoft.com/office/troubleshoot/activation/reset-office-365-proplus-activation-state) — Windows equivalent
- Microsoft Support: [How to remove Office license files on a Mac](https://support.microsoft.com/office/how-to-remove-office-license-files-on-a-mac-b032c0f6-a431-4dad-83a9-6b727c03b193) — License Removal Tool
- Microsoft Q&A: [macOS Office sign-in redirecting to old tenant after tenant migration](https://learn.microsoft.com/answers/a/12815374) — same scenario reported in the wild
