# Teams – Sharing Files with External Users in Chat

**Source:** [T-Minus 365 – Quick Tip: Sharing Files with External Users in Teams Chat](https://tminus365.com/quick-tip-sharing-files-with-external-users-in-teams-chat/)
**Date Captured:** 2026-05-18
**Tags:** `Teams` `PowerShell` `Files Policy` `External Sharing` `MSP`

---

## Overview

By default, Microsoft Teams **blocks native file attachments** in chats that include external participants (clients, vendors, partners). This is not a bug — it is intentional policy behavior.

**What users experience:**
- The `+` (attach) icon is missing from the chat toolbar in external chats
- Dragging a file from File Explorer into the chat produces a red X
- Users can still paste a SharePoint/OneDrive link manually, but direct attachment is gone

**Root cause:** The `FileSharingInChatsWithExternalUsers` setting inside the **CsTeamsFilesPolicy** is `Disabled` by default.

> ⚠️ This setting is **not configurable through the Teams Admin Center UI** — PowerShell only (as of writing).

---

## What's Actually Happening (Under the Hood)

There are two independent layers that control external file sharing in Teams. Both need to be correct for the full experience to work:

| Layer | What It Controls | Where It Lives |
|---|---|---|
| `CsTeamsFilesPolicy` | The file **attachment UX** inside Teams chat (the `+` icon, drag-and-drop) | Teams PowerShell |
| SharePoint External Sharing | Whether external users can actually **open/access** files once shared | SharePoint Admin Center |

Enabling `FileSharingInChatsWithExternalUsers` only restores the attachment experience. If SharePoint external sharing is locked down, users will be able to attach — but recipients won't be able to open the file.

---

## The Fix – PowerShell Steps

### Step 1 – Install the MicrosoftTeams Module

```powershell
Install-Module -Name MicrosoftTeams -Force -AllowClobber
```

> Only needed once per machine. Skip if already installed.

---

### Step 2 – Import and Connect

```powershell
Import-Module MicrosoftTeams
Connect-MicrosoftTeams
```

> Authenticate with a Global Admin or Teams Admin account.

---

### Step 3 – Check the Current Policy State

```powershell
Get-CsTeamsFilesPolicy
```

> Review the current value of `FileSharingInChatsWithExternalUsers`. Expect it to show `Disabled` on a default tenant.

---

### Step 4 – Enable External File Sharing

**Option A — Global (all users in the tenant):**

```powershell
Set-CsTeamsFilesPolicy -Identity "Global" -FileSharingInChatsWithExternalUsers Enabled
```

**Option B — Scoped (specific users or groups only):**

```powershell
# Create a custom policy
New-CsTeamsFilesPolicy -Identity "AllowExternalFileSharing" -FileSharingInChatsWithExternalUsers Enabled

# Assign to a specific user
Grant-CsTeamsFilesPolicy -Identity "user@domain.com" -PolicyName "AllowExternalFileSharing"

# OR assign to a group (see Scoping to a Group section below)
Grant-CsTeamsFilesPolicy -Group "<GroupObjectId>" -PolicyName "AllowExternalFileSharing" -Rank 1
```

> If you go with Option B, do **not** modify the Global policy. Users without a direct or group assignment will remain on the default (disabled) behavior.

---

### Step 5 – Verify the Change

```powershell
Get-CsTeamsFilesPolicy
```

> Confirm `FileSharingInChatsWithExternalUsers` now shows `Enabled`. If it does, the change is in flight. Propagation can take up to an hour in most environments — allow up to 24 hours before concluding something went wrong.

---

## Field Notes / MSP Considerations

### 👥 Scoping to a Group

Rather than assigning the policy per-user or tenant-wide, you can target a **Microsoft 365 group, security group, or distribution list**. Members inherit the policy automatically — as users are added or removed from the group, their assignment updates accordingly.

```powershell
# Get the group's Object ID from Entra ID (or grab it from the Entra admin center)
$groupId = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

# Create the custom policy if not already done
New-CsTeamsFilesPolicy -Identity "AllowExternalFileSharing" -FileSharingInChatsWithExternalUsers Enabled

# Assign to the group
Grant-CsTeamsFilesPolicy -Group $groupId -PolicyName "AllowExternalFileSharing" -Rank 1
```

**What `-Rank` means:**
- Rank determines precedence when a user belongs to **multiple groups** that each have a different policy assigned
- `Rank 1` = highest priority — wins over any lower-ranked group assignments
- Direct per-user assignments always override group assignments regardless of rank

**Verify the group assignment:**

```powershell
# Check all policies assigned to the group
Get-CsGroupPolicyAssignment -GroupId $groupId

# Check a specific user's effective policy (shows whether it came from a direct or group assignment)
Get-CsUserPolicyAssignment -Identity "user@domain.com" -PolicyType TeamsFilesPolicy | Select-Object -ExpandProperty PolicySource
```

> ⚠️ `Get-CsOnlineUser` only shows **direct** policy assignments — it will not reflect inherited group assignments. Always use `Get-CsUserPolicyAssignment` to confirm a user's effective policy.

**Remove a group policy assignment:**

```powershell
Grant-CsTeamsFilesPolicy -Group $groupId -PolicyName $null
```

---

### 🔗 SharePoint/OneDrive Is Separate

This policy controls the Teams attachment UX only. For recipients to actually open shared files, verify your SharePoint external sharing settings:

- **SharePoint Admin Center → Policies → Sharing**
- Set to at least "Existing guests" or "New and existing guests" depending on your client's risk tolerance

---

## Quick Reference

| Action | Command |
|---|---|
| Check current policy | `Get-CsTeamsFilesPolicy` |
| Enable globally | `Set-CsTeamsFilesPolicy -Identity "Global" -FileSharingInChatsWithExternalUsers Enabled` |
| Disable globally | `Set-CsTeamsFilesPolicy -Identity "Global" -FileSharingInChatsWithExternalUsers Disabled` |
| Create custom policy | `New-CsTeamsFilesPolicy -Identity "PolicyName" -FileSharingInChatsWithExternalUsers Enabled` |
| Assign to user | `Grant-CsTeamsFilesPolicy -Identity "user@domain.com" -PolicyName "PolicyName"` |
| Assign to group | `Grant-CsTeamsFilesPolicy -Group "<ObjectId>" -PolicyName "PolicyName" -Rank 1` |
| Check group assignments | `Get-CsGroupPolicyAssignment -GroupId "<ObjectId>"` |
| Check user's effective policy | `Get-CsUserPolicyAssignment -Identity "user@domain.com" -PolicyType TeamsFilesPolicy` |
| Remove group assignment | `Grant-CsTeamsFilesPolicy -Group "<ObjectId>" -PolicyName $null` |
| Remove user assignment (revert to inherited) | `Grant-CsTeamsFilesPolicy -Identity "user@domain.com" -PolicyName $null` |

---

## Related Areas to Know

- **Teams External Access** (`Set-CsTenantFederationConfiguration`) — controls whether Teams federation with external orgs is allowed at all
- **Teams Guest Access** (`Set-CsTeamsClientConfiguration`) — controls what guests can do inside your tenant's Teams environment
- **SharePoint External Sharing** — controls whether OneDrive/SharePoint links sent to external users actually work
- **Sensitivity Labels / DLP** — can restrict file sharing in Teams chats regardless of this policy
