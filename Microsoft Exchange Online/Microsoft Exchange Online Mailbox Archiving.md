# Exchange Online Mailbox Archiving

### Helpdesk Technician Reference

> **Applies to:** Microsoft 365 Exchange Online  
> **Last updated:** May 2026  
> **Graph API reference verified with:** Microsoft Graph API Index (27,700+ endpoints)

---

## Table of Contents

1. [Overview](#1-overview)
2. [Archive Types Explained](#2-archive-types-explained)
3. [Enable or Disable a Mailbox Archive](#3-enable-or-disable-a-mailbox-archive)
4. [Archive Storage Limits](#4-archive-storage-limits)
5. [Auto-Expanding Archive](#5-auto-expanding-archive)
6. [How Users Access the Archive](#6-how-users-access-the-archive)
7. [Archive Policies and Retention Tags](#7-archive-policies-and-retention-tags)
8. [Managing the Archive with Microsoft Graph API](#8-managing-the-archive-with-microsoft-graph-api)
9. [Troubleshooting](#9-troubleshooting)
10. [Quick Reference](#10-quick-reference)

---

## 1. Overview

Exchange Online mailbox archiving provides users with additional storage for older email, keeping their primary mailbox clean while ensuring email is retained and searchable. The archive appears as a separate mailbox in Outlook alongside the user's primary mailbox.

**Why enable archiving?**

- Extends effective mailbox storage without increasing the primary mailbox quota
- Keeps the primary mailbox performant by moving older items out
- Satisfies compliance and records retention requirements
- Items in the archive are still discoverable via Microsoft Purview eDiscovery and Content Search

> **Note:** The archive mailbox is separate from the primary mailbox but is accessed from the same Outlook profile. It is not the same as a backup — it is a live mailbox that users can access and search.

---

## 2. Archive Types Explained

| Archive Type | Description | Storage Limit |
|-------------|-------------|--------------|
| **Online Archive (In-Place Archive)** | A secondary mailbox attached to the user's primary mailbox. Enabled per user in the EAC or PowerShell. | 50 GB (Plan 1) / Unlimited (Plan 2, E3, E5) |
| **Auto-Expanding Archive** | Automatically grows beyond 50 GB when the archive fills up. Requires Exchange Online Plan 2 or Microsoft 365 E3/E5. | Unlimited (up to 1.5 TB in practice) |

> **Important:** Auto-expanding archive cannot be disabled once it has been enabled on a mailbox.

---

## 3. Enable or Disable a Mailbox Archive

### Enable via the Exchange Admin Center (EAC)

1. Go to `https://admin.exchange.microsoft.com`.
2. In the left navigation, click **Recipients** → **Mailboxes**.
3. Select the user mailbox you want to enable archiving for.
4. In the details pane, click the **Mailbox** tab.
5. Click **Manage mailbox archive**.
6. Toggle **Archive mailbox** to **Enabled**.
7. Click **Save**.

The archive mailbox is created immediately. It may take up to 30 minutes to appear in Outlook.

### Disable via the Exchange Admin Center (EAC)

> **Warning:** Disabling the archive does not delete the archive mailbox or its contents immediately. The archive enters a soft-disabled state. If re-enabled within 30 days, the content is restored. After 30 days, the archive content may be permanently deleted.

1. Follow steps 1–5 above.
2. Toggle **Archive mailbox** to **Disabled**.
3. Click **Save**.

### Enable via PowerShell

```powershell
# Connect first
Connect-ExchangeOnline -UserPrincipalName admin@contoso.com

# Enable archive for a single user
Enable-Mailbox -Identity "user@contoso.com" -Archive

# Enable archive for all users who do not already have one
Get-Mailbox -ResultSize Unlimited -Filter "ArchiveStatus -eq 'None'" |
  Enable-Mailbox -Archive

# Disable archive for a single user
Disable-Mailbox -Identity "user@contoso.com" -Archive
```

### Enable Archive for a Shared Mailbox

Shared mailboxes can also have an archive enabled, but the behavior differs from user mailboxes:

- A shared mailbox archive **requires a license** to use auto-expanding archive (Exchange Online Plan 2 or Microsoft 365 E3/E5 assigned to the shared mailbox).
- Without a license, the shared mailbox archive is capped at 50 GB.
- The archive is enabled the same way as a user mailbox — via EAC or PowerShell.

```powershell
# Enable archive for a shared mailbox
Enable-Mailbox -Identity "support@contoso.com" -Archive

# Check archive status of a shared mailbox
Get-Mailbox -Identity "support@contoso.com" | Select DisplayName, ArchiveStatus, RecipientTypeDetails
```

> **Note:** `Get-MailboxStatistics -Archive` works for shared mailboxes that have been licensed. For unlicensed shared mailboxes, this cmdlet may return an error — check `ArchiveStatus` with `Get-Mailbox` instead.

### Check Archive Status via PowerShell

```powershell
# Check archive status for a single user
Get-Mailbox -Identity "user@contoso.com" | Select DisplayName, ArchiveStatus, ArchiveDatabase

# List all users with an active archive
Get-Mailbox -ResultSize Unlimited | Where-Object { $_.ArchiveStatus -eq "Active" } |
  Select DisplayName, PrimarySmtpAddress, ArchiveStatus

# Get the size of a user's archive mailbox
Get-MailboxStatistics -Identity "user@contoso.com" -Archive |
  Select DisplayName, TotalItemSize, ItemCount
```

---

## 4. Archive Storage Limits

The archive mailbox storage limit depends on the user's license.

| License | Archive Storage | Notes |
|---------|----------------|-------|
| Exchange Online Plan 1 | 50 GB | No auto-expanding archive |
| Exchange Online Plan 2 | Unlimited (auto-expanding) | Auto-expanding enabled by default |
| Microsoft 365 Business Basic / Standard | 50 GB | No auto-expanding archive |
| Microsoft 365 Business Premium | Unlimited (auto-expanding) | Includes Exchange Online Plan 2; auto-expanding enabled by default |
| Microsoft 365 E1 | 50 GB | No auto-expanding archive |
| Microsoft 365 E3 / E5 | Unlimited (auto-expanding) | Auto-expanding enabled by default |

> **Tip:** If a user's archive is approaching 50 GB and they are on Plan 1, E1, or Business Basic/Standard, upgrade their license to Plan 2, Business Premium, or E3/E5 to unlock auto-expanding archive.

### View Archive Quota and Usage

```powershell
# View archive quota settings
Get-Mailbox -Identity "user@contoso.com" |
  Select ArchiveQuota, ArchiveWarningQuota, AutoExpandingArchiveEnabled

# View archive mailbox size
Get-MailboxStatistics -Identity "user@contoso.com" -Archive |
  Select TotalItemSize, ItemCount, DeletedItemCount
```

---

## 5. Auto-Expanding Archive

Auto-expanding archive allows the archive mailbox to grow automatically beyond 50 GB without manual intervention. Once the archive reaches its initial quota, Exchange Online automatically provisions additional storage.

### Enable Auto-Expanding Archive

**For a single mailbox:**
```powershell
Enable-Mailbox -Identity "user@contoso.com" -AutoExpandingArchive
```

**For the entire organization (all mailboxes):**
```powershell
Set-OrganizationConfig -AutoExpandingArchive
```

**Check if auto-expanding archive is enabled:**
```powershell
Get-Mailbox -Identity "user@contoso.com" |
  Select AutoExpandingArchiveEnabled

# Check the organization-wide setting
Get-OrganizationConfig | Select AutoExpandingArchiveEnabled
```

> **Important:** Auto-expanding archive **cannot be disabled** once enabled on a mailbox or organization. Plan carefully before enabling organization-wide.

> **Note:** After the initial 100 GB archive fills up, Exchange Online automatically provisions additional auxiliary storage. This first expansion can take up to 30 days to trigger. Subsequent expansions happen automatically without additional delay.

---

## 6. How Users Access the Archive

### In Outlook Desktop (Windows / Mac)

Once the archive is enabled, it appears automatically in the Outlook folder pane as a second mailbox labeled **Online Archive — [user's name]** or **In-Place Archive — [user's name]**.

- Users can drag and drop items between the primary mailbox and archive.
- Users can create folders within the archive.
- Search in Outlook includes the archive mailbox by default.

> **Note:** If the archive does not appear in Outlook after 30 minutes, restart Outlook. If it still does not appear, confirm the archive is enabled in the EAC and that the user's Outlook profile is connected to Exchange Online (not a cached offline-only profile).

### In Outlook on the Web (OWA)

1. Sign in at `https://outlook.office.com`.
2. In the left folder pane, scroll down below the primary mailbox folders.
3. The archive appears as **In-Place Archive** below the main folder list.
4. Click to expand and browse archive folders.

### Outlook Mobile

The archive mailbox is not directly accessible in the Outlook mobile app. Users who need to access archived items should use Outlook on the Web or Outlook Desktop.

---

## 7. Archive Policies and Retention Tags

Archiving works hand-in-hand with **Messaging Records Management (MRM)** — a set of retention policies and tags that automatically move items from the primary mailbox to the archive based on age.

### How Retention Tags Work

| Tag Type | Description |
|----------|-------------|
| **Default Policy Tag (DPT)** | Applies to all items in the mailbox that don't have another tag applied |
| **Retention Policy Tag (RPT)** | Applies to specific default folders (Inbox, Sent Items, Deleted Items, etc.) |
| **Personal Tag** | Applied manually by users to items or folders |

### Common Archive Actions

| MRM Action | What Happens |
|-----------|-------------|
| **MoveToArchive** | Moves items to the archive mailbox after the specified number of days |
| **DeleteAndAllowRecovery** | Soft-deletes items (recoverable for 14 days) |
| **PermanentlyDelete** | Hard-deletes items — not recoverable |

### Assign a Retention Policy to a Mailbox

1. In the EAC, go to **Recipients** → **Mailboxes**.
2. Select the user mailbox.
3. Click the **Mailbox** tab → **Manage retention policy**.
4. Select the desired retention policy from the list.
5. Click **Save**.

**Via PowerShell:**
```powershell
# Assign a retention policy to a mailbox
Set-Mailbox -Identity "user@contoso.com" -RetentionPolicy "Default MRM Policy"

# View the current retention policy on a mailbox
Get-Mailbox -Identity "user@contoso.com" | Select RetentionPolicy

# Force the Managed Folder Assistant to run immediately (instead of waiting for scheduled run)
Start-ManagedFolderAssistant -Identity "user@contoso.com"
```

> **Note:** The Managed Folder Assistant (MFA) runs on a schedule — typically once every 7 days per mailbox. Use `Start-ManagedFolderAssistant` to force an immediate run when testing.

### Retention Hold vs. Litigation Hold

| Hold Type | Purpose | Effect on MRM | Who Controls It |
|-----------|---------|--------------|----------------|
| **Retention Hold** | Temporarily pauses MRM policy processing (e.g., user on leave) | Pauses MoveToArchive and delete actions | Helpdesk / Exchange Admin |
| **Litigation Hold** | Preserves all mailbox content for legal or compliance purposes | Does not pause MRM, but prevents permanent deletion | Legal / Compliance team |

> **Important:** Litigation Hold and Retention Hold can be active at the same time. Litigation Hold does not pause archiving — items will still move to the archive. It simply ensures nothing is permanently deleted while the hold is active.

### Place a Mailbox on Retention Hold

```powershell
# Enable retention hold
Set-Mailbox -Identity "user@contoso.com" -RetentionHoldEnabled $true

# Disable retention hold
Set-Mailbox -Identity "user@contoso.com" -RetentionHoldEnabled $false

# Check if a mailbox is on retention hold
Get-Mailbox -Identity "user@contoso.com" | Select RetentionHoldEnabled
```

### Bulk-Populate the Archive (PST Import)

If you need to migrate historical email into a user's archive mailbox in bulk, use the **PST Import** feature in the Microsoft Purview compliance portal.

1. Go to `compliance.microsoft.com` → **Data lifecycle management** → **Import**.
2. Create a new import job and choose **Upload your files** (network upload) or **Ship a drive** (physical drive).
3. Map the PST file to the target user and set the destination to their **archive mailbox**.
4. Complete the import job wizard.

> **Note:** PST import requires a Microsoft 365 E3/E5 license or a Microsoft Purview add-on. For large migrations, contact your Microsoft partner or use a Microsoft-approved third-party migration tool.

---

## 8. Managing the Archive with Microsoft Graph API

> **API reference sourced from the Microsoft Graph API index (27,700+ endpoints, updated weekly).**

### Install the Microsoft Graph PowerShell Module

1. Open **PowerShell 7** (`pwsh`) as Administrator.
2. Run the following command:

```powershell
Install-Module -Name Microsoft.Graph -Force -AllowClobber
```

3. If prompted to install from an untrusted repository, type `Y` and press **Enter**.
4. The module will download and install. This may take a few minutes as it includes multiple sub-modules.

**Keep the module up to date:**
```powershell
Update-Module -Name Microsoft.Graph
```

### Connect to Microsoft Graph

```powershell
Connect-MgGraph -Scopes "Mail.Read"
Connect-MgGraph -Scopes "Mail.ReadWrite"
Connect-MgGraph -Scopes "Mail.Read", "Mail.ReadWrite"
```

**Verify your connection:**
```powershell
Get-MgContext
```

**Disconnect when finished:**
```powershell
Disconnect-MgGraph
```

### Required Permissions

| Permission Type | Permission Scope | Use Case |
|----------------|-----------------|----------|
| Delegated (work account) | `Mail.Read` | Read the signed-in user's mailbox settings and archive folder |
| Delegated (work account) | `Mail.ReadWrite` | Read and modify mail folders and messages in the archive |
| Application | `Mail.Read` | Read any user's mailbox settings (admin context) |
| Application | `Mail.ReadWrite` | Read and modify any user's mail folders and messages |

### Get Mailbox Settings

```
GET /users/{user-id}/mailboxSettings
```

```powershell
$settings = Invoke-MgGraphRequest -Method GET `
  -Uri "https://graph.microsoft.com/v1.0/users/john.smith@contoso.com/mailboxSettings"
$settings.archiveFolder
```

### List Mail Folders

```
GET /users/{user-id}/mailFolders/archive
GET /users/{user-id}/mailFolders/archive/childFolders
```

```powershell
Invoke-MgGraphRequest -Method GET `
  -Uri "https://graph.microsoft.com/v1.0/users/john.smith@contoso.com/mailFolders/archive"

Invoke-MgGraphRequest -Method GET `
  -Uri "https://graph.microsoft.com/v1.0/users/john.smith@contoso.com/mailFolders/archive/childFolders"
```

### List Messages in the Archive

```powershell
Invoke-MgGraphRequest -Method GET `
  -Uri "https://graph.microsoft.com/v1.0/users/john.smith@contoso.com/mailFolders/archive/messages?`$top=10&`$select=subject,from,receivedDateTime&`$orderby=receivedDateTime desc"
```

### Permanently Delete Items

```
POST /users/{user-id}/messages/{message-id}/permanentDelete
POST /users/{user-id}/mailFolders/{mailFolder-id}/permanentDelete
```

> **Warning:** Without a hold in place, deletion is immediate and irreversible. Only perform this with explicit authorization.

---

## 9. Troubleshooting

### Archive Not Appearing in Outlook

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| Archive not showing after 30 min | Outlook not synced | Restart Outlook; check Exchange connectivity |
| Archive shows but is empty | Archive is new | Wait for Managed Folder Assistant or run `Start-ManagedFolderAssistant` |
| Archive missing entirely | Archive not enabled | Verify in EAC or run `Get-Mailbox | Select ArchiveStatus` |
| Archive not visible in OWA | Browser cache | Clear cache and reload |

### Items Not Moving to Archive

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| Items not moving | MFA hasn't run | `Start-ManagedFolderAssistant -Identity "user@contoso.com"` |
| No retention policy | Default policy missing | `Set-Mailbox -Identity "user@contoso.com" -RetentionPolicy "Default MRM Policy"` |
| Mailbox on retention hold | Hold pausing MRM | Check `Get-Mailbox | Select RetentionHoldEnabled` |

### Archive is Full

| Symptom | Fix |
|---------|-----|
| Archive at 50 GB, Plan 1/E1 | Upgrade to Exchange Online Plan 2 or E3/E5 |
| Auto-expanding not growing | First expansion can take 30 days; verify: `Get-Mailbox | Select AutoExpandingArchiveEnabled` |

```powershell
Get-Mailbox -Identity "user@contoso.com" |
  Select DisplayName, ArchiveStatus, AutoExpandingArchiveEnabled, RetentionPolicy, RetentionHoldEnabled

Get-MailboxStatistics -Identity "user@contoso.com" -Archive |
  Select DisplayName, TotalItemSize, ItemCount
```

---

## 10. Quick Reference

| Task | Method |
|------|--------|
| Enable archive | EAC: Mailboxes → Select user → Mailbox → Manage mailbox archive |
| Enable archive (PowerShell) | `Enable-Mailbox -Identity "user@contoso.com" -Archive` |
| Enable shared mailbox archive | `Enable-Mailbox -Identity "shared@contoso.com" -Archive` |
| Enable auto-expanding archive | `Enable-Mailbox -Identity "user@contoso.com" -AutoExpandingArchive` |
| Assign retention policy | `Set-Mailbox -Identity "user@contoso.com" -RetentionPolicy "Default MRM Policy"` |
| Force MRM to run | `Start-ManagedFolderAssistant -Identity "user@contoso.com"` |
| Enable retention hold | `Set-Mailbox -Identity "user@contoso.com" -RetentionHoldEnabled $true` |
| Check archive size | `Get-MailboxStatistics -Identity "user@contoso.com" -Archive` |
| Connect to Graph | `Connect-MgGraph -Scopes "Mail.Read"` |
| Get archive folder ID | `GET /users/{user-id}/mailboxSettings` → `archiveFolder` |
| List archive folders | `GET /users/{user-id}/mailFolders/archive/childFolders` |

---

*For additional help, visit [Microsoft Learn — Exchange Online Archiving](https://learn.microsoft.com/exchange/archiving/archiving) or the [Microsoft Graph mailboxSettings API reference](https://learn.microsoft.com/graph/api/resources/mailboxsettings).*
