---
created: 2026-06-04T15:42:00
updated: 2026-06-04T15:42
modified: 2026-06-04T15:42:59-04:00
tags:
  - Microsoft
  - Windows
  - OneDrive
---


# Microsoft OneDrive Sync Troubleshooting Guide

**Scope:** MSP Technician Reference  
**Applies To:** OneDrive for Business, SharePoint Sync, SharePoint Shortcuts

---

## Symptoms

User reports one or more of the following:

- OneDrive sync status icons (overlays) missing from File Explorer
- OneDrive not uploading or downloading file changes
- SharePoint synced library or shortcut not reflecting updates
- SharePoint sync/shortcut folder missing sync status icons entirely

---

## Quick Fix — Relink the Account

> **Start here.** This is fast and low-impact. It does not always resolve the issue, but it's worth attempting first before the deeper fix.

### Steps

1. Open the **OneDrive system tray icon** (taskbar, bottom-right). If not visible, launch OneDrive from Start.
2. Click the gear icon → **Settings** → **Account** tab.
3. Click **Unlink this PC** and confirm.
4. Once unlinked, sign back into OneDrive with the user's work account.
5. Allow OneDrive to begin syncing and check whether sync status icons return.

**If this resolves the issue, you're done.** If sync icons are still missing or files are still not syncing, proceed to the Full Fix below.

---

## Full Fix — Reset OneDrive Settings Folder

> This is the more reliable fix and should be used when the quick fix fails. It clears OneDrive's local configuration state, which is commonly the root cause of persistent sync failures.

### Step 1 — Unlink the Account

1. Open the **OneDrive system tray icon**.
2. Click gear icon → **Settings** → **Account** tab → **Unlink this PC** → confirm.

### Step 2 — Stop the OneDrive Process

1. Right-click the **OneDrive system tray icon** → **Quit OneDrive** (or **Close OneDrive**).
2. Confirm OneDrive is no longer running. Check Task Manager if needed — kill `OneDrive.exe` if it persists.

### Step 3 — Remove the Work or School Account from Windows

1. Open **Settings** → **Accounts** → **Access work or school**.
2. Select the user's work account → click **Disconnect** → confirm.

### Step 4 — Rename the OneDrive Settings Folder

1. Open **File Explorer**.
2. Navigate to:
   ```
   C:\Users\<username>\AppData\Local\Microsoft\OneDrive
   ```
   > **Note:** AppData is a hidden folder. If not visible, enable **Show hidden items** in File Explorer's View options, or paste the path directly into the address bar.
3. Locate the folder named **`settings`**.
4. Right-click → **Rename** → change the name to **`settings.old`**.

### Step 5 — Relaunch OneDrive and Sign In

1. Launch **OneDrive** from the Start menu.
2. Sign in with the user's work account when prompted.
3. Allow OneDrive to complete the initial sync fully before proceeding.

> **Note:** **This step is critical.** Do not attempt to re-add SharePoint syncs or shortcuts until OneDrive has fully synced. Adding them while OneDrive is still processing will cause them to fail silently or not load at all. Monitor the tray icon — wait until it shows a green checkmark (up to date).

### Step 6 — Re-adding SharePoint Syncs or Shortcuts

Once OneDrive is fully synced, you need to re-add any SharePoint synced libraries or shortcuts. **Before doing so, talk to the user.**

Ask the following:

- **Did you make any changes to files in this folder before the issue started?**  
  Files that were edited locally but never synced up may exist only on the device and could be lost if the folder is discarded.
- **Are there any files with very long file paths, special characters, or unsupported file types?**  
  These can cause sync errors that surface as a general broken sync state.
- **Was the folder recently moved or renamed in SharePoint?**  
  The local sync path may be orphaned from the new SharePoint location.

Based on the user's answers, follow the appropriate path below.

---

#### Path A — User Did Not Work on Any Files

No local-only changes to recover. Proceed directly:

1. Navigate to the SharePoint library in the browser.
2. Click **Sync** or **Add shortcut to OneDrive** as appropriate.
3. Wait for the library to fully sync down to the device.
4. Confirm the folder appears in File Explorer with sync status icons.

---

#### Path B — User Did Work on Files (Recovery Required)

> Do not rename or remove the broken SharePoint sync folder until the files have been recovered and documented.

**1. Locate the Files**

1. Open **File Explorer** and navigate to the broken SharePoint synced folder.  
   This is typically located under:
   ```
   C:\Users\<username>\<OrgName>\<Library Name>
   ```
   or inside the user's **OneDrive - [Company]** folder depending on how it was synced.
2. Ask the user to point out the specific files, or sort by **Date Modified** to identify recent changes that align with when the issue began.
3. Note the file names and paths for documentation.

**2. Copy the Files to a Safe Location**

1. Create a temporary recovery folder outside of any OneDrive or SharePoint sync path:
   ```
   C:\Users\<username>\Desktop\SP_Recovery_<date>
   ```
2. **Copy** (do not move) the identified files into this folder.  
   The originals must stay in place until the reset is confirmed complete.

> **Note:** **Copy only — do not move.** If something goes wrong during the reset, the originals are still in the broken sync folder as a fallback.

**3. Document with Screenshots**

Before making any further changes:

1. Take a **screenshot** of the broken SharePoint sync folder showing the files and their **Date Modified** timestamps.
2. Take a **screenshot** of the `SP_Recovery_<date>` folder confirming the copied files are present.
3. Attach both screenshots to the ticket. This protects both the technician and the user if questions arise later.

**4. Rename the Broken SharePoint Sync Folder**

1. In File Explorer, right-click the broken SharePoint synced folder → **Rename** → append `.old`.  
   Example: `Marketing Documents` → `Marketing Documents.old`
2. Do **not** delete it. It stays as a fallback until the user confirms everything is restored correctly.

**5. Re-add the SharePoint Sync**

1. Navigate to the SharePoint library in the browser.
2. Click **Sync** or **Add shortcut to OneDrive** as appropriate.
3. Wait for the library to fully sync down to the device.

**6. Restore the User's Files**

1. Open the newly synced SharePoint folder in File Explorer.
2. Copy the recovered files from `SP_Recovery_<date>` back into the correct location.
3. Confirm the files upload to SharePoint — check sync status icons and verify the files appear in SharePoint via the browser.
4. Confirm with the user that the restored files look correct and contain their expected changes.

**7. Clean Up**

Once the user confirms everything is in order:

- Delete the `SP_Recovery_<date>` folder from the Desktop.
- Leave the `.old` SharePoint folder in place for a few days as a safety net, then remove it once the user is satisfied.
- Update the ticket with a summary of what was recovered and where files were restored to.

---

## Quick Reference

| Scenario | Action |
|---|---|
| Sync icons missing, OneDrive otherwise appears active | Try Quick Fix (relink) first |
| OneDrive not syncing files at all | Full Fix (rename `settings` folder) |
| SharePoint sync not loading after OneDrive fix | Ensure OneDrive is fully synced before re-adding |
| Ready to re-add SharePoint sync | Talk to user first — did they work on files? |
| User confirms no local file changes | Path A — re-add sync directly |
| User confirms they were working on files | Path B — recover files → screenshot → rename `.old` → re-add sync → restore |

---

*Last updated: June 2025*
