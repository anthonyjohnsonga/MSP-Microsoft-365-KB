# Microsoft Exchange Online Guide
### Helpdesk Technician Reference

> **Applies to:** Microsoft 365 Exchange Online  
> **Last updated:** May 2026

---

## Table of Contents

1. [Overview](#1-overview)
2. [Accessing Exchange Online](#2-accessing-exchange-online)
3. [User Mailboxes](#3-user-mailboxes)
4. [Shared Mailboxes](#4-shared-mailboxes)
5. [Resource Mailboxes](#5-resource-mailboxes)
6. [Groups & Distribution Lists](#6-groups--distribution-lists)
7. [Mail Flow Basics](#7-mail-flow-basics)
8. [Troubleshooting Email Delivery](#8-troubleshooting-email-delivery)
9. [NDR Error Codes](#9-ndr-error-codes)
10. [Permissions & Delegation](#10-permissions--delegation)
11. [Exchange Online PowerShell](#11-exchange-online-powershell)
12. [Security & Compliance](#12-security--compliance)
13. [Quick Reference](#13-quick-reference)
14. [PowerShell Cheat Sheet](#14-powershell-cheat-sheet)

---

## 1. Overview

Exchange Online is Microsoft's cloud-based email and calendaring service included in Microsoft 365. It provides enterprise-grade email, shared calendars, contacts, and tasks for your organization without requiring on-premises server infrastructure.

### Admin Portals at a Glance

| Portal | URL | Use For |
|--------|-----|----------|
| Exchange Admin Center (EAC) | `admin.exchange.microsoft.com` | Mailboxes, groups, mail flow, rules, migration |
| Microsoft 365 Admin Center | `admin.microsoft.com` | User accounts, licenses, service health |
| Microsoft Defender Portal | `security.microsoft.com` | Anti-spam, anti-malware, quarantine |
| Microsoft Purview | `compliance.microsoft.com` | eDiscovery, retention, audit logs |
| Microsoft Entra Admin Center | `entra.microsoft.com` | Roles, MFA, Conditional Access |

---

## 2. Accessing Exchange Online

### Exchange Admin Center (EAC)

1. Sign in to `admin.microsoft.com` with your Microsoft 365 admin account.
2. Click **Show all** → **Admin centers** → **Exchange**.
3. The EAC opens at `https://admin.exchange.microsoft.com`.

### EAC Navigation Areas

| Area | What You Do Here |
|------|------------------|
| **Recipients** | Manage mailboxes, groups, contacts |
| **Mail flow** | Message trace, rules, connectors, accepted domains |
| **Roles** | Manage admin role groups |
| **Migration** | Migrate mailboxes in batches |
| **Reports** | Mail flow and migration batch reports |
| **Insights** | Proactively discover and fix mail flow issues |
| **Organization** | Organization sharing and Outlook apps |
| **Public folders** | Manage public folders |

### Required Admin Roles

| Role | Access Level | Notes |
|------|-------------|-------|
| Global Administrator | Full access | Use sparingly |
| Exchange Administrator | Full Exchange Online access | Recommended for Exchange admins |
| Exchange Recipient Administrator | Manage recipients only | Good for helpdesk mailbox management |
| Helpdesk Administrator | Password resets, basic user management | Cannot directly manage mailboxes |

---

## 3. User Mailboxes

### Set Out of Office

```powershell
Set-MailboxAutoReplyConfiguration -Identity "user@contoso.com" `
  -AutoReplyState Enabled `
  -InternalMessage "I am out of office." `
  -ExternalMessage "I am out of office."
```

### Configure Email Forwarding

```powershell
Set-Mailbox -Identity "user@contoso.com" `
  -DeliverToMailboxAndForward $true `
  -ForwardingAddress "other@contoso.com"
```

> **Warning:** Verify with your manager or security team before enabling external forwarding.

### Mailbox Storage Limits by License

| License | Primary Mailbox | Archive Mailbox |
|---------|----------------|----------------|
| Microsoft 365 Business Basic / Standard | 50 GB | 50 GB (if enabled) |
| Exchange Online Plan 1 | 50 GB | 50 GB |
| Exchange Online Plan 2 / Microsoft 365 E3/E5 | 100 GB | Unlimited |

### Increase Mailbox Quota

```powershell
Set-Mailbox -Identity "user@contoso.com" `
  -IssueWarningQuota 45GB `
  -ProhibitSendQuota 49GB `
  -ProhibitSendReceiveQuota 50GB `
  -UseDatabaseQuotaDefaults $false
```

### Calendar Delegation

```powershell
# Grant Editor access to a user's calendar
Add-MailboxFolderPermission -Identity "user@contoso.com:\Calendar" `
  -User "delegate@contoso.com" `
  -AccessRights Editor

Get-MailboxFolderPermission -Identity "user@contoso.com:\Calendar"

Remove-MailboxFolderPermission -Identity "user@contoso.com:\Calendar" `
  -User "delegate@contoso.com"
```

### Offboarding Workflow

1. **Block sign-in** — `admin.microsoft.com` → Users → Active users → Block sign-in
2. **Reset password** to prevent unauthorized access
3. **Set Out of Office** auto-reply
4. **Configure forwarding** to manager/team if needed
5. **Convert to shared mailbox** — EAC → Mailboxes → Others → Convert to shared mailbox
6. **Remove the license** in Microsoft 365 Admin Center
7. **Grant access** to the shared mailbox for appropriate team members

> **Important:** Do not delete the mailbox immediately. Retain for at least 30–90 days per your organization's retention policy.

### Recover a Deleted Mailbox

```powershell
# View soft-deleted mailboxes (retained 30 days after account deletion)
Get-Mailbox -SoftDeletedMailbox
```

Or restore via `admin.microsoft.com` → **Users** → **Deleted users** → **Restore**.

---

## 4. Shared Mailboxes

Shared mailboxes allow multiple users to read and send email from a common address (e.g., `support@contoso.com`). No license required up to 50 GB.

### Create a Shared Mailbox

```powershell
New-Mailbox -Shared -Name "Support Team" -DisplayName "Support Team" -Alias Support
```

### Permission Types

| Permission | What It Allows |
|-----------|----------------|
| **Full Access** | Open and fully manage the mailbox |
| **Send As** | Send email appearing entirely from the shared mailbox |
| **Send on Behalf** | Send showing "Delegate on behalf of Shared Mailbox" |

```powershell
# Grant Full Access
Add-MailboxPermission -Identity "support@contoso.com" `
  -User "jane.doe@contoso.com" -AccessRights FullAccess -InheritanceType All

# Grant Send As
Add-RecipientPermission -Identity "support@contoso.com" `
  -Trustee "jane.doe@contoso.com" -AccessRights SendAs

# Remove Full Access
Remove-MailboxPermission -Identity "support@contoso.com" `
  -User "jane.doe@contoso.com" -AccessRights FullAccess
```

---

## 5. Resource Mailboxes

```powershell
New-Mailbox -Room -Name "Conference Room A" -Alias ConferenceRoomA
New-Mailbox -Equipment -Name "Projector Cart 1" -Alias ProjectorCart1

Set-CalendarProcessing -Identity "Conference Room A" `
  -AutomateProcessing AutoAccept `
  -MaximumDurationInMinutes 480
```

---

## 6. Groups & Distribution Lists

### Group Types

| Group Type | Use Case |
|-----------|----------|
| **Distribution Group** | Send email to a list of people |
| **Mail-Enabled Security Group** | Email + resource access control |
| **Microsoft 365 Group** | Team collaboration (email, Teams, SharePoint) |
| **Dynamic Distribution Group** | Membership based on attribute filter |

```powershell
Add-DistributionGroupMember -Identity "Sales Team" -Member "user@contoso.com"
Remove-DistributionGroupMember -Identity "Sales Team" -Member "user@contoso.com"
Get-DistributionGroupMember -Identity "Sales Team"
```

---

## 7. Mail Flow Basics

### Mail Flow Rules

1. EAC → **Mail flow** → **Rules** → **Add a rule**
2. Define **Conditions** and **Actions**
3. Set to **Enforce** (not Test mode) when ready

> **Note:** New rules can take up to 15 minutes to become active.

### Common Mail Flow Rule Issues

| Problem | Solution |
|---------|----------|
| Rule not working | Wait up to 1 hour; verify priority; confirm Enforce mode |
| Disclaimer added to all replies | Add exception for unique phrase already in the disclaimer |
| OR logic not working | Create two separate rules |
| SentTo not matching a group | Use **"To box contains a member of this group"** |

---

## 8. Troubleshooting Email Delivery

### Step 1 — Check Service Health

`admin.microsoft.com` → **Health** → **Service health** → look for Exchange Online incidents.

### Step 2 — Run Message Trace

```powershell
Get-MessageTrace `
  -SenderAddress "sender@external.com" `
  -RecipientAddress "user@contoso.com" `
  -StartDate (Get-Date).AddDays(-1) `
  -EndDate (Get-Date)
```

### Message Trace Status Meanings

| Status | Meaning |
|--------|----------|
| Delivered | Successfully delivered |
| Failed | Delivery failed — check error code |
| Pending | Queued, still attempting |
| Filtered as spam | Blocked or moved to Junk |
| Quarantined | Held by anti-spam/malware policy |

### SPF, DKIM, and DMARC

| Record | Purpose |
|--------|----------|
| **SPF** | Lists authorized mail servers for your domain |
| **DKIM** | Digitally signs outbound messages |
| **DMARC** | Policy for SPF/DKIM failures (none, quarantine, reject) |

---

## 9. NDR Error Codes

| Error Code | Description | Common Fix |
|-----------|-------------|------------|
| `550 5.1.1` | Recipient address does not exist | Verify email address and mailbox exists |
| `550 5.1.10` | Recipient not found | Check if user was deleted |
| `550 5.4.1` | Domain does not exist | Verify MX records and accepted domains |
| `550 5.7.1` | Unauthorized to send | Check SPF records and block lists |
| `452 4.2.2` | Mailbox over quota | Free up space or increase quota |
| `421 4.3.2` | Service temporarily unavailable | Check Microsoft 365 service health |

**Useful Tools:**
- **Microsoft Remote Connectivity Analyzer** — `testconnectivity.microsoft.com`
- **Message Trace** — EAC → Mail flow → Message trace
- **Microsoft NDR Reference** — `learn.microsoft.com/exchange/mail-flow-best-practices/non-delivery-reports-in-exchange-online`

---

## 10. Permissions & Delegation

```powershell
# Grant Full Access
Add-MailboxPermission -Identity "user@contoso.com" `
  -User "delegate@contoso.com" -AccessRights FullAccess -InheritanceType All

# Grant Full Access without auto-mapping
Add-MailboxPermission -Identity "user@contoso.com" `
  -User "delegate@contoso.com" -AccessRights FullAccess -AutoMapping $false

# Grant Send As
Add-RecipientPermission -Identity "user@contoso.com" `
  -Trustee "delegate@contoso.com" -AccessRights SendAs

# Grant Send on Behalf
Set-Mailbox -Identity "user@contoso.com" -GrantSendOnBehalfTo "delegate@contoso.com"

# View Full Access delegates
Get-MailboxPermission "user@contoso.com" | Where-Object { $_.AccessRights -like "Full*" }
```

---

## 11. Exchange Online PowerShell

```powershell
# Install module (one-time, run as Administrator)
Install-Module -Name ExchangeOnlineManagement -Force -AllowClobber

# Connect
Connect-ExchangeOnline -UserPrincipalName "admin@contoso.com"

# Disconnect
Disconnect-ExchangeOnline -Confirm:$false
```

### Common Cmdlets

| Task | Cmdlet |
|------|--------|
| List all mailboxes | `Get-Mailbox -ResultSize Unlimited` |
| Get mailbox size | `Get-MailboxStatistics -Identity "user@contoso.com"` |
| Create shared mailbox | `New-Mailbox -Shared -Name "Name" -Alias alias` |
| List shared mailboxes | `Get-Mailbox -RecipientTypeDetails SharedMailbox -ResultSize Unlimited` |
| Run message trace | `Get-MessageTrace -SenderAddress ... -RecipientAddress ...` |
| List room mailboxes | `Get-Mailbox -RecipientTypeDetails RoomMailbox` |

---

## 12. Security & Compliance

### Litigation Hold

```powershell
# Enable
Set-Mailbox -Identity "user@contoso.com" -LitigationHoldEnabled $true

# Disable
Set-Mailbox -Identity "user@contoso.com" -LitigationHoldEnabled $false
```

> **Important:** Always coordinate with legal/compliance before enabling or disabling litigation holds.

### Audit Logging

`compliance.microsoft.com` → **Audit** → set date range and search.

---

## 13. Quick Reference

| Task | Navigation Path |
|------|----------------|
| Set Out of Office | EAC → Recipients → Mailboxes → Select user → Others → Automatic replies |
| Create shared mailbox | EAC → Recipients → Mailboxes → Add a shared mailbox |
| Grant Full Access | EAC → Mailboxes → Select mailbox → Mailbox Delegation → Full Access |
| Trace a lost email | EAC → Mail flow → Message trace → Start a trace |
| Check service health | M365 Admin Center → Health → Service health |
| Release quarantined email | Defender portal → Email & Collaboration → Review → Quarantine |
| Enable mailbox archive | EAC → Mailboxes → Select mailbox → Mailbox → Manage mailbox archive |
| Enable litigation hold | EAC → Mailboxes → Select mailbox → Others → Manage litigation hold |

### Key Admin URLs

| Service | URL |
|---------|-----|
| Exchange Admin Center | `https://admin.exchange.microsoft.com` |
| Microsoft 365 Admin Center | `https://admin.microsoft.com` |
| Microsoft Defender Portal | `https://security.microsoft.com` |
| Microsoft Purview Compliance | `https://compliance.microsoft.com` |
| Microsoft Entra Admin Center | `https://entra.microsoft.com` |
| Outlook on the Web | `https://outlook.office.com` |
| Remote Connectivity Analyzer | `https://testconnectivity.microsoft.com` |

---

## 14. PowerShell Cheat Sheet

```powershell
# Connect / Disconnect
Install-Module ExchangeOnlineManagement
Connect-ExchangeOnline -UserPrincipalName admin@contoso.com
Disconnect-ExchangeOnline -Confirm:$false

# Mailbox Management
Get-Mailbox -ResultSize Unlimited
Get-Mailbox -Identity "user@contoso.com"
Get-MailboxStatistics -Identity "user@contoso.com" | Select DisplayName, TotalItemSize, ItemCount
Set-MailboxAutoReplyConfiguration -Identity "user@contoso.com" -AutoReplyState Enabled -InternalMessage "OOO" -ExternalMessage "OOO"
Set-Mailbox -Identity "user@contoso.com" -DeliverToMailboxAndForward $true -ForwardingAddress "other@contoso.com"
Set-Mailbox -Identity "user@contoso.com" -ForwardingAddress $null
Get-Mailbox -RecipientTypeDetails SharedMailbox -ResultSize Unlimited
New-Mailbox -Shared -Name "Support Team" -Alias Support
Set-Mailbox -Identity "user@contoso.com" -Type Shared

# Permissions
Add-MailboxPermission -Identity "mailbox@contoso.com" -User "delegate@contoso.com" -AccessRights FullAccess -InheritanceType All
Add-MailboxPermission -Identity "mailbox@contoso.com" -User "delegate@contoso.com" -AccessRights FullAccess -AutoMapping $false
Remove-MailboxPermission -Identity "mailbox@contoso.com" -User "delegate@contoso.com" -AccessRights FullAccess
Add-RecipientPermission -Identity "mailbox@contoso.com" -Trustee "delegate@contoso.com" -AccessRights SendAs
Set-Mailbox -Identity "mailbox@contoso.com" -GrantSendOnBehalfTo "delegate@contoso.com"

# Groups
Get-DistributionGroup -ResultSize Unlimited
Get-DistributionGroupMember -Identity "Sales Team"
Add-DistributionGroupMember -Identity "Sales Team" -Member "user@contoso.com"
Remove-DistributionGroupMember -Identity "Sales Team" -Member "user@contoso.com"

# Message Trace
Get-MessageTrace -SenderAddress "sender@external.com" -RecipientAddress "user@contoso.com" -StartDate (Get-Date).AddDays(-1) -EndDate (Get-Date)

# Litigation Hold
Set-Mailbox -Identity "user@contoso.com" -LitigationHoldEnabled $true
Set-Mailbox -Identity "user@contoso.com" -LitigationHoldEnabled $false
Get-Mailbox -ResultSize Unlimited | Where-Object { $_.LitigationHoldEnabled -eq $true }

# Resource Mailboxes
New-Mailbox -Room -Name "Conference Room A" -Alias ConferenceRoomA
New-Mailbox -Equipment -Name "Projector Cart 1" -Alias ProjectorCart1
Get-CalendarProcessing -Identity "Conference Room A"
Set-CalendarProcessing -Identity "Conference Room A" -AutomateProcessing AutoAccept -MaximumDurationInMinutes 480
Get-Mailbox -RecipientTypeDetails RoomMailbox
```

---

*For additional help, visit [Microsoft Learn — Exchange Online Documentation](https://learn.microsoft.com/exchange/exchange-online) or open a support ticket in the Microsoft 365 Admin Center under **Help & Support**.*
