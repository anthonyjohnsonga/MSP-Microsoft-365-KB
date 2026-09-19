# Deploy PDFgear 2.1.20 with Microsoft Intune

**Applies to:** Microsoft Intune, Windows 11, PDFgear 2.1.20  
**Scope:** Package, deploy, detect, update, and remove PDFgear 2.1.20 as an Intune Win32 application.  
**Last Updated:** September 2026

---

This runbook documents the tested packaging and deployment of **PDFgear 2.1.20** as a Microsoft Intune Win32 application.

> [!IMPORTANT]
> The commands and registry values in this guide were validated against `pdfgear_setup_v2.1.20.exe`. Revalidate the installer, uninstall entry, silent switches, architecture, and detection data before packaging any later release.

## Validated deployment facts

| Item | Validated value |
|---|---|
| Installer | `pdfgear_setup_v2.1.20.exe` |
| Installer technology | Inno Setup |
| Install context | System / machine-wide |
| Install folder | `C:\Program Files\PDFgear` |
| Silent install result | Exit code `0` |
| Restart required in test | No |
| Uninstaller | `C:\Program Files\PDFgear\unins000.exe` |
| Silent uninstall result | Exit code `0` |
| Uninstall cleanup in test | `C:\Program Files\PDFgear` removed |
| Display name | `PDFgear 2.1.20` |
| Display version | `2.1.20` |
| Uninstall registry key | `HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall\{7DACF63A-4EE4-4837-9AF9-C65D4509FFB4}_is1` |
| Registry view | 64-bit |

## Recommended folder layout

Keep the source directory clean. Files such as logs, previous installers, and the Microsoft Win32 Content Prep Tool should not be placed in `Source`, because the tool packages the entire source directory.

```text
C:\IntuneApps\PDFgear\
├── Source\
│   └── pdfgear_setup_v2.1.20.exe
├── Output\
└── IntuneWinAppUtil.exe
```

## 1. Validate the installer locally

Perform validation on a disposable test device or virtual machine. Run PowerShell as an administrator.

### Inspect the file

Record the hash and verify the digital signature before deployment:

```powershell
Get-FileHash `
    -Path 'C:\IntuneApps\PDFgear\Source\pdfgear_setup_v2.1.20.exe' `
    -Algorithm SHA256

Get-AuthenticodeSignature `
    -FilePath 'C:\IntuneApps\PDFgear\Source\pdfgear_setup_v2.1.20.exe' |
    Select-Object Status, StatusMessage, SignerCertificate
```

Do not copy a hash from another environment. Record the hash of the exact installer that will be packaged.

### Test the silent install

```powershell
$installer = 'C:\IntuneApps\PDFgear\Source\pdfgear_setup_v2.1.20.exe'
$log = 'C:\IntuneApps\PDFgear\PDFgear-install.log'
$arguments = @(
    '/VERYSILENT'
    '/SUPPRESSMSGBOXES'
    '/NORESTART'
    '/SP-'
    "/LOG=`"$log`""
)

$process = Start-Process `
    -FilePath $installer `
    -ArgumentList $arguments `
    -Wait `
    -PassThru

Write-Host "Exit code: $($process.ExitCode)"
Get-Content -Path $log -Tail 30
```

The validated test returned exit code `0`, logged `Installation process succeeded`, and reported `Need to restart Windows? No`.

The production Intune install command intentionally omits `/LOG`. Intune Management Extension already records execution details. Add installer logging through a wrapper only if the organization has defined a writable, managed log location.

### Confirm the installed application and uninstall data

```powershell
Test-Path -Path 'C:\Program Files\PDFgear'

$uninstallKey = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\{7DACF63A-4EE4-4837-9AF9-C65D4509FFB4}_is1'

Get-ItemProperty -Path $uninstallKey |
    Select-Object DisplayName, DisplayVersion, InstallLocation, UninstallString, QuietUninstallString
```

Expected values for the tested package:

```text
DisplayName          : PDFgear 2.1.20
DisplayVersion       : 2.1.20
InstallLocation      : C:\Program Files\PDFgear\
UninstallString      : "C:\Program Files\PDFgear\unins000.exe"
QuietUninstallString : "C:\Program Files\PDFgear\unins000.exe" /SILENT
```

### Test the silent uninstall

```powershell
$uninstaller = 'C:\Program Files\PDFgear\unins000.exe'

$process = Start-Process `
    -FilePath $uninstaller `
    -ArgumentList '/SILENT', '/NORESTART' `
    -Wait `
    -PassThru

Write-Host "Exit code: $($process.ExitCode)"
Test-Path -Path 'C:\Program Files\PDFgear'
```

The validated test returned exit code `0`, and `Test-Path` returned `False`.

`/SILENT /NORESTART` is retained as the production uninstall command because it is the exact command that was tested. Inno Setup also supports `/VERYSILENT` and `/SUPPRESSMSGBOXES`, but a changed command should be validated before production use.

## 2. Package the installer

Download the current Microsoft Win32 Content Prep Tool from its official repository and place `IntuneWinAppUtil.exe` outside the source folder.

Run:

```powershell
Set-Location -Path 'C:\IntuneApps\PDFgear'
.\IntuneWinAppUtil.exe
```

Provide these answers:

```text
Source folder: C:\IntuneApps\PDFgear\Source
Setup file:    pdfgear_setup_v2.1.20.exe
Output folder: C:\IntuneApps\PDFgear\Output
Catalog folder: N
```

Expected output:

```text
C:\IntuneApps\PDFgear\Output\pdfgear_setup_v2.1.20.intunewin
```

## 3. Create the Win32 application

In the Intune admin center, go to:

**Apps** > **Windows** > **Create** > **Windows app (Win32)**

Upload `pdfgear_setup_v2.1.20.intunewin`.

### App information

| Field | Value |
|---|---|
| Name | `PDFgear 2.1.20` |
| Description | `PDFgear is a PDF application for viewing, editing, converting, merging, signing, and annotating PDF documents.` |
| Publisher | `PDFgear` |
| App version | `2.1.20` |
| Category | `Productivity` |
| Show as featured app | `No` |
| Information URL | `https://www.pdfgear.com/` |
| Privacy URL | `https://www.pdfgear.com/privacy-policy/` |
| Developer | `PDFgear` |

Using the version in the app name makes supersedence, rollback, reporting, and package ownership clearer. If the organization uses a generic display name, retain the version in the **App version** field and in internal documentation.

### Program

| Setting | Value |
|---|---|
| Install command | `pdfgear_setup_v2.1.20.exe /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP-` |
| Uninstall command | `"C:\Program Files\PDFgear\unins000.exe" /SILENT /NORESTART` |
| Installation time required | `15` minutes |
| Allow available uninstall | `Yes` if Company Portal users should be allowed to remove an Available assignment; otherwise follow organizational policy |
| Install behavior | `System` |
| Device restart behavior | `No specific action` |

The install command uses documented Inno Setup switches:

- `/VERYSILENT` hides the wizard and progress window.
- `/SUPPRESSMSGBOXES` suppresses suppressible message boxes when used with a silent mode.
- `/NORESTART` prevents Setup from restarting Windows.
- `/SP-` disables the initial startup prompt.

### Return codes

The default Intune table may be retained:

| Return code | Code type |
|---:|---|
| `0` | Success |
| `1707` | Success |
| `3010` | Soft reboot |
| `1641` | Hard reboot |
| `1618` | Retry |

For this Inno Setup package, `0` is the validated success result. Inno Setup documents any nonzero setup exit code as an incomplete installation. The additional Intune defaults are primarily relevant to Windows Installer behavior and are harmless here, but they are not evidence that PDFgear returns those codes. Do not map Inno Setup exit code `8` to success or reboot; it indicates Setup could not proceed.

### Requirements

| Setting | Value |
|---|---|
| Operating system architecture | `64-bit` |
| Minimum operating system | Use the organization's supported Windows baseline |
| Other requirements | Leave blank unless required by organizational policy |

The tested package installed in 64-bit mode under `C:\Program Files` and wrote to the 64-bit HKLM uninstall registry view, so the 64-bit requirement is appropriate for this package.

The original deployment used **Windows 10 22H2** as the minimum. That remains a valid targeting choice only for organizations intentionally managing eligible Windows 10 devices, such as devices covered by Extended Security Updates. It must not be described as a generally supported Windows baseline: standard Windows 10 22H2 support ended on October 14, 2025. For a new deployment, select the organization's currently supported Windows 11 baseline unless a documented Windows 10 exception applies.

## 4. Configure detection

### Baseline rule for the immutable 2.1.20 package

Use **Manually configure detection rules** and add a **Registry** rule:

| Setting | Value |
|---|---|
| Key path | `HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Uninstall\{7DACF63A-4EE4-4837-9AF9-C65D4509FFB4}_is1` |
| Value name | `DisplayVersion` |
| Detection method | `String comparison` |
| Operator | `Equals` |
| Value | `2.1.20` |
| Associated with a 32-bit app on 64-bit clients | `No` |

This exact rule is technically correct for a version-locked PDFgear 2.1.20 app. It answers the narrow question, “Is the installed version exactly the version represented by this Intune app?”

It is not an evergreen detection rule. If PDFgear is upgraded to a later version and the same uninstall key remains, `DisplayVersion` will no longer equal `2.1.20`. Intune can then consider the 2.1.20 app absent. Do not leave an independently Required 2.1.20 deployment in scope after moving devices to a newer release unless the supersedence and assignment behavior has been tested.

### About the GUID uninstall key

The key suffix is not an MSI product code. Inno Setup derives the uninstall key name from the installer's `AppId` and appends `_is1`. The key will normally remain stable across releases only if PDFgear keeps the same `AppId` and registry view.

Therefore:

- The GUID key is reliable for the tested 2.1.20 installer.
- Do not assume a future installer will use the same GUID, registry view, display name, or uninstaller filename.
- Inspect the uninstall registry after installing every new version in a test environment.
- If the GUID changes, update the detection rule and uninstall strategy for the new Intune app.

### Optional resilient detection for a minimum version

Use this only when the intended policy is “PDFgear 2.1.20 or later is acceptable,” rather than exact-version compliance. A custom script avoids dependence on one uninstall-key GUID and checks both 64-bit and 32-bit uninstall locations.

Save the following as `Detect-PDFgear.ps1`:

```powershell
$minimumVersion = [version]'2.1.20'
$registryPaths = @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
)

$detectedApp = Get-ItemProperty -Path $registryPaths -ErrorAction SilentlyContinue |
    Where-Object {
        $_.DisplayName -match '^PDFgear(?:\s|$)' -and
        -not [string]::IsNullOrWhiteSpace($_.DisplayVersion)
    } |
    Where-Object {
        try {
            [version]$_.DisplayVersion -ge $minimumVersion
        }
        catch {
            $false
        }
    } |
    Select-Object -First 1

if ($null -ne $detectedApp) {
    Write-Output "Detected $($detectedApp.DisplayName), version $($detectedApp.DisplayVersion)"
    exit 0
}

exit 1
```

Configure the Intune custom detection script with:

| Setting | Value |
|---|---|
| Run script as 32-bit process on 64-bit clients | `No` |
| Enforce script signature check | Follow organizational signing policy |

Intune considers a custom detection script successful only when it exits with code `0` **and** writes data to standard output. The script deliberately writes output only when a qualifying installation is found.

> [!NOTE]
> The resilient script is not automatically “better.” Exact detection is preferable when each Intune app represents one controlled release and supersedence is used. Minimum-version detection is preferable when later versions installed by another trusted process should satisfy the same assignment.

## 5. Dependencies and supersedence

For the initial 2.1.20 deployment:

- **Dependencies:** None were required in the validated test.
- **Supersedence:** None for the first PDFgear package.

The installer launched `RegExt.exe` with an `-installWebView2` parameter during the validated installation. That shows the installer handles that action; it does not, by itself, prove that a separate Intune WebView2 dependency is required. Add a dependency only if testing demonstrates a need.

## 6. Assign and pilot

1. Assign the app as **Required** to a small device pilot group.
2. Do not assign it broadly until install, detection, launch, update, and uninstall behavior are confirmed.
3. Avoid assigning the same group simultaneously under conflicting intents such as **Required** and **Uninstall**.
4. Review the final configuration, create the app, and sync a pilot device.

Validate on the pilot device:

```powershell
Test-Path -Path 'C:\Program Files\PDFgear'

Get-ItemProperty `
    -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\{7DACF63A-4EE4-4837-9AF9-C65D4509FFB4}_is1' |
    Select-Object DisplayName, DisplayVersion, InstallLocation, QuietUninstallString
```

Also confirm:

- PDFgear launches for a standard user.
- The Intune device install status reports **Installed**.
- The detection rule remains successful after a restart and another device sync.
- Required PDF functionality works in the organization's security configuration.
- The uninstall action succeeds if the deployment design requires it.

## 7. Deploy future PDFgear versions safely

Treat every new PDFgear installer as a new package until it has been proven compatible with the prior deployment.

1. Download the installer from the vendor-approved source.
2. Record its SHA-256 hash and validate its digital signature.
3. Test a clean silent install and capture an installer log.
4. Install it over 2.1.20 and verify whether it performs an in-place upgrade.
5. Reinspect both uninstall registry views. Record the `AppId`-derived key, `DisplayVersion`, install location, uninstall string, and quiet uninstall string.
6. Test silent uninstall and reinstall on a disposable system.
7. Build a new `.intunewin` package and a new, versioned Intune Win32 app.
8. Give the new app a detection rule that matches its intended policy:
   - Use exact `DisplayVersion` equality for a version-specific app.
   - Use version comparison or a validated custom script only when later versions should also count as installed.
9. Configure the new app to supersede 2.1.20.
10. For a normal in-place update, leave **Uninstall previous version** set to **No** after confirming the new installer upgrades the old version correctly. Set it to **Yes** only when testing shows that the old version must be removed first.
11. Pilot the upgrade, including devices where PDFgear is running, and verify detection after upgrade.
12. Expand assignments in stages and retain the prior package long enough to support rollback.

Do not merely replace the `.intunewin` content while leaving an old install command or detection rule unchanged. If an in-place content update is intentionally used, update the package, command, metadata, and detection rule as one controlled change and test the loss of straightforward rollback.

## 8. Troubleshooting

### Installation reports success but Intune reports not detected

- Confirm the key path includes the backslash before the GUID: `...\Uninstall\{GUID}_is1`.
- Confirm the registry rule uses the 64-bit view: **Associated with a 32-bit app on 64-bit clients = No**.
- Confirm `DisplayVersion` is exactly `2.1.20` when using string equality.
- If another updater installed a newer version, exact 2.1.20 detection should fail by design.
- Inspect `IntuneManagementExtension.log` under `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs`.

### Installation repeatedly runs

The detection rule is false or inconsistent. Check the registry view, the key GUID, and `DisplayVersion`. Also check whether a newer PDFgear version has replaced the value while the old 2.1.20 app remains independently Required.

### Installation fails without visible UI

Reproduce the command locally with `/LOG="C:\Path\PDFgear-install.log"`, then inspect the log and the exit code. Inno Setup exit codes `1` through `8` indicate initialization, cancellation, fatal, preparation, or restart-blocked failures; they are not successful installations.

### Uninstall is not fully complete when the process returns

Inno Setup's uninstaller launches a temporary clone so that it can delete itself. A small amount of cleanup can still be running when the original uninstaller returns. If a replacement workflow immediately needs the old files to be absent, test the timing and use a wrapper that waits for the relevant process or path state with a bounded timeout.

### A later release uses a different GUID

Create the new detection rule from the new installer's actual uninstall data. Do not copy the 2.1.20 GUID into the new app. If the superseding package must remove an older release whose uninstall path is uncertain, use a carefully tested wrapper that discovers the registered quiet uninstall command rather than guessing a key or filename.

## Sources

- [Add, assign, and monitor a Win32 app in Microsoft Intune](https://learn.microsoft.com/en-us/intune/intune-service/apps/apps-win32-add)
- [Win32 app supersedence in Microsoft Intune](https://learn.microsoft.com/en-us/intune/intune-service/apps/apps-win32-supersedence)
- [Windows 10 release information and support status](https://learn.microsoft.com/en-us/windows/release-health/release-information)
- [Inno Setup command-line parameters](https://jrsoftware.org/ishelp/topic_setupcmdline.htm)
- [Inno Setup setup exit codes](https://jrsoftware.org/ishelp/topic_setupexitcodes.htm)
- [Inno Setup uninstaller parameters](https://jrsoftware.org/ishelp/topic_uninstcmdline.htm)
- [Inno Setup uninstaller exit codes](https://jrsoftware.org/ishelp/topic_uninstexitcodes.htm)
- [Inno Setup `AppId` and uninstall key behavior](https://jrsoftware.org/ishelp/topic_setup_appid.htm)
