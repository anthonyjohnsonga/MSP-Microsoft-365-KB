# Install Windows Updates with PowerShell

**Applies to:** Windows 11; Windows 10 under an applicable support arrangement; Windows PowerShell 5.1<br>
**Scope:** Install approved updates locally using the community PSWindowsUpdate module<br>
**Last Updated:** October 2026

---

## Overview

Open an elevated **Windows PowerShell 5.1** session on the affected endpoint. Use `PSWindowsUpdate` to scan, review, and install updates, then verify installation and arrange any required restart.

PSWindowsUpdate is a community module published by Michal Gajda, not a built-in Microsoft cmdlet. This guide uses local execution on the endpoint; it does not configure PowerShell remoting or fleet deployment. Commands were reviewed against documentation but were not executed on an endpoint during preparation.

## Prerequisites

| Requirement | Detail |
|---|---|
| Permissions | Local administrator rights or an authorized SYSTEM session on the target endpoint. Confirm the computer and execution identity before installing anything. |
| Module approval | The customer permits PSWindowsUpdate from PowerShell Gallery. Review and approve the module version through your normal software process. |
| Update policy | Check Intune update rings, Windows Update for Business, WSUS, and RMM patch policy. Use this procedure only within the customer's approved patching process. |
| Connectivity | Access to PowerShell Gallery for module installation and the permitted update service for scan/download. SYSTEM sessions can have different proxy access from signed-in users. |
| Maintenance | Approved update scope and maintenance window, saved user work, and a recovery plan. Confirm remote access can reconnect after restart. |
| Licensing | No additional Microsoft 365 license is needed for the commands. Windows servicing entitlement and any Intune/RMM licensing still apply. |

**MSP note:** Select one pilot endpoint per relevant customer configuration. Record the hostname, module version, chosen update source, installed KBs, results, and reboot status in the service ticket. Keep customer identifiers and diagnostic output out of this repository.

---

## 1. Confirm the Endpoint and PowerShell Session

Run locally on the target endpoint:

```powershell
hostname.exe
whoami.exe
$PSVersionTable.PSVersion
Get-ExecutionPolicy -List
```

Use Windows PowerShell 5.1 for this runbook. Verify the session identity and administrative privileges before proceeding.

If execution policy blocks the approved module, and organizational policy permits it, set a temporary policy for this session only:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned
```

Group Policy takes precedence. Do not change machine-wide policy to `Unrestricted` or bypass an enforced policy to continue. Closing this PowerShell process removes its process-scoped setting.

## 2. Check, Install, and Import the Module

1. Check for an existing installation:

   ```powershell
   Get-Module -ListAvailable -Name PSWindowsUpdate |
       Select-Object Name, Version, ModuleBase
   ```

2. If missing, install the customer-approved module. The following retrieves the version currently available from PSGallery; use an approved version with `-RequiredVersion` where your process requires version pinning:

   ```powershell
   Install-Module -Name PSWindowsUpdate -Repository PSGallery -Scope AllUsers
   ```

   Review any NuGet-provider or repository prompts. Do not globally mark a repository trusted just to suppress prompts. An unattended RMM job needs these dependencies prepared through the customer's software process.

3. Import and inspect the available commands:

   ```powershell
   Import-Module PSWindowsUpdate -ErrorAction Stop
   Get-Module PSWindowsUpdate | Select-Object Name, Version
   Get-Help Get-WindowsUpdate -Full
   Get-Help Install-WindowsUpdate -Full
   ```

## 3. Select the Update Source and Review Updates

1. Inspect the registered services and scan using the configured default source:

   ```powershell
   Get-WUServiceManager
   Get-WindowsUpdate
   ```

2. If the approved task explicitly requires **Microsoft Update**, check that it is registered and that policy permits its use. If registration is needed and approved:

   ```powershell
   Add-WUServiceManager -MicrosoftUpdate
   ```

3. Scan that source:

   ```powershell
   Get-WindowsUpdate -MicrosoftUpdate
   ```

4. Review titles, KBs, update types, and expected disruption before installation. Microsoft Update can offer updates for other Microsoft products; it does not update every installed application. Do not assume all offered drivers, previews, or feature updates are approved.

**Managed-update caveat:** Do not add Microsoft Update or choose an alternate source to evade WSUS approvals, update deferrals, or customer policy. If the source is restricted, stop and resolve the task through the managing system.

## 4. Install Approved Updates and Control the Restart

For an interactive session, omit `-AcceptAll` to review the module's acceptance prompts and select only approved updates. This example uses Microsoft Update; omit `-MicrosoftUpdate` to retain the configured default source:

```powershell
Install-WindowsUpdate -MicrosoftUpdate -IgnoreReboot -Verbose
```

Only when **all updates offered by the chosen scan are approved**, use the original draft's acceptance behavior with explicit module reboot suppression:

```powershell
Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot -Verbose
```

`-IgnoreReboot` prevents this module from initiating the restart; it does not cancel independent Windows, Intune, or RMM restart policies. Keep the session open until installation finishes and retain the results in the ticket.

For a maintenance task that explicitly permits an automatic restart after installation, use this alternative **instead of** the preceding install command:

```powershell
Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -AutoReboot -Verbose
```

Expect the remote session to disconnect. Do not combine `-AutoReboot` and `-IgnoreReboot`.

## 5. Verify Installation and Reboot Status

```powershell
Get-WUHistory | Select-Object -First 20
Get-WURebootStatus -Silent
```

The silent reboot-status check returns a Boolean. If a restart is needed, arrange it in the approved window, reconnect afterward, and scan the same source again. Additional updates can become applicable after a restart.

## Verification / Testing Checklist

- [ ] The correct endpoint, administrative context, and approved module version were confirmed.
- [ ] The scan used the approved update source and updates were reviewed before acceptance.
- [ ] Installation results and history show the intended updates succeeded; failures were recorded.
- [ ] Any required restart completed and remote access recovered.
- [ ] A follow-up scan of the same source was reviewed for remaining applicable updates.
- [ ] Key user applications and endpoint services work after maintenance.
- [ ] The PowerShell session was closed to remove any process-scoped execution-policy change.

## Recovery and Rollback

There is no single rollback for a batch of Windows updates. Identify the failing KB and use its Microsoft release notes and supported uninstall/recovery procedure; some updates cannot be removed. Confirm backups and the customer's recovery path before installation rather than relying on uninstall availability.

If Microsoft Update registration was added solely for this task, record the prior service configuration and return it to the customer's intended configuration through the managing policy or an approved service-removal procedure. Do not remove a service that was already registered before the task. Removing PSWindowsUpdate does not uninstall installed Windows updates.

## Troubleshooting

| Symptom | Check / next action |
|---|---|
| Module installation fails | Check repository availability, NuGet/provider prerequisites, TLS/proxy access, and whether the module is permitted. Capture the error before changing settings. |
| Module import is blocked | Inspect `Get-ExecutionPolicy -List` and organizational application-control policy. A process setting cannot override Group Policy. |
| Access denied during scan or installation | Verify local administrative/SYSTEM context. Run locally on the endpoint; this guide does not assume remote Windows Update API access is permitted. |
| Microsoft Update is unavailable | Inspect `Get-WUServiceManager` and effective update-source policy. Register it only if approved. |
| No updates found | Check the selected source, applicability, approvals/deferrals, and pending restart state. Compare with the customer's patch-management reports. |
| Installation fails or remains pending | Record the update title, KB, result/error code, and reboot state. Follow the relevant Microsoft update troubleshooting guidance. |
| Remote access disconnects | Check whether a restart occurred and whether the endpoint reconnects. Verify history after reconnection before retrying installation. |

---

## Sources

- PowerShell Gallery, Michal Gajda: [PSWindowsUpdate](https://www.powershellgallery.com/packages/PSWindowsUpdate/2.2.1.5) — community module, command list, and version information. Use the installed module's help for parameter details.
- Microsoft Learn: [About execution policies](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies)
- Microsoft Learn: [Get started with PowerShell Gallery](https://learn.microsoft.com/en-us/powershell/gallery/getting-started)
