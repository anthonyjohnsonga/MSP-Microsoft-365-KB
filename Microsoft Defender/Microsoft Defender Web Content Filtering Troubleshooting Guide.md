# Microsoft Defender Web Content Filtering Troubleshooting Guide

**Applies to:** Microsoft Defender for Endpoint Plan 1/Plan 2 and Defender for Business, including Microsoft 365 Business Premium; Windows endpoints  
**Scope:** Reference for diagnosing website blocks in Edge and Chrome and applying an approved website exception  
**Last Updated:** November 2026

## Purpose

Use this reference when a website displays **“This content is blocked by your organization”** in Edge, or a Defender notification or connection error in Chrome. Establish which protection feature blocked the request before changing policy.

**Sanitized case example:** Access to `https://portal.example.com` resumed after an Allow indicator propagated. This illustrates one resolution; it does not establish the cause of every browser error.

## Access and prerequisites

Web Content Filtering is available with Defender for Endpoint Plan 1/Plan 2 and Defender for Business. Endpoint advanced hunting has separate licensing requirements; use the [KQL reference](./Microsoft%20Defender%20Network%20Protection%20KQL%20Hunting%20Guide.md) for those requirements and query examples.

Use an account authorized for the affected devices and intended task. Under Defender unified RBAC, viewing policies and reports requires **Security operations > Security data > Security data basics (read)**; managing policies and Allow indicators requires **Security operations > Security data > Response (manage)**. Legacy RBAC differs; consult the [Web Content Filtering prerequisites](https://learn.microsoft.com/en-us/defender-endpoint/web-content-filtering#prerequisites).

**MSP note:** Verify the customer tenant before inspecting or changing an indicator. Defender for Business supports one Web Content Filtering policy applied to all users, without per-device policy scope. Do not assume another customer's licensing, scope options, or policy assignments apply here.

## 1. Recognize the symptom

- **Edge:** Record the SmartScreen block-page wording and URL.
- **Chrome:** Record any Windows Security notification and browser error. An SSL or connection error alone proves neither a Defender block nor a website TLS fault.
- Record the exact URL, redirects, affected device, browser, and reproduction time. Use a consistent time zone when comparing local and cloud events.

## 2. Read the Network Protection configuration

On the affected Windows device, open PowerShell:

```powershell
Get-MpPreference | Select-Object EnableNetworkProtection
```

| Value | Configured mode |
|---|---|
| `0` | Disabled |
| `1` | Block |
| `2` | Audit |

A value of `1` reports the configured mode. It does not prove that prerequisites are satisfied or that Network Protection blocked this request. For non-Edge web indicators, check Defender Antivirus active mode, behavior monitoring, cloud protection and connectivity, and Network Protection Block mode. These requirements are documented in the [indicator reference](https://learn.microsoft.com/en-us/defender-endpoint/indicator-ip-domain#prerequisites).

## 3. Read matching local events

Run this after reproducing the issue, using an account with access to the log:

```powershell
$targetDomain = 'example.com'
Get-WinEvent -FilterHashtable @{
    LogName   = 'Microsoft-Windows-Windows Defender/Operational'
    Id        = 1126
    StartTime = (Get-Date).AddMinutes(-10)
} |
Where-Object { $_.Message -match [regex]::Escape($targetDomain) } |
Select-Object TimeCreated, Id, Message |
Format-List
```

Replace `example.com` with the affected domain. The text match can include unrelated hosts containing that text; inspect the actual destination and process in each event.

Event ID **1126** records a Network Protection block; **1125** records an audit event. A matching event establishes that Network Protection enforced a block at that time. A no-events message differs from an access or log-reading error. Neither proves that the request succeeded.

Edge uses SmartScreen for web filtering. A missing Network Protection event does not rule out an Edge block.

## 4. Identify the blocking feature

Where endpoint hunting is available, use **Microsoft Defender portal > Hunting > Advanced hunting** and the [Network Protection KQL Hunting Guide](./Microsoft%20Defender%20Network%20Protection%20KQL%20Hunting%20Guide.md). Correlate the device, URL, and time with the failed request.

An illustrative Network Protection event is:

```text
ActionType       = ExploitGuardNetworkProtectionBlocked
ResponseCategory = CustomPolicy
RemoteUrl        = https://portal.example.com
```

`CustomPolicy` maps to **Web Content Filtering**, but does not identify the blocked content category or assigned policy name. `CustomBlockList` points to custom indicators; `CasbPolicy` points to Defender for Cloud Apps. `Malicious` and `Phishing` indicate web threat protection. See Microsoft's [response category reference](https://learn.microsoft.com/en-us/defender-endpoint/web-protection-overview#troubleshoot-endpoint-blocks).

Review **Settings > Endpoints > Rules > Web content filtering** for the applicable policy. Use **Reports > Web protection** for category and domain reporting. If hunting is unavailable, combine reporting, policy assignments, local events, and browser evidence; do not assume every organizational block is WCF.

For Edge, investigate `SmartScreenUrlWarning` events and the `Experience` field using Microsoft's [Edge hunting example](https://learn.microsoft.com/en-us/defender-endpoint/web-protection-overview#advanced-hunting-for-web-protection).

## 5. Create an approved website exception

Use an Allow indicator only after confirming the business need, site trust, and intended policy exception. Allow indicators can override other web protection blocks as well as WCF; document the reason and review date.

1. In **Settings > Endpoints > General > Advanced features**, confirm **Custom network indicators** is enabled.
2. Open **Settings > Endpoints > Rules > Indicators > URLs/Domains** and select **Add item**.
3. Enter the required host, such as `portal.example.com`, and set **Action = Allow**. Add a descriptive title, justification, and an appropriate expiry where applicable.
4. Review the available organizational scope. Choose the narrowest supported device-group scope and confirm its membership. If the tenant offers only all-device scope, assess that impact before saving.
5. Review and save the indicator.

For HTTPS in Chrome, plan around the hostname; do not assume an exception for a URL path has the same granularity as in Edge. Check redirects and dependent hosts individually rather than allowing the entire parent domain by default.

Keep Network Protection and Web Content Filtering enabled. A category reassessment may be preferable when the site is incorrectly classified; the [Web Content Filtering documentation](https://learn.microsoft.com/en-us/defender-endpoint/web-content-filtering) describes category disputes.

## 6. Interpret propagation and retest results

Microsoft's [indicator documentation](https://learn.microsoft.com/en-us/defender-endpoint/indicator-ip-domain) states that changes usually take effect in under two hours but can take up to 48 hours. Do not treat two hours as a guaranteed deadline.

An Intune sync or antivirus signature update should not be treated as proof that an indicator has arrived. Retest the exact URL in the affected browser and compare new events with the recorded test time. Historical blocks remain in local logs and hunting results.

| Observation | Interpretation and next reference point |
|---|---|
| Fresh matching Event 1126 and failed access | Network Protection still blocked the request. Review the event reason, indicator action, expiry, scope, and delivery. |
| Site opens and no matching fresh block | Supports restored access for this device and test; does not by itself prove which policy caused the change. |
| Site fails with no matching Event 1126 | Check Edge SmartScreen evidence where applicable, telemetry health, redirects, proxy, DNS, TLS, and other controls. |

## 7. Restore temporary settings or remove the exception

If troubleshooting changed security settings, restore the recorded baseline in the policy that owns them. For current Microsoft Edge, **PreventSmartScreenPromptOverride** controls whether users can bypass SmartScreen website warnings. Review it under **Microsoft Edge > SmartScreen settings** and confirm the effective setting at `edge://policy`. Do not assume an older Windows **Browser** policy controls current Edge.

To roll back this exception, remove the specific Allow indicator, or restore its prior action, scope, and expiry if you edited an existing indicator. Allow for propagation and retest. Removing an exception may restore the original block; leave the underlying protection enabled.

## Sources

- Microsoft Learn: [Web Content Filtering](https://learn.microsoft.com/en-us/defender-endpoint/web-content-filtering)
- Microsoft Learn: [Web Content Filtering in Defender for Business](https://learn.microsoft.com/en-us/defender-business/mdb-web-content-filtering)
- Microsoft Learn: [Create indicators for IPs and URLs/domains](https://learn.microsoft.com/en-us/defender-endpoint/indicator-ip-domain)
- Microsoft Learn: [Network protection](https://learn.microsoft.com/en-us/defender-endpoint/network-protection)
- Microsoft Learn: [Web protection and response categories](https://learn.microsoft.com/en-us/defender-endpoint/web-protection-overview)
- Microsoft Learn: [Network Protection events in Windows Event Viewer](https://learn.microsoft.com/en-us/defender-endpoint/attack-surface-reduction-windows-events)
- Microsoft Learn: [PreventSmartScreenPromptOverride](https://learn.microsoft.com/en-us/deployedge/microsoft-edge-browser-policies/preventsmartscreenpromptoverride)
