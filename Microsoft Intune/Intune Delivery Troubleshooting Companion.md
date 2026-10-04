# Intune Delivery Troubleshooting Companion

**Applies to:** Supported Windows devices enrolled in Microsoft Intune with applicable MDM or Intune Management Extension workloads  
**Scope:** Diagnose delayed policy, app, script, compliance, and inventory delivery on one pilot device before wider remediation  
**Last Updated:** October 4, 2026

Start at **Intune admin center > Devices > All devices > select device > Sync**, then check **Device sync status** and the relevant workload report. Record the action time and inspect client evidence before repeating Sync. See the preserved [delivery PDF](./Intune%20Faster%20Delivery.pdf) and [detailed fact check](./Intune%20Faster%20Delivery%20Fact%20Check.md) for timing qualifications.

## Prerequisites

| Requirement | Detail |
|---|---|
| Licensing | Appropriate Intune user/device licensing, commonly Intune Plan 1 or a suite containing it. Standard sync needs no Intune Suite add-on. Check separate Remediations licensing before using that feature. |
| Portal access | Help Desk Operator or a scoped custom role with Remote tasks/Sync devices and device read access. Assignment edits and diagnostic collection need their own permissions. |
| Local access | Use elevated Windows PowerShell for protected logs, service checks, and the optional IME restart. Run user-context join checks in the affected user's session. |
| Client | Supported Windows, Intune enrollment, correct Entra registration/join, and IME installed for applicable workloads. Record the installed version rather than assuming rollout from tenant release alone. |
| MSP scope | Confirm the customer tenant, cloud, tenant region, scope tags, device record, and user. Treat sovereign-cloud endpoints and rollout separately. |

**Validation status:** Commands were reviewed and syntax-checked locally. Delivery behavior has not been tested in a customer tenant or lab. The read-only checks below do not modify enrollment or assignments.

## 1. Identify Where the Delay Occurs

1. Confirm the device is awake and online. Match its identity to the portal record; avoid an old duplicate record.
2. Record the last check-in, target app/policy, assignment time, group membership, exclusions, filters, and user/device targeting.
3. Check **Tenant administration > Tenant status** and customer service-health notices. Record the tenant location for endpoint selection.
4. Separate these milestones: notification received, assignment received, workload evaluated, change applied, result uploaded, portal updated. Stop at the first missing milestone.

| Workload | Evidence to start with |
|---|---|
| Settings / MDM policy | Device configuration status and MDM Admin event log |
| Win32 app | Assignment, requirements, install scheduling, detection, AppWorkload.log |
| Platform script | Script status, execution context, AgentExecutor.log |
| Custom compliance | Discovery output and JSON rules, HealthScripts.log, downloaded-script age |
| App inventory | Properties catalog assignment and All Apps > App Inventory timestamps |

## 2. Request One Sync and Observe

1. Use **Devices > All devices > select device > Sync**. Follow the portal confirmation if shown.
2. Inspect **Device sync status**. The new device view is the default in the 2609 release notes; older documentation may still mention a preview toggle.
3. At the device, **Company Portal > Settings > Sync** is another supported route. Current Microsoft documentation also describes MDM and IME check-ins from **Settings > Accounts > Access work or school > select account > Info > Sync**.
4. Compare log timestamps with the request. A completed sync does not prove an installer finished or that every policy succeeded. Use the specific app or policy report and verify the effective local state.

Source: [Microsoft Sync action](https://learn.microsoft.com/en-us/intune/device-management/actions/sync).

## 3. Check Enrollment and Agent Health

In the affected user's session:

```powershell
dsregcmd /status
```

Match the join type to the intended deployment. An MDM URL alone does not prove successful enrollment; confirm the connected management account and fresh portal check-in. Keep raw identity output private.

In elevated Windows PowerShell:

```powershell
Get-Service -Name IntuneManagementExtension -ErrorAction SilentlyContinue |
    Select-Object Name, Status, StartType

$agentPath = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Intune Management Extension\Microsoft.Management.Services.IntuneWindowsAgent.exe'
if (-not (Test-Path -LiteralPath $agentPath)) {
    $agentPath = Join-Path $env:ProgramFiles 'Microsoft Intune Management Extension\Microsoft.Management.Services.IntuneWindowsAgent.exe'
}
if (Test-Path -LiteralPath $agentPath) {
    (Get-Item -LiteralPath $agentPath).VersionInfo |
        Select-Object FileVersion, ProductVersion
}
```

IME absence can be expected when no applicable workload requires it. If it should be installed, check eligibility, assignment, and service connectivity. Do not manually repackage the IME installer. On co-managed devices, verify that the apps workload is assigned to Intune or Pilot Intune.

## 4. Check WNS and IME Connectivity

Use the current [Microsoft endpoint requirements](https://learn.microsoft.com/en-us/intune/fundamentals/endpoints). WNS requires outbound TCP 443 to `*.notify.windows.com` and `*.wns.windows.com`; IME also needs regional service/CDN and Trouter endpoints. These are part of the full endpoint list.

1. Identify the tenant's region. Inspect proxy/firewall logs at the sync timestamp.
2. Look for blocked DNS, proxy authentication failures, TLS failures, and interrupted long-lived connections. A successful interactive-user browser test does not prove the service account can connect.
3. Test an exact hostname seen in logs, never a wildcard:

```powershell
netsh winhttp show proxy

# Commercial North America example; replace with the endpoint for this tenant.
$endpointHost = 'go-amer.trouter.communications.svc.cloud.microsoft'
Resolve-DnsName -Name $endpointHost
Test-NetConnection -ComputerName $endpointHost -Port 443
```

TCP success proves only reachability, not authenticated application traffic or notification delivery. Review the real service/proxy trace. Microsoft excludes SSL inspection for specified management/attestation endpoints and requires HTTP partial responses for IME content endpoints. Apply narrowly scoped rules from the official tables through customer change control; retain the previous configuration for rollback.

## 5. Correlate Logs with the Request

IME logs normally reside in `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs`. Use CMTrace or a text viewer; include rolled logs if the incident predates the current file.

| Log | Look for |
|---|---|
| IntuneManagementExtension.log | Check-in, authentication, policy retrieval, reporting |
| NotificationInfra.log | Notification-channel receipt and errors; availability varies by client |
| AppWorkload.log | Assignment evaluation, download, install, detection, reporting |
| AppActionProcessor.log | Applicability and detection decisions |
| AgentExecutor.log | Platform-script execution and errors |
| HealthScripts.log | Remediation/custom-compliance script processing |
| ClientHealth.log / ClientCertCheck.log | Agent health and certificate problems |

Source: [Microsoft Win32 troubleshooting](https://learn.microsoft.com/en-us/intune/app-management/deployment/troubleshoot-win32).

```powershell
$logRoot = 'C:\ProgramData\Microsoft\IntuneManagementExtension\Logs'
if (Test-Path -LiteralPath $logRoot) {
    Get-ChildItem -LiteralPath $logRoot -File |
        Sort-Object LastWriteTime -Descending |
        Select-Object Name, LastWriteTime, Length
}

$since = (Get-Date).AddMinutes(-30)
Get-WinEvent -FilterHashtable @{
    LogName = 'Microsoft-Windows-DeviceManagement-Enterprise-Diagnostics-Provider/Admin'
    StartTime = $since
} -ErrorAction SilentlyContinue |
    Select-Object TimeCreated, Id, LevelDisplayName, Message
```

In Event Viewer, use **Applications and Services Logs > Microsoft > Windows > DeviceManagement-Enterprise-Diagnostics-Provider > Admin**. Correlate the exact policy/app and timestamps rather than treating every logged error as this incident. Log timestamps can use different time zones; normalize them before comparing. Source: [Collect MDM logs](https://learn.microsoft.com/en-us/windows/client-management/mdm-collect-logs).

## 6. Resolve the Workload-Specific Cause

| Symptom | Next action |
|---|---|
| MDM sync succeeds, app has no assignment | Verify groups, exclusions, filters, user context, applicability, and co-management ownership. |
| App assignment received, installation delayed | Check availability/deadline, dependencies, requirements, download failures, restart state, and return codes. Push does not bypass these controls. |
| App installed, Intune reports failure | Reproduce detection in the configured architecture/context; check the upload result before repackaging. |
| Successful platform script does not rerun | Expected unless script/policy or applicable context changes. Use a deliberate revision or properly licensed Remediations for recurring work. |
| Custom compliance remains stale | Use Company Portal's Check compliance/check-access flow for the downloaded script; it does not retrieve an updated script. Validate JSON and wait for documented retrieval/reporting cadence. |
| Built-in compliance remains stale | Check the actual setting, policy error, and any relevant attestation dependency. Do not weaken the compliance rule to make reporting green. |
| Inventory missing | Confirm ApplicationProperties assignment, supported join/enrollment, and **All Apps > App Inventory**. Five-minute lab uploads are not a portal-update SLA. |

See [platform-script rules](https://learn.microsoft.com/en-us/intune/device-management/tools/run-powershell-scripts-windows), [custom compliance behavior](https://learn.microsoft.com/en-us/intune/device-security/compliance/custom-settings), and [app inventory setup](https://learn.microsoft.com/en-us/intune/app-management/deployment/enhanced-app-inventory).

## 7. Controlled Recovery and Rollback

After saving evidence, an IME restart can initiate a check-in. Coordinate it on the pilot device when an installation or script is not actively running:

```powershell
Restart-Service -Name IntuneManagementExtension -ErrorAction Stop
Get-Service -Name IntuneManagementExtension
```

Verify the service returns to Running and fresh logs show the intended work. A restart has no persistent configuration to roll back and does not repair every enrollment issue. Do not repeatedly restart it or delete its registry state, caches, enrollment certificates, or scheduled tasks to force delivery.

For any assignment, detection, script, or network change, save the previous values, change one variable in a pilot group, and restore the prior configuration if results worsen. Do not use Wipe, Retire, unenrollment, or a broad compliance exclusion as a delivery diagnostic.

## Verification Checklist

- [ ] Correct customer tenant, device, user, cloud, and region confirmed.
- [ ] Notification/check-in and assignment processing observed with timestamps.
- [ ] Effective local setting, app detection, or script outcome verified.
- [ ] Result upload and portal report independently checked.
- [ ] Custom compliance and inventory expectations match documented limitations.
- [ ] Temporary diagnostic changes reverted; pilot scope retained until validated.

## 8. Escalation Evidence

Keep device identifiers, tenant details, raw logs, and diagnostic packages in the customer's approved private support location. For escalation, include OS/IME versions, action time and time zone, affected workload, sanitized error codes, assignment/filter details, network path, and a comparison with a working device. Export the relevant MDM events and IME logs; use the portal's app **Installation details > Collect logs** when available. Attach raw packages privately to the support case, never to this public KB.

## Sources

- Microsoft Learn: [Sync device action](https://learn.microsoft.com/en-us/intune/device-management/actions/sync)
- Microsoft Learn: [Intune Management Extension](https://learn.microsoft.com/en-us/intune/device-management/tools/management-extension-windows)
- Microsoft Learn: [Network endpoints](https://learn.microsoft.com/en-us/intune/fundamentals/endpoints)
- Microsoft Learn: [Win32 app troubleshooting](https://learn.microsoft.com/en-us/intune/app-management/deployment/troubleshoot-win32)
- Microsoft Learn: [Collect MDM logs](https://learn.microsoft.com/en-us/windows/client-management/mdm-collect-logs)
- Microsoft Learn: [Platform scripts](https://learn.microsoft.com/en-us/intune/device-management/tools/run-powershell-scripts-windows)
- Microsoft Learn: [Custom compliance](https://learn.microsoft.com/en-us/intune/device-security/compliance/custom-settings)
- Microsoft Learn: [App inventory](https://learn.microsoft.com/en-us/intune/app-management/deployment/enhanced-app-inventory)
- Microsoft Learn: [Remediations and licensing](https://learn.microsoft.com/en-us/intune/device-management/tools/deploy-remediations)
- Microsoft Learn: [What's new in Intune](https://learn.microsoft.com/en-us/intune/whats-new/)
