# Windows AppSwitched Registry Investigation Guide

**Applies to:** Windows 10 version 1903 and later; Windows 11; per-user Explorer registry artifacts<br>
**Scope:** Inspect AppSwitched counters, identify the associated account, and correlate findings during endpoint investigations. Does not provide a complete execution history or identify the person using an account.<br>
**Last Updated:** October 2026

---

## Overview

**AppSwitched** is a per-user taskbar-interaction artifact in `NTUSER.DAT`. Published forensic research associates its counter with left-clicking an application's taskbar button. Use it as supporting evidence of interactive application use, rather than a complete count of launches or focus changes.

For the account running your inspection shell, the path is:

```text
HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\FeatureUsage\AppSwitched
```

FeatureUsage was introduced in Windows 10 version 1903. Verify availability and counter behavior on the Windows build under investigation.

---

## Prerequisites

| Requirement | Detail |
|---|---|
| Tools | Registry Editor or PowerShell on Windows; an offline registry parser for preserved evidence |
| Permissions | Read access for the current user's key; elevated local administrator access to load an offline hive |
| Licensing | Local registry inspection requires no Microsoft 365 or Intune license |
| Target account | Record the device, Windows build, target SID, and profile path |
| Evidence handling | Preserve the original hive and associated transaction logs using the approved collection process; analyze with an offline parser or use a working copy |

**MSP note:** An RMM shell running as SYSTEM or another administrator does not inspect the affected user's HKCU. Confirm the customer endpoint and target SID. Store collected evidence in the approved case location, not this repository.

---

## 1. Identify the Target Account and Hive

1. For your own account, run `whoami /user` to record its SID.
2. For another account, inspect **Registry Editor > HKEY_LOCAL_MACHINE > SOFTWARE > Microsoft > Windows NT > CurrentVersion > ProfileList**. Each SID subkey's `ProfileImagePath` maps to a local profile folder.
3. Check whether the target hive is already loaded under **HKEY_USERS > <SID>**. Use that hive if present; otherwise use the offline method in section 2.

```powershell
Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList' |
    ForEach-Object {
        [pscustomobject]@{
            SID = $_.PSChildName
            ProfilePath = (Get-ItemProperty -LiteralPath $_.PSPath).ProfileImagePath
        }
    }
```

**Account attribution:** Profile folder names can differ from account names after renames or for Entra accounts. Retain the SID and profile mapping. A SID identifies an account, not the person using it.

## 2. Inspect the AppSwitched Values

Choose the method matching the target hive. Do not edit or delete counters.

### Current User

1. Press **Win+R**, enter `regedit`, and open the path in the overview.
2. Review application value names and `REG_DWORD` data. Select decimal when comparing counts; Registry Editor can display DWORD data as hexadecimal.

Alternatively:

```powershell
Get-ItemProperty -LiteralPath 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FeatureUsage\AppSwitched' -ErrorAction Stop
```

`PSPath`, `PSParentPath`, `PSChildName`, `PSDrive`, and `PSProvider` are PowerShell metadata, not application counters. This command does not display the key's LastWrite timestamp.

### Another User with an Already-Loaded Hive

Use an elevated shell if permissions require it. Replace the example SID with the target SID from section 1:

```powershell
$targetSid = 'S-1-5-21-111111111-222222222-333333333-1001'
$appSwitchedPath = "Registry::HKEY_USERS\$targetSid\Software\Microsoft\Windows\CurrentVersion\Explorer\FeatureUsage\AppSwitched"
Get-ItemProperty -LiteralPath $appSwitchedPath -ErrorAction Stop
```

Do not unload a hive Windows loaded for a user session.

### Offline Hive or Working Copy

For routine troubleshooting, ensure the target user is signed out and the hive is not already loaded. For forensic analysis, prefer an offline parser. If mounting is necessary, use a working copy because loading can change the analysis copy.

Run this in an elevated PowerShell shell. Replace the example file path. The script checks load success, refuses to reuse an existing mount, and attempts cleanup even when the read fails.

```powershell
$hiveFile = 'C:\Investigation\Working Copy\NTUSER.DAT'
$mountName = 'AppSwitchedReview'
$mountPath = "Registry::HKEY_USERS\$mountName"

if (-not (Test-Path -LiteralPath $hiveFile -PathType Leaf)) {
    throw "Hive file not found: $hiveFile"
}
if (Test-Path -LiteralPath $mountPath) {
    throw "Mount already exists: $mountPath. Choose another name or investigate its owner."
}

& reg.exe load "HKU\$mountName" "$hiveFile"
if ($LASTEXITCODE -ne 0) {
    throw 'Hive load failed. Check permissions and whether the file is in use.'
}

try {
    Get-ItemProperty -LiteralPath "$mountPath\Software\Microsoft\Windows\CurrentVersion\Explorer\FeatureUsage\AppSwitched" -ErrorAction Stop
}
finally {
    & reg.exe unload "HKU\$mountName"
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Unload failed. Close tools holding this hive open, then run: reg.exe unload HKU\$mountName"
    }
}
```

## 3. Interpret the Results

| Data | Interpretation |
|---|---|
| Value name | Application identifier, often an executable path or an AppUserModelID |
| `REG_DWORD` data | Accumulated taskbar-interaction counter; not a duration or complete execution count |
| Key LastWrite timestamp | Key-level modification time, available through suitable registry analysis tools; not an individual application's last-use time |

**Interpretation limits:**

- Do not use AppSwitched as a complete record of Alt+Tab, direct window clicks, background processes, or launches.
- Values have no individual event timestamps. A key-level timestamp cannot establish when a particular application was used.
- Entries may remain after application removal. Retention is not guaranteed, and presence does not establish that an application is still installed.
- An absent key or value does not prove an application was never used.
- Elevation or alternate credentials alone do not establish which hive receives taskbar counters. Verify the interactive session and inspected hive.

## 4. Correlate with Other Evidence

1. Record the SID, application identifier, counter, Windows build, and collection time with its time zone in the case record.
2. Correlate with UserAssist, Prefetch, BAM, and available endpoint telemetry; each has different coverage and retention limits.
3. Review available logon events, including event 4624 and its logon type, for session context. Shared accounts still limit attribution to an individual.
4. Document supported findings and gaps. Do not assign an application-use time from AppSwitched alone.

---

## Verification / Testing Checklist

- [ ] Device, Windows build, target SID, and profile path are recorded.
- [ ] The hive belongs to the affected account rather than the RMM or administrator account.
- [ ] Application counters are distinguished from PowerShell metadata.
- [ ] Other available evidence is correlated and attribution/timestamp limits are documented.
- [ ] Any hive mounted by this procedure was successfully unloaded.
- [ ] Original evidence is preserved and customer data is stored in the approved case location.

**Lab validation:** In a disposable test profile on the relevant Windows build, compare a known application's counter before and after taskbar interactions. Record observations before relying on exact behavior. Do not experiment on an evidence profile.

**Cleanup / rollback:** No AppSwitched values are intentionally changed. Unload only the temporary hive you mounted. If cleanup fails, close tools holding the mount and retry `reg.exe unload`; do not delete the mounted key or counters.

---

## Troubleshooting

| Symptom | Likely cause | Action |
|---|---|---|
| Key is missing | Wrong hive, no relevant recorded activity, or build/profile differences | Confirm SID and build; corroborate with other artifacts |
| Access denied | Insufficient access to another account's hive | Use an authorized elevated shell or approved offline collection process |
| Load fails or file is in use | Profile hive is already loaded or held by another process | Inspect `HKEY_USERS\<SID>` or analyze a collected working copy |
| Temporary mount exists | Earlier inspection or another tool uses the name | Determine ownership or choose a unique name; do not unload someone else's mount |
| SID does not resolve to an account name | Deleted account or unavailable directory | Retain SID and `ProfileImagePath`; verify against authorized directory records |
| Counter differs from launch history | Limited taskbar-interaction coverage | Correlate with execution artifacts and validate in a lab |
| Unload fails | Open registry handle | Close tools using the temporary mount, retry unloading, and confirm it is absent |

---

## Related Keys and Tools

Other subkeys under `Explorer\FeatureUsage` provide supporting metrics:

| Key | Reported behavior |
|---|---|
| `AppLaunch` | Launches through applications pinned to the taskbar |
| `AppBadgeUpdated` | Application taskbar badge updates |
| `ShowJumpView` | Taskbar right-click / jump-list interactions |
| `TrayButtonClicked` | Clicks on built-in taskbar buttons, such as Start or the clock |

These descriptions reflect published forensic research; verify behavior on the target build.

- **Registry Explorer / RECmd:** Inspect offline hives and parse registry artifacts. Check installed batch definitions for FeatureUsage coverage.
- **RegRipper:** Use an appropriate FeatureUsage plugin if included in the installed distribution; confirm availability and output before use.

---

## Sources

- Microsoft Learn: [reg load](https://learn.microsoft.com/windows-server/administration/windows-commands/reg-load) and [reg unload](https://learn.microsoft.com/windows-server/administration/windows-commands/reg-unload).
- Microsoft Learn: [Get-ItemProperty](https://learn.microsoft.com/powershell/module/microsoft.powershell.management/get-itemproperty).
- Microsoft Learn: [4624: An account was successfully logged on](https://learn.microsoft.com/windows/security/threat-protection/auditing/event-4624).
- CrowdStrike, Jai Minton: [Employing FeatureUsage for Windows 10 Taskbar Forensics](https://www.crowdstrike.com/en-us/blog/how-to-employ-featureusage-for-windows-10-taskbar-forensics/).
- Group-IB: [Reconstructing User Activity for Forensics with FeatureUsage](https://www.group-ib.com/blog/featureusage/).
- Eric Zimmerman: [Tools](https://ericzimmerman.github.io/) — Registry Explorer and RECmd.
- RegRipper: [RegRipper 3.0 repository](https://github.com/keydet89/RegRipper3.0).
