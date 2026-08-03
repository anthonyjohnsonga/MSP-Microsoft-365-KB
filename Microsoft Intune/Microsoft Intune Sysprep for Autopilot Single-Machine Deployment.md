# Sysprep for Autopilot Single-Machine Deployment

**Applies to:** Windows 10 / Windows 11 Pro or Enterprise, Microsoft Intune, Windows Autopilot (Entra ID P1 or P2)  
**Scope:** Preparing one physical machine — pre-loaded with tools and Office, registered in Autopilot — to ship to one end user. This is not a golden-image or WIM-capture guide.  
**Last Updated:** August 2026

---

## Overview

One machine, one client, one user. You build it on the bench, register the hash in Autopilot, and ship it. The question that stalls this workflow is always the same: *do I need to Sysprep, and with which switches?*

The short answer is `/oobe` without `/generalize`. Almost every Sysprep horror story — Appx failures, BitLocker errors, "the machine needs a rebuild" — comes from `/generalize`, and `/generalize` is only required when the OS will run on **different hardware** than it was built on. That isn't this scenario.

---

## What Sysprep Is

Sysprep (System Preparation Tool) lives at `C:\Windows\System32\Sysprep\sysprep.exe`. Its job is to reset parts of a Windows installation so it can be handed to someone else.

It does **two independent things**, controlled by separate switches:

1. **Reset to OOBE** — makes the machine boot into the "let's set up your PC" first-run experience again
2. **Generalize** — strips machine identity (SID) and hardware-specific state so the OS can run on *different* hardware

Most people conflate these. They're separate, and for single-machine deployment you only want the first one. Microsoft's own guidance backs this: *"To prepare a computer for an end user, you must configure the computer to boot to OOBE."* Generalizing is the additional step required only when you *"transfer a Windows image to a different computer."*

> **Note:** The Sysprep GUI is deprecated. Microsoft still supports it but may remove it in a future release — use the command line. On Windows Server Core you *must* use the command line with `/quiet`, or the process fails silently with no UI.

---

## The Switches

| Switch | What it does |
|---|---|
| `/oobe` | Next boot goes to the Out-of-Box Experience — region, keyboard, account sign-in. Installed apps, machine name, and drivers survive. |
| `/audit` | Reboots into Audit mode — desktop access as the built-in Administrator with no OOBE, for installing apps and drivers. See [Build in Audit Mode](#build-in-audit-mode-the-cleaner-path). |
| `/generalize` | Resets machine SID, clears system restore points, deletes event logs, and strips hardware driver bindings. **Only needed if the OS will run on different hardware than it was built on.** |
| `/reboot` | Restart after Sysprep completes (goes straight into OOBE) |
| `/shutdown` | Power off after Sysprep completes — better if you're boxing the machine immediately |
| `/quit` | Run and return to desktop, no reboot or shutdown |
| `/quiet` | Suppress on-screen confirmations. **Mandatory on Server Core** — without it the UI never appears and Sysprep fails silently. |
| `/unattend:<file>` | Apply an answer file during setup |
| `/mode:vm` | Generalize a VHD for redeployment on the **same** hypervisor with a **matching hardware profile**. Can only be run from inside a VM. The only other switches that apply are `/reboot`, `/shutdown`, and `/quit`. |

---

## Do I Need `/generalize`?

**No** — if the OS stays on the hardware it was built on. One machine, one client, one user.

**Yes** — if the OS is going onto *other* hardware:
- Capturing a WIM for MDT/WDS/ConfigMgr
- Cloning a VM template
- Any image deployed to multiple machines

The SID reset only matters when two machines would otherwise share one. Not your scenario.

---

## The Command

```powershell
C:\Windows\System32\Sysprep\sysprep.exe /oobe /shutdown
```

Use `/shutdown` when boxing the machine up. Use `/reboot` if you want to verify OOBE appears before powering off.

**PowerShell note:** always use the full path. PowerShell doesn't search the working directory, and the Sysprep folder isn't in `%PATH%` — bare `sysprep.exe` will throw `CommandNotFoundException`. Run elevated.

---

## Build in Audit Mode (the cleaner path)

This is the supported way to build a machine you intend to hand to someone else, and it removes two of the problems the rest of this guide has to work around.

At the **first OOBE screen** on a fresh machine, press <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>F3</kbd>. Windows reboots straight to the desktop as the built-in Administrator with the Sysprep tool already open. Install your RMM agent, security tools, Office, and drivers there, then run:

```powershell
C:\Windows\System32\Sysprep\sysprep.exe /oobe /shutdown
```

Why this is better:

- **No bench admin profile ships with the machine.** The built-in Administrator account is disabled and its profile removed when you leave Audit mode — the entire [Bench Admin Account](#bench-admin-account) decision below disappears.
- **No per-user Appx drift.** Nothing gets installed under a real user profile, which is the root cause of `0x80073CF2` if you ever do need `/generalize`.

The catch: you have to decide on Audit mode *before* completing OOBE. On a machine that's already been through OOBE, follow the workflow below instead.

---

## Deployment Workflow

### 1. Build the machine
- Install RMM agent, security tools, Office
- Rename to client naming convention
- Apply patches, reboot, let updates settle

> The Autopilot deployment profile can apply its own device name template, which overrides whatever you set here.

### 2. Freeze Store updates (do this *before* installing anything, on future builds)

```powershell
if (-not (Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore")) {
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore" | Out-Null
}
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore" -Name "AutoDownload" -Value 2 -Type DWord
```

Prevents per-user Appx versions from drifting away from provisioned versions. Not strictly required without `/generalize`, but good hygiene — and it's the fix if you ever *do* need to generalize.

> **Don't use `New-Item -Force` here.** On an existing registry key, `-Force` replaces the key and silently drops any other values under it — including anything a baseline put there (`RemoveWindowsStore`, `DisableStoreApps`, and friends).

### 3. Capture the Autopilot hash

```powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned
Install-Script -Name Get-WindowsAutopilotInfo -Force
$env:Path += ";C:\Program Files\WindowsPowerShell\Scripts"
Get-WindowsAutopilotInfo -OutputFile C:\HWID\AutopilotHWID.csv
```

Note the invoked name has **no `.ps1`** once it's installed as a script — `Install-Script` puts it on the path, unlike `sysprep.exe`. On first run it prompts to approve app registration permissions. Agree to install **NuGet** from the PSGallery if asked.

The hash is derived from hardware, so it survives Sysprep either way.

**Two no-script alternatives** for a one-off bench machine:
- **Windows 11, in OOBE:** press <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>D</kbd> for the Autopilot Diagnostics Page and export logs to a thumb drive — the bundle includes a CSV with the hash.
- **From the desktop:** **Settings > Accounts > Access work or school > Export your management log files**. Output lands in `C:\Users\Public\Documents\MDMDiagnostics`.

**MSP note:** Microsoft recommends 4K-hash registration "only for testing or other limited scenarios" and points partners at Partner Center for volume registration — the 4K hash contains sensitive information only the device owner should hold. CSV import also caps at **500 rows** per file.

### 4. Register in Intune and **wait for assignment**

Import the CSV under **Devices > Windows > Enrollment > Devices** (under Windows Autopilot), or use `-Online` with a Graph app registration. Registration requires *Intune Administrator* or *Policy and Profile Manager*.

Then verify — this is the step people skip:
- Device appears in the Autopilot device list (hit **Sync**, then **Refresh** — it can take several minutes)
- Device is in the correct deployment group
- Profile status reads **Assigned**, not *Pending*

If the profile isn't assigned when the user hits OOBE, the machine falls through to consumer OOBE and you're doing a manual enrollment remotely.

### 5. Pre-flight checks

- [ ] Autopilot profile status = **Assigned**
- [ ] BitLocker policy assigned to the target device group (key escrow to Entra ID)
- [ ] Machine is **workgroup** — not Entra-joined, not domain-joined
- [ ] No Microsoft account signed in
- [ ] Bench admin account decision made (see below)

### 6. Sysprep

```powershell
C:\Windows\System32\Sysprep\sysprep.exe /oobe /shutdown
```

### 7. Box it up

If you used `/reboot`, power off at the first OOBE screen — don't click through it.

> **Don't restart OOBE repeatedly to "test."** Too many OOBE restarts drop it into a recovery mode where the Autopilot configuration won't run. The tell is language, region, and keyboard all appearing on **one page** instead of separate pages. Fix by setting `HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\UserOOBE` to `1`.

---

## Bench Admin Account

Skip this entirely if you built in [Audit mode](#build-in-audit-mode-the-cleaner-path) — the built-in Administrator profile is removed on the way out.

Otherwise: your build account (e.g. a bench admin with SID ending `-1001`) ships with the machine. Sysprep doesn't delete user profiles — `/generalize` wouldn't either.

Decide deliberately:
- **Keep it** as break-glass local admin — ensure the password is your managed/rotated standard, not a bench throwaway, and that LAPS or equivalent picks it up after enrollment
- **Remove it** if the Autopilot profile grants the end user local admin anyway

Either is fine. Shipping it by accident is not.

---

## BitLocker

Decrypt is only required for `/generalize`:

```powershell
Disable-BitLocker -MountPoint "C:"
Get-BitLockerVolume -MountPoint "C:"   # wait for FullyDecrypted
```

Suspending is not enough — it must read `VolumeStatus: FullyDecrypted` and `ProtectionStatus: Off`.

Without `/generalize`, leave BitLocker alone.

**Either way, confirm the Intune disk encryption policy is assigned to the group the device lands in before shipping.** Windows 11 auto-encrypts on qualifying hardware, and 24H2 removed the DMA and HSTI/Modern Standby prerequisites — so far more machines now encrypt themselves than technicians expect.

Where the recovery key ends up depends entirely on how the device is signed in:

| Device state | Recovery key destination |
|---|---|
| Entra joined | Backed up to Entra ID automatically once the user authenticates, then the clear key is removed |
| AD domain joined | Backed up to AD DS when the computer joins the domain |
| Personal Microsoft account, no join | Uploaded to that **consumer** MSA — not your tenant, not recoverable by you |
| Local accounts only | No escrow at all. Per Microsoft the device *"remains unprotected even though the data is encrypted"* — the clear key is still present |

For backup to Entra ID or AD DS to happen, the **Choose how BitLocker-protected operating system drives can be recovered** setting must be enabled by policy. That's the reason the policy has to be assigned *before* the device reaches OOBE, not after.

---

## Common Errors (all `/generalize`-only)

Every one of these disappears when you drop `/generalize`.

### `0x80310039` — BitLocker is on for the OS volume
Decrypt fully. See above.

### `0x80073CF2` — Package installed for a user, but not provisioned for all users

`/generalize` requires every app to be provisioned for all users. Updating an app from the Microsoft Store ties that app to the signed-in user account, which breaks the requirement. The Sysprep log shows:

```
<package name> was installed for a user, but not provisioned for all users.
This package will not function properly in the sysprep image.
```

```powershell
# Identify
Get-AppxPackage -AllUsers <PackageName> | Select PackageFullName, Version
Get-AppxProvisionedPackage -Online | Where-Object DisplayName -eq "<PackageName>" | Select DisplayName, Version

# See which user owns it
(Get-AppxPackage -AllUsers <PackageName>).PackageUserInformation | ForEach-Object {
    [PSCustomObject]@{
        SID          = $_.UserSecurityId.Sid
        User         = $_.UserSecurityId.UserName
        InstallState = $_.InstallState
    }
}

# Remove per-user copy (elevated)
Remove-AppxPackage -Package "<PackageFullName>" -AllUsers
```

Sysprep reports **one package at a time** — re-read the log after each attempt.

`Microsoft.SecHealthUI` is a known dead end on current Windows 11 builds: it's a protected system component, returns `0x80073CFA` on removal, and often isn't provisioned at all. There's no clean supported fix. Drop `/generalize`.

### Generalize pass limit exceeded
Rarely what's actually wrong on a modern build. Windows 8.1 / Server 2012 and later allow **1001** Sysprep runs per image; only Windows 7 and Server 2008 R2 were limited to 3. The activation *rearm* clock is a separate counter, and the `SkipRearm` answer-file setting is no longer needed with a volume-licensing or retail key because Windows activates automatically.

### Machine is domain or Entra joined
Generalizing a joined machine is unsupported and produces unpredictable results. Unjoin to workgroup first — see the [Entra Device Tenant-to-Tenant Migration Runbook](../Microsoft%20Entra/Microsoft%20Entra%20Device%20Tenant%20Migration%20Runbook.md) for `dsregcmd /leave` and record-cleanup steps.

---

## Reading the Logs

The error dialog is always generic. The real cause is in the generalize-pass logs, which Sysprep writes outside the standard Setup log locations:

```powershell
notepad C:\Windows\System32\Sysprep\Panther\setuperr.log   # short list of failures
notepad C:\Windows\System32\Sysprep\Panther\setupact.log   # full verbose trace
```

Start with `setuperr.log`. Specialize-pass logs live in `%WINDIR%\Panther`, and OOBE logs in `%WINDIR%\Panther\Unattendgc`.

---

## Where This Workflow Should Go

Sysprep works for this, but **Autopilot pre-provisioning (White Glove)** is purpose-built for it and removes the Sysprep step entirely:

1. Boot the new device to OOBE
2. Press the Windows key 5× to enter pre-provisioning
3. Intune pushes all device-targeted apps and policies on your bench
4. Reseal, box, ship
5. User signs in — only user-targeted content runs

No hand-installing Office, no Sysprep, no Appx errors. Worth piloting on the next device that gives you the excuse.

Also worth evaluating: **Windows Autopilot device preparation**, the newer registration model that drops the hardware-hash harvest entirely in favour of a device-preparation policy and an Entra group.

---

## Quick Reference

| Scenario | Command |
|---|---|
| One machine → one client, ship it | `sysprep.exe /oobe /shutdown` |
| Verify OOBE before boxing | `sysprep.exe /oobe /reboot` |
| Capturing an image for multiple machines | `sysprep.exe /oobe /generalize /shutdown` |
| VHD returning to the **same** hypervisor and hardware profile | `sysprep.exe /oobe /generalize /shutdown /mode:vm` |

**Rule of thumb:** if the OS stays on the hardware it was built on, you don't need `/generalize`.

---

## Related Notes

- [Entra Device Tenant-to-Tenant Migration Runbook](../Microsoft%20Entra/Microsoft%20Entra%20Device%20Tenant%20Migration%20Runbook.md) — unjoining, `dsregcmd`, and Autopilot deregistration
- [Zero to Hero — Part 3: Intune Enrollment Configuration](./Zero%20to%20Hero/Part%203%20-%20Intune%20Enrollment%20Configuration.md) — automatic enrollment and enrollment restrictions
- [Microsoft Intune Enrollment and Credential Service Principal Check](./Microsoft%20Intune%20Enrollment%20and%20Credential%20Service%20Principal%20Check.md) — CA exclusions for enrollment and PRT acquisition

---

## Sources

- Microsoft Learn: [Sysprep Command-Line Options](https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/sysprep-command-line-options)
- Microsoft Learn: [Sysprep Process Overview](https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/sysprep-process-overview)
- Microsoft Learn: [Sysprep (Generalize) a Windows installation](https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/sysprep--generalize--a-windows-installation)
- Microsoft Learn: [Boot Windows to Audit Mode or OOBE](https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/boot-windows-to-audit-mode-or-oobe)
- Microsoft Learn: [Manually register devices with Windows Autopilot](https://learn.microsoft.com/en-us/autopilot/add-devices)
- Microsoft Learn: [BitLocker overview](https://learn.microsoft.com/en-us/windows/security/operating-system-security/data-protection/bitlocker/)
- Microsoft Learn: [BitLocker drive encryption in Windows 11 for OEMs](https://learn.microsoft.com/en-us/windows-hardware/design/device-experiences/oem-bitlocker)
