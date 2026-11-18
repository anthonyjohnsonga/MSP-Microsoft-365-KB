# Microsoft Defender Network Protection KQL Hunting Guide

**Applies to:** Microsoft Defender for Endpoint with endpoint advanced hunting access; Windows endpoints  
**Scope:** Read-only KQL query reference for Network Protection blocks, response fields, and local event correlation  
**Last Updated:** November 2026

## Purpose

Use these standalone queries in **Microsoft Defender portal > Hunting > Advanced hunting** to investigate website blocks enforced by **Microsoft Defender Network Protection**. The examples use `example.com`; replace it with the domain you need to investigate.

**Data source:** `DeviceEvents` in Microsoft Defender for Endpoint. Advanced Hunting events can arrive later than events recorded locally on the device, and historical events remain visible after a policy is fixed.

## Access and data requirements

Endpoint advanced hunting requires an eligible license, such as Defender for Endpoint Plan 2, and onboarded devices sending telemetry. Defender for Business, including the version bundled with Microsoft 365 Business Premium, does not include the same endpoint advanced hunting capability; see Microsoft's [plan comparison](https://learn.microsoft.com/en-us/defender-business/mdb-overview).

Your account needs permission to read endpoint hunting data for the relevant devices. Endpoint RBAC and device scope determine which results you can see. See [advanced hunting access](https://learn.microsoft.com/en-us/defender-xdr/advanced-hunting-overview#get-access). An empty result can reflect scope, missing telemetry, or the chosen filters.

**MSP note:** Confirm the customer tenant and device scope before running a query. These examples do not automatically search every managed tenant. Keep customer identifiers and exported event details out of shared documentation.

All examples only read data; no policy changes or rollback are required.

## Query 1 — Find Network Protection blocks for a domain

```kusto
DeviceEvents
| where Timestamp > ago(24h)
| where ActionType == "ExploitGuardNetworkProtectionBlocked"
| where RemoteUrl contains "example.com"
| project Timestamp, DeviceName, ActionType, RemoteUrl, AdditionalFields
| order by Timestamp desc
```

**What each line does**

| Command | Explanation |
|---|---|
| `DeviceEvents` | Reads Defender for Endpoint device event telemetry. |
| `where Timestamp > ago(24h)` | Limits the search to the past 24 hours. Adjust as needed. |
| `where ActionType == ...` | Selects Network Protection **blocked** events (not just warnings). |
| `where RemoteUrl contains ...` | Looks for the domain text in the destination URL. `contains` is a substring search, not an exact-domain validator. |
| `project ...` | Displays only the chosen columns. |
| `order by Timestamp desc` | Lists newest events first. |

**Use it when:** You first need to establish whether Network Protection blocked the URL, on which device, and when.

## Query 2 — Identify the blocking feature

```kusto
DeviceEvents
| where Timestamp > ago(24h)
| where ActionType == "ExploitGuardNetworkProtectionBlocked"
| where RemoteUrl contains "example.com"
    or AdditionalFields contains "example.com"
| extend Details = parse_json(AdditionalFields)
| project Timestamp,
          DeviceName,
          ActionType,
          RemoteUrl,
          ResponseCategory = tostring(Details.ResponseCategory),
          DisplayName = tostring(Details.DisplayName),
          AdditionalFields
| order by Timestamp desc
```

**New commands and fields**

| Item | Explanation |
|---|---|
| `or` | Matches if the domain is in either the URL or the event's additional details. |
| `extend Details = parse_json(AdditionalFields)` | Converts the JSON text in `AdditionalFields` to a structured value. |
| `tostring(Details.ResponseCategory)` | Extracts the classification/reason recorded for the block as readable text. |
| `tostring(Details.DisplayName)` | Extracts the policy/domain label, if populated. |
| `AdditionalFields` | Retains the original JSON for verification and additional context. |

**Illustrative event with placeholder values**

```text
ActionType       = ExploitGuardNetworkProtectionBlocked
RemoteUrl        = https://portal.example.com
ResponseCategory = CustomPolicy
DisplayName      = uri=example.com
IsAudit          = false
```

**How to interpret it**

- `ExploitGuardNetworkProtectionBlocked`: Network Protection enforced a block.
- `CustomPolicy`: Microsoft maps this response to Web Content Filtering (WCF). It does **not** identify the specific blocked content category or assigned policy name.
- `DisplayName = uri=example.com`: The domain label associated with the decision. It does **not** prove that an Allow indicator for the subdomain `portal.example.com` is incorrect.
- `IsAudit = false`: The recorded event was an enforced block, not an audit-only event.

Common response values are documented in Microsoft's [web protection reference](https://learn.microsoft.com/en-us/defender-endpoint/web-protection-overview#troubleshoot-endpoint-blocks):

| ResponseCategory | Blocking feature |
|---|---|
| `CustomPolicy` | Web Content Filtering |
| `CustomBlockList` | Custom indicators |
| `CasbPolicy` | Defender for Cloud Apps |
| `Malicious` or `Phishing` | Web threat protection |

Fields can be absent or empty. Retain `AdditionalFields` to inspect the actual payload; `DisplayName` is not a reliable policy identifier.

## Query 3 — Monitor a fresh test across devices

```kusto
DeviceEvents
| where Timestamp > ago(30m)
| where ActionType == "ExploitGuardNetworkProtectionBlocked"
| where RemoteUrl contains "example.com"
| extend Details = parse_json(AdditionalFields)
| project Timestamp,
          DeviceName,
          RemoteUrl,
          ResponseCategory = tostring(Details.ResponseCategory),
          DisplayName = tostring(Details.DisplayName)
| order by Timestamp desc
```

**What changed from Query 2?**

- `ago(30m)` limits results to a shorter period.
- `DeviceName` remains in the output to compare affected computers; it is also present in Query 2.
- The smaller `project` list focuses on recent blocks and their response fields. Unlike Query 2, this example searches only `RemoteUrl`.

**Important:** A 30-minute window still includes older events inside that window. To test a recent change, record the **exact test time**, reproduce the issue, and compare timestamps. Advanced Hunting ingestion may be delayed.

## Optional — Search by one specific device

Add this line after the `DeviceEvents` line in any query:

```kusto
| where DeviceName =~ "example-device"
```

`=~` is a **case-insensitive equality** comparison. Replace `example-device` with the exact `DeviceName` shown in telemetry, which can be a fully qualified name such as `example-device.example.com`.

## Interpreting results after a change

Compare events with the exact reproduction time and affected device. Use a consistent time zone when comparing hunting timestamps with local PowerShell output. Old block records remain searchable after a policy change; their presence does not mean the current request is blocked.

A successful browser test, healthy reporting, and no matching fresh block events together support a resolution. No rows alone do not prove success: filters, device scope, ingestion delays, or a different enforcement component can hide the relevant event.

An approved Allow indicator can provide a web filtering exception, but choosing remediation depends on the blocking feature and intended policy. This reference does not require creating an exception to run its queries.

## Local Windows event reference

For local evidence while cloud telemetry arrives, use Windows PowerShell on the affected computer with permission to read the log:

```powershell
Get-WinEvent -FilterHashtable @{
    LogName   = 'Microsoft-Windows-Windows Defender/Operational'
    Id        = 1126
    StartTime = (Get-Date).AddMinutes(-10)
} |
Where-Object { $_.Message -match 'example\.com' } |
Select-Object TimeCreated, Id, Message |
Format-List
```

Event ID `1126` records Network Protection blocks; `1125` records audit events. This PowerShell query filters the local Defender Operational log by time and domain text. A no-events message differs from an access or log-reading error; neither establishes that the browser request succeeded.

## Troubleshooting reminders

- **Network Protection Block mode** is compatible with targeted Allow indicators; you don't normally need to disable it.
- **Edge SmartScreen bypass settings** do not override enforced organizational Web Content Filtering blocks.
- A Chrome `ERR_SSL_VERSION_OR_CIPHER_MISMATCH` error can accompany an enforced network block, but does not, by itself, prove that Defender caused the TLS error.
- **Do not infer the specific content category from `CustomPolicy`.** Review WCF policy and reporting for that detail.

## Query coverage notes

The queries select Network Protection blocks only. Edge web protection can instead produce `SmartScreenUrlWarning` events; use Microsoft's [web protection hunting examples](https://learn.microsoft.com/en-us/defender-endpoint/web-protection-overview#advanced-hunting-for-web-protection) when investigating Edge.

`contains "example.com"` is a broad text match: it can also match unrelated hosts such as `notexample.com` or a URL path containing that text. Inspect the returned destination before attributing a block to a domain.

## Related reference

- [Microsoft Defender SmartScreen & Network Protection](./Microsoft%20Defender%20Smartscreen%20Network%20Protection.md)

## Sources

- Microsoft Learn: [Network protection](https://learn.microsoft.com/en-us/defender-endpoint/network-protection)
- Microsoft Learn: [Web protection and response categories](https://learn.microsoft.com/en-us/defender-endpoint/web-protection-overview)
- Microsoft Learn: [DeviceEvents table](https://learn.microsoft.com/en-us/defender-xdr/advanced-hunting-deviceevents-table)
- Microsoft Learn: [Advanced hunting overview and access](https://learn.microsoft.com/en-us/defender-xdr/advanced-hunting-overview)
- Microsoft Learn: [Defender for Business feature comparison](https://learn.microsoft.com/en-us/defender-business/mdb-overview)
- Microsoft Learn: [Attack surface reduction events in Windows Event Viewer](https://learn.microsoft.com/en-us/defender-endpoint/attack-surface-reduction-windows-events)
