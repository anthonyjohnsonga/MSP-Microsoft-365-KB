# OneDrive Over-Quota Report Script — Quick Guide

> **Script Source:** [PnP Script Samples — Identify OneDrive Users Over License-Based Storage Quota](https://pnp.github.io/script-samples/onedrive-overquota-report/README.html?tabs=graphps)

---

## Connection Requirements

**Microsoft Graph only** — no SharePoint Online Management Shell, no PnP PowerShell required. The script uses `Connect-MgGraph` from the `Microsoft.Graph.Authentication` module.

### Required Modules

```powershell
Install-Module Microsoft.Graph.Authentication -Scope CurrentUser
Install-Module Microsoft.Graph.Users -Scope CurrentUser
```

Or let the script handle it automatically:

```powershell
.\Get-ODBOverQuotaUsers.ps1 -InstallPrerequisites
```

### Required Delegated Scopes

These are prompted at login. First run may require Global Admin consent.

| Scope | Purpose |
|---|---|
| `User.Read.All` | Read user profiles |
| `Directory.Read.All` | Read directory data |
| `Reports.Read.All` | Pull OneDrive usage report (FastScan) |
| `Sites.Read.All` | Read OneDrive site metadata |
| `Files.Read.All` | Read drive quota info |

**Minimum M365 Role:** Global Reader (least privilege — script is strictly read-only)

---

## Basic Usage Examples

**Standard run (FastScan, console output only):**
```powershell
.\Get-ODBOverQuotaUsers.ps1
```

**Export all results to CSV:**
```powershell
.\Get-ODBOverQuotaUsers.ps1 -ExportPath "C:\Reports\OneDriveQuotaReport.csv"
```

> ⚠️ Always use a **full path** for `-ExportPath`. Relative paths in elevated shells resolve to `C:\WINDOWS\system32`.

**MSP / multi-tenant — target a specific client:**
```powershell
.\Get-ODBOverQuotaUsers.ps1 -TenantId "clienttenant.onmicrosoft.com" -ExportPath "C:\Reports\ClientReport.csv"
```

**Spot-check a specific user:**
```powershell
.\Get-ODBOverQuotaUsers.ps1 -UserPrincipalName user@domain.com -ExportPath "C:\Reports\Spotcheck.csv"
```

**Multiple users:**
```powershell
.\Get-ODBOverQuotaUsers.ps1 -UserPrincipalName alice@domain.com,bob@domain.com -ExportPath "C:\Reports\Spotcheck.csv"
```

**Slower but real-time data (bypasses daily report cache):**
```powershell
.\Get-ODBOverQuotaUsers.ps1 -LegacyScan -ExportPath "C:\Reports\OneDriveQuotaReport.csv"
```

---

## CSV Output Columns

The exported CSV contains **all evaluated sites**, sorted with over-quota rows first. Key columns to filter on in Excel:

| Column | Description |
|---|---|
| `OverQuota` | **TRUE/FALSE** — filter here first |
| `LicenseTier` | e.g., "Enterprise (5 TB)", "A1 (100 GB)" |
| `StorageUsed` / `StorageUsedMB` | Human-readable + raw MB for pivot tables |
| `ExpectedQuota` / `CurrentQuota` | License entitlement vs. provisioned quota |
| `OverBy` / `OverByMB` | How far over (blank if under) |
| `AssignedSKUs` | Comma-separated SKU part numbers |

---

## Scan Mode Cheat Sheet

| Mode | Switch | Speed | Data Freshness | Notes |
|---|---|---|---|---|
| FastScan | *(default)* | Fast | ~24–48h lag | Fails if tenant reports are anonymized |
| LegacyScan | `-LegacyScan` | Slow | Real-time | Works regardless of anonymization |
| TargetedUser | `-UserPrincipalName` | Instant | Real-time | Single or multiple UPNs |

---

## All Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `-ExportPath` | string | *(none)* | Full path for CSV export (e.g. `C:\Reports\report.csv`) |
| `-TenantId` | string | *(home tenant)* | Tenant ID (GUID) or verified domain — required for multi-tenant/MSP |
| `-Environment` | string | `Global` | `Global`, `USGov` (GCC High), `USGovDoD`, or `China` |
| `-UserPrincipalName` | string[] | *(none)* | One or more UPNs to evaluate; bypasses FastScan/LegacyScan |
| `-LegacyScan` | switch | off | Per-user enumeration — slower but real-time |
| `-InstallPrerequisites` | switch | off | Auto-install missing Graph modules to current-user scope |

---

## License Quota Tiers

The script flags users where `StorageUsed > ExpectedQuota` based on their highest assigned license tier.

| Tier | Expected Quota | Typical SKUs |
|---|---|---|
| Enterprise | 5 TB | E3, E5, A3, A5, Plan 2 |
| Standard | 1 TB | Plan 1, Multi-Geo |
| Lite / A1 (EDU) | 100 GB | OneDrive Lite, Office 365 A1 |
| BasicP2 | 10 GB | Basic 2 |
| Viral / Basic | 5 GB | Office for the web, Basic |
| Deskless | 2 GB | F1, F3, Kiosk |

> **Note:** Enterprise users are **never flagged as over quota** — usage above 5 TB is treated as a legitimate tenant-level storage boost or admin exception.

---

## Common Gotchas (MSP Use)

**Anonymized reports** — If FastScan fails with `ANONYMIZED REPORTS DETECTED`, go to:
M365 Admin Center → Settings → Org Settings → Reports → turn off "Display concealed user names in all reports"
Or use `-LegacyScan` to bypass the Reports API entirely.

**GCC High tenants** — Add `-Environment USGov` to all commands.

**Delegated admin / GDAP** — You must include `-TenantId` pointing to the customer tenant. Without it, the script targets your home/MSP tenant.

**Running as Administrator** — Don't use relative paths for `-ExportPath`. Use a full drive path like `C:\Reports\report.csv` to avoid the `system32` resolution issue.

**Unlicensed accounts with OneDrive** — The script flags these as over quota whenever `StorageUsed > 0`, which is useful for identifying retained offboarded accounts.
