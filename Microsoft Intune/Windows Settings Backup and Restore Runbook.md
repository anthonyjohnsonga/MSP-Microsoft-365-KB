# Windows Settings Backup and Restore Runbook

**Applies to:** Intune-managed Windows clients joined or hybrid joined to Microsoft Entra ID in the commercial cloud.

**Scope:** Configure Windows settings backup and enrollment or first-sign-in restore, verify a pilot, and manage rollback and offboarding.

**Last Updated:** October 6, 2026

## Overview

This runbook turns on Windows settings backup and restore (formerly Windows Backup for Organizations) for an Intune-managed client tenant in two parts: the tenant-wide restore toggle in Enrollment, then a device-targeted settings catalog policy that enables backup.

It backs up Windows settings and the list of installed Microsoft Store apps to the tenant. It does not back up files, Win32 apps, or app data. Use OneDrive Known Folder Move for files.

Backup runs automatically every eight days once the policy applies. Users can also run it on demand from the Windows Backup app. No interval change is configured in this runbook.

Starting with Windows 11 version 26H2, backup is on by default for eligible devices. An explicit admin policy (Enabled or Disabled) still wins, so set it deliberately in the baseline. Restore still requires administrator configuration.

## 1. Prerequisites and Change Capture

Confirm every item below before enabling. Backup and restore have different OS minimums ([Microsoft Learn](https://learn.microsoft.com/en-us/windows/configuration/windows-backup/)).

| Requirement | Backup (source device) | Restore at OOBE | Restore at first sign-in |
| --- | --- | --- | --- |
| Windows 10 22H2 | 19045.6216+ | Not supported | Not supported |
| Windows 11 22H2 / 23H2 | 22621.5768+ / 22631.5768+ | 22621.3958+ / 22631.3958+ | Not supported |
| Windows 11 24H2 | 26100.4946+ | 26100.4770+ | 26100.7922+ |
| Windows 11 25H2 | Not listed | Not listed | 26200.7922+ |
| Join state | Entra joined or hybrid joined | Entra joined only | Entra joined or hybrid joined |
| Other | User signed in with Entra ID | User has a backup profile; if Autopilot is used, user-driven mode is required | Device already enrolled; first sign-in after enrollment; user has a backup profile |

**Build-table note:** “Not listed” reflects a gap in the current overview, not a declaration that a newer version is unsupported. Confirm current Microsoft requirements before deploying on 25H2 or 26H2. An OS meeting a feature build minimum may still be outside normal servicing; confirm lifecycle and any required ESU coverage.

- **Licensing:** Confirm Intune entitlement for the targeted users/devices and supported Windows licensing and servicing. The feature overview does not list a separate backup add-on requirement; do not assume Microsoft 365 Backup service licensing or Enterprise State Roaming licensing applies to this feature.
- **Roles:** Intune Service Administrator or Global Administrator to change the Enrollment restore setting. Microsoft 365 Backup Administrator to view or delete another user's backup data.
- **Cloud:** Not available in GCC High, sovereign clouds, or China.
- **Policy source:** Configure through Intune (CSP) or GPO, never both. On hybrid-joined clients, confirm no AD GPO touches Sync your settings.
- **Older builds:** If target devices ship below the July 2025 (OOBE) or March 2026 (first sign-in) builds, enable **Install Windows quality updates** on the Enrollment Status Page so they patch during setup.

Record the original enrollment toggle, profile settings, assignments/exclusions, relevant GPOs, and Conditional Access policies in the change record. Export or capture affected profiles before modifying them. Start with a small pilot of supported, dedicated devices.

**MSP note:** Backups cannot migrate across tenants. Confirm the customer tenant before every Graph session, and store backup exports and diagnostic output privately. No customer identifiers or backup payloads belong in this repository.

### Baseline conflict check

Backup silently does nothing if any of these are set to **Disabled** by a security baseline or GPO. Review the customer's Intune, AD GPO, and baseline-management settings (including Inforcer where used) before rollout.

- [ ] EnableActivityFeed (System > OS Policies)
- [ ] PublishUserActivities (System > OS Policies)
- [ ] UploadUserActivities (System > OS Policies)
- [ ] EnableCDP (ADMX_GroupPolicy CSP)
- [ ] AllowConnectedDevices (Connectivity CSP)

For these five prerequisites, Not configured or Enabled avoids this specific conflict. Other prerequisites and policies can still prevent backup. Do not relax a security baseline without reviewing the customer's requirements.

## 2. Turn on Restore in Enrollment

This tenant-wide toggle makes restore available at enrollment; the page appears only when the device and user meet restore prerequisites. It has no group assignment and doesn't affect devices already enrolled.

1. Sign in to the [Intune admin center](https://intune.microsoft.com) as Intune Service Administrator or Global Administrator.
2. Go to **Devices > Enrollment > Windows Backup and Restore**.
3. Set **Show restore page** to **On**.
4. Select **Save**.
5. Record the change and the date in the client's documentation. Verify whether the customer's baseline-management tooling tracks this enrollment setting; record it separately if it does not.

## 3. Create the Backup Policy

One settings catalog profile with **Enable Windows Backup** set to Enabled turns on backup and makes the Windows Backup app available on assigned devices.

1. In the Intune admin center, go to **Devices > Windows > Configuration > Create > New policy**.
2. Platform: **Windows 10 and later**. Profile type: **Settings catalog**. Select **Create**.
3. Name it to your naming standard, for example `WIN - Settings Backup - Enable`.
4. Select **Add settings**, browse to **Administrative Templates > Windows Components > Sync your settings**, and select **Enable Windows Backup**.
5. Set **Enable Windows Backup** to **Enabled**.
6. Assign to a pilot device group containing eligible Entra joined or hybrid joined Windows devices. Expand after Section 6 passes. Exclude shared, kiosk, multi-user, non-persistent VDI, and Windows 365 Flex shared Cloud PCs from backup and restore-enabled profiles; use an explicit disable policy where needed, especially with the 26H2 backup default. (Microsoft allows device or user groups; device groups are the recommendation here.)
7. Review and create.

### Optional: limit what is backed up

Add any of these settings from the same **Sync your settings** category to the same profile. Enabled means that group is not backed up. Each has an "Allow users to turn ... syncing on" option that makes it off by default instead of locked.

| Setting | Settings app group it turns off | OMA-URI path |
| --- | --- | --- |
| Do not sync | Remember my preferences (all groups) | `ADMX_SettingSync/DisableSettingSync` |
| Do not sync apps | Remember my apps (existing backups can still be restored) | `ADMX_SettingSync/DisableApplicationSettingSync` |
| Do not sync passwords | Accounts, Wi-Fi networks and passwords | `ADMX_SettingSync/DisableCredentialsSettingSync` |
| Do not sync personalize | Personalization | `ADMX_SettingSync/DisablePersonalizationSettingSync` |
| Do not sync accessibility settings | Accessibility | `SettingsSync/DisableAccessibilitySettingSync` |
| Do not sync language preferences settings | Language preferences and dictionary | `SettingsSync/DisableLanguageSettingSync` |
| Do not sync other Windows settings | Other Windows settings | `ADMX_SettingSync/DisableWindowsSettingSync` |

All paths sit under `./Device/Vendor/MSFT/Policy/Config/`, so these settings are device-scoped ([policy settings reference](https://learn.microsoft.com/en-us/windows/configuration/windows-backup/policy-settings)). Use the policy reference and test the required settings on the target build; absence from the catalog is not evidence that a policy has no effect.

## 4. Restore After Enrollment and Diagnose Conditional Access

Only needed if users should be offered restore at first sign-in on devices already enrolled, or if Conditional Access blocks the restore flow.

### Restore at first sign-in

1. Create a settings catalog profile (Windows 10 and later).
2. Add **Windows Backup And Restore > Enable Windows Restore** and set it to **Enabled**.
3. Assign to the target device group. It applies at the next policy refresh.

### Conditional Access diagnosis

If restore reports an access error, inspect **Entra admin center > Entra ID > Monitoring & health > Sign-in logs** for the test user at the failure time. Check the resource, failed policy, and grant control before changing access. These app IDs identify different documented scenarios:

| App ID | Documented scenario |
| --- | --- |
| `d32c68ad-72d2-4acb-a0c7-46bb2cf93873` | Backup/restore service token blocked by Conditional Access; Microsoft documents a custom policy allowing this service for the restore flow. |
| `74d197dc-b84d-4d43-a1b2-b5bf3bb91c11` | OOBE restore experience may still require phishing-resistant MFA when an authentication strength policy excludes Intune apps. This is not a general instruction to exclude the restore app. |

Use the sign-in evidence to make a narrowly scoped policy change for the required restore scenario. An additional permissive policy does not override a blocking policy or another policy's unmet grant control. Capture the original policy, validate with the pilot, and retain the customer's required protections.

For supported VM/OOBE scenarios where strong authentication is difficult, Microsoft suggests considering a Temporary Access Pass. Validate TAP against the enforced authentication strength and customer enrollment design before relying on it.

## 5. What Gets Backed Up

Backup preserves supported Windows settings and the Microsoft Store app list. Use Microsoft's [settings catalog](https://learn.microsoft.com/en-us/windows/configuration/windows-backup/catalog) for exact build-specific coverage; do not promise complete user-profile recovery.

| Area | Example coverage or recovery method |
| --- | --- |
| Windows preferences | Supported personalization, accessibility, input-device, system, and File Explorer settings; coverage differs by OS. |
| Microsoft Store apps | Installed app list; this is not an app-data backup. Validate the resulting app experience in the pilot. |
| User files and folders | Use OneDrive Known Folder Move or the customer's file backup solution. |
| Win32/LOB apps and application data | Deploy apps through Intune and use application-specific data protection. |
| Microsoft Edge favorites and settings | Use Edge enterprise sync. |
| Managed device configuration | Reapply through Intune; verify required policies after enrollment. |

Windows 10 has a smaller backup-only settings set. The catalog also documents special conditions, including administrator requirements for restoring Set time zone automatically. Test the settings the customer actually needs. Use the current overview for first-sign-in restore requirements: parts of the FAQ still describe the older OOBE-only behavior.

## 6. Verify the Pilot

Check the tenant side first (does a backup exist for the user), then the device side (did the policy land and is anything blocking it). The device-side registry and task checks are discovery queries, so confirm the results on one test device before scripting them into a Remediation.

### Tenant: Confirm a User Has a Backup (Graph Beta)

Microsoft's `WindowsBackupAdmin` module wraps the Graph beta `windowsSetting` API ([PowerShell Gallery](https://www.powershellgallery.com/packages/WindowsBackupAdmin)). It runs on Windows PowerShell 5.1 or PowerShell 7 and installs `Microsoft.Graph.Authentication` on first run. Viewing your own backup needs no special role; viewing or deleting another user's needs the **Microsoft 365 Backup Administrator** role.

```powershell
# One-time install
Install-Module WindowsBackupAdmin -Scope CurrentUser

# View and optionally export a user's backup (grouped by device). -UserId accepts UPN or object ID.
Get-WindowsBackup -UserId user@contoso.com
```

The same data through Graph directly. Install/import both SDK modules below. Administrator consent is required for the delegated permissions; use Microsoft 365 Backup Administrator for the other-user workflow. Graph beta APIs are subject to change and unsupported for production applications, so treat this as an interactive diagnostic, not a production Remediation. The user path uses `{user object ID}@{tenant ID}`, not a UPN, and is delegated-only ([List Windows settings](https://learn.microsoft.com/en-us/graph/api/usersettings-list-windows?view=graph-rest-beta)).

```powershell
# One-time install for this direct Graph example
Install-Module Microsoft.Graph.Authentication, Microsoft.Graph.Users -Scope CurrentUser
Import-Module Microsoft.Graph.Authentication
Import-Module Microsoft.Graph.Users

# Replace these fictional values with the intended customer's tenant and user.
Connect-MgGraph -TenantId 'customer.onmicrosoft.com' -Scopes 'UserWindowsSettings.Read.All','User.Read.All'
Get-MgContext | Select-Object TenantId, Account, Scopes
$userId = (Get-MgUser -UserId 'user@contoso.com').Id
$tenantId = (Get-MgContext).TenantId
$filter = [Uri]::EscapeDataString("settingType eq 'backup'")
$uri = "https://graph.microsoft.com/beta/users/${userId}@${tenantId}/settings/windows?`$filter=$filter"

$settings = @(
    do {
        $page = Invoke-MgGraphRequest -Method GET -Uri $uri -ErrorAction Stop
        $page.value
        $uri = $page.'@odata.nextLink'
    } while ($uri)
)
$settings | Select-Object settingType, payloadType, windowsDeviceId
Disconnect-MgGraph
```

Each distinct `windowsDeviceId` identifies backup data associated with a device. Inspect instance timestamps (for example, `lastModifiedDateTime`) for recency. Returned data alone does not prove that the latest backup succeeded or that restore will work.

### Device: confirm prerequisites

```powershell
# Join state: AzureAdJoined should be YES (and DomainJoined YES for hybrid)
dsregcmd /status | Select-String 'AzureAdJoined|DomainJoined'

# OS build + revision, compare to the Prerequisites table
$v = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
"{0} {1}.{2}" -f $v.DisplayVersion, $v.CurrentBuild, $v.UBR
```

### Device: confirm the policy applied

```powershell
# Find EnableWindowsBackup (and any Do not sync / restore settings) delivered by Intune
Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device' -Recurse -ErrorAction SilentlyContinue |
    ForEach-Object {
        $key = $_
        $key.GetValueNames() |
            Where-Object { $_ -match 'EnableWindowsBackup|Disable.*SettingSync|EnableWindowsRestore' } |
            ForEach-Object { [pscustomobject]@{ Key = $key.Name; Name = $_; Value = $key.GetValue($_) } }
    }
```

If nothing returns, check the profile status in Intune and force a sync from **Settings > Accounts > Access work or school > Info > Sync**.

### Device: check for baseline conflicts

```powershell
# A value of 0 (or a disabled ADMX value) for any of these means backup will not run
$names = 'EnableActivityFeed','PublishUserActivities','UploadUserActivities','EnableCdp','AllowConnectedDevices'

# GPO-delivered values
$gpo = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System'
if (Test-Path $gpo) {
    $k = Get-Item $gpo
    $names | ForEach-Object { [pscustomobject]@{ Source = 'GPO'; Name = $_; Value = $k.GetValue($_) } }
}

# Intune-delivered values
Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device' -Recurse -ErrorAction SilentlyContinue |
    ForEach-Object {
        $key = $_
        $key.GetValueNames() | Where-Object { $names -contains $_ } |
            ForEach-Object { [pscustomobject]@{ Source = $key.Name; Name = $_; Value = $key.GetValue($_) } }
    }
```

An empty Value means the queried registry value was absent; it does not prove the effective policy is Not configured. Confirm GPO results and Intune per-setting status. The registry queries are discovery aids, not an authoritative policy report.

### Device: find the backup task and its last run

The sources cited here do not identify a stable task name. Run this on a device where the policy has applied, then note the exact task path for future scripts. The filter is broad, so ignore unrelated matches such as registry backup tasks.

```powershell
Get-ScheduledTask |
    Where-Object { $_.TaskName -match 'Backup' -or $_.TaskPath -match 'Backup|SettingSync' } |
    ForEach-Object {
        $i = $_ | Get-ScheduledTaskInfo
        [pscustomobject]@{
            Path       = $_.TaskPath + $_.TaskName
            State      = $_.State
            LastRun    = $i.LastRunTime
            LastResult = $i.LastTaskResult
            NextRun    = $i.NextRunTime
        }
    }
```

The user-facing check is **Settings > Accounts > Windows backup**, which shows backup status, or the Windows Backup app.

## 7. Troubleshooting and Offboarding

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| Policy shows Succeeded but no backup exists | A baseline sets activity feed, CDP, or Connected Devices to Disabled | Check all prerequisites and the effective baseline; review conflicting settings before changing them |
| Windows Backup app missing | EnableWindowsBackup not applied, or build too old | Confirm the policy and OS build |
| Toggles grayed out in Settings | Backup not enabled by policy, or a Do not sync setting locks them | Check the policy and any Do not sync settings |
| No restore page at OOBE | Device enrolled before Show restore page was on, hybrid joined, self-deploying Autopilot, or build too old | Verify Entra join, a same-tenant backup profile, supported build, and user-driven mode if using Autopilot; review ESP updates |
| "You can't get there from here" during restore | Conditional Access blocking the token | Inspect sign-in logs and resolve the specific policy conflict in Section 4 |
| Unexpected results on hybrid devices | GPO and Intune both configuring Sync your settings | Pick one source; remove the other |
| Get-WindowsBackup fails for another user | Missing Microsoft 365 Backup Administrator role | Check tenant, admin consent, delegated scopes, and role; activate approved PIM access if available |

### Turning backup off

Set **Enable Windows Backup** to **Disabled** in the same profile. The scheduled backup stops, but existing backup data stays in the tenant until deleted.

### Deleting a user's backup at offboarding

Add this to the user offboarding SOP. Deletion is permanent and removes all of the user's backup data; the command prompts for confirmation.

```powershell
Remove-WindowsBackup -UserId user@contoso.com
```

- [ ] Export first with `Get-WindowsBackup` if the client's retention policy requires it.
- [ ] Delete before or alongside removing the user's licenses and account.

## 8. Verification Checklist and Rollback

- [ ] Pilot device meets OS, join-state, user-sign-in, and cloud requirements.
- [ ] Intune profile and per-setting status show the intended settings without conflicts.
- [ ] Effective baseline policies do not disable the five prerequisites in Section 1.
- [ ] User runs an on-demand backup in the Windows Backup app; status and tenant backup timestamps confirm new data.
- [ ] On a separate pilot target, the same user and tenant can select the expected source backup during supported OOBE or first sign-in.
- [ ] Required sample settings restore; Store app experience, OneDrive files, and Intune app/policy deployment are checked separately.
- [ ] Shared/VDI exclusions and explicit disable policies are effective where needed.
- [ ] Any Conditional Access change is tested and documented, with expected protections still enforced.

To roll back the rollout:

1. Restore captured profile settings and assignments and the original enrollment restore toggle. Enrollment-toggle changes do not undo policy already delivered to enrolled devices.
2. If the intent is to stop backup or restore on enrolled devices, explicitly set the relevant backup/restore settings to Disabled and sync the pilot. Merely removing an assignment is not proof that the setting is disabled, particularly with the 26H2 default.
3. Restore any changed Conditional Access policy and baseline/GPO settings from the change record. Confirm effective configuration and sign-in behavior.
4. Verify that future backup/restore behavior matches the rollback intent. Existing backups remain; deletion is a separate, irreversible offboarding action. Disabling restore does not reverse preferences already restored to a user profile.

**Validation status:** Reviewed against Microsoft documentation and checked for PowerShell syntax. No tenant policy changes, backup deletion, or end-to-end lab restore were performed during preparation. Complete the pilot before broad deployment.

## Sources

- [Windows settings backup and restore overview](https://learn.microsoft.com/en-us/windows/configuration/windows-backup/), Microsoft Learn, updated 2026-09-29
- [Windows Backup for Organizations policy settings](https://learn.microsoft.com/en-us/windows/configuration/windows-backup/policy-settings), Microsoft Learn
- [Windows Backup for Organizations settings catalog](https://learn.microsoft.com/en-us/windows/configuration/windows-backup/catalog), Microsoft Learn
- [Windows Backup for Organizations FAQ](https://learn.microsoft.com/en-us/windows/configuration/windows-backup/faq), Microsoft Learn
- [List Windows settings (Graph)](https://learn.microsoft.com/en-us/graph/api/usersettings-list-windows?view=graph-rest-beta), Microsoft Learn
- [WindowsBackupAdmin module](https://www.powershellgallery.com/packages/WindowsBackupAdmin), PowerShell Gallery
