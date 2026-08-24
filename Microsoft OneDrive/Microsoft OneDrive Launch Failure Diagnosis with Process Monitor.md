# Diagnosing OneDrive Launch Failures with Process Monitor

**Applies to:** OneDrive sync app (`OneDrive.exe`) on Windows 10/11; Process Monitor (Sysinternals)  
**Scope:** OneDrive starts and immediately exits — visible in Task Manager for a second or two, then gone. No error dialog, no Application event log entry, and nothing written to the OneDrive ODL logs. Covers capturing and reading the ProcMon trace, the exit-status catalogue, and the policy misconfiguration that most often causes it. Not for sync *failures* on a OneDrive that launches and stays running — see [Microsoft OneDrive Sync Troubleshooting](./Microsoft%20OneDrive%20Sync%20Troubleshooting.md) for those.  
**Last Updated:** August 2026

---

## Overview

**Why ProcMon:** When OneDrive writes no logs of its own, it exited before its logging subsystem initialized. ProcMon captures the syscalls the process made before dying, which is the only remaining source of truth.

**Reach for this early.** If `%LOCALAPPDATA%\Microsoft\OneDrive\logs\OD4` is empty after a failed launch, go straight here. Don't spend hours on reinstalls, EDR consoles, or profile rebuilds first.

**MSP note:** The most common root cause is a policy value the client is reading and obeying — a clean exit, not a crash. Because it's machine-wide and lives in the registry, it fails identically for every profile and survives a reinstall, which is exactly why it defeats the standard escalation path.

---

## Prerequisites

| Requirement | Detail |
|---|---|
| Tool | [Process Monitor](https://learn.microsoft.com/sysinternals/downloads/procmon) (Sysinternals), downloaded to the affected endpoint |
| Access | Local admin to run `procmon64.exe` elevated; the affected user's credentials to launch OneDrive |
| Session | Console or interactive session — OneDrive is a GUI app and will **not** launch from session 0 or a background RMM shell |
| Admin side | Ability to check Group Policy / Intune policy assignment, to determine whether a policy value was set centrally |

---

## 1. Prepare

- Download Process Monitor (Sysinternals) to the affected endpoint.
- Run `procmon64.exe` **elevated**.
- You must be at the console or in an interactive session — OneDrive is a GUI
  app and will not launch from session 0 or a background RMM shell.

## 2. Filter before capturing

ProcMon starts capturing on launch. Press **Ctrl+E** to stop, **Ctrl+X** to clear.

Open the filter dialog (**Ctrl+L**) and add:

| Column | Relation | Value | Action |
|---|---|---|---|
| Process Name | is | `OneDrive.exe` | Include |
| Process Name | is | `OneDriveStandaloneUpdater.exe` | Include |

Optional but useful: **Options → Show Resolved Registry Paths**.

## 3. Capture the failure

1. **Ctrl+E** to start capturing.
2. Launch OneDrive as the affected user, **non-elevated**:
   `C:\Program Files\Microsoft OneDrive\OneDrive.exe`
3. Wait ~10 seconds after the process disappears.
4. **Ctrl+E** to stop.

Expect a few thousand events. That's normal.

**MSP note:** Save the trace (**File → Save → All events**, `.PML`) before you start filtering it down. A `.PML` is the one artifact worth attaching to the ticket, and re-capturing on a user's machine is rarely convenient.

## 4. Find the exit

This is the key step. **Work backwards from `Process_Exit`.**

1. Press **Ctrl+F** and search for `Process_Exit`, or scroll to the end of the trace.
2. Read the **20–30 operations immediately before** it. A process that shuts
   itself down deliberately almost always reads the reason right before exiting.
3. Check the **Detail** column on the `Process_Exit` line for the exit status.

### Reading the exit status

Convert the decimal exit status to hex — it usually names the problem outright.

| Exit status | Hex | Meaning |
|---|---|---|
| 2147943660 | `0x8007046C` | `ERROR_ACCESS_DISABLED_BY_POLICY` — blocked by policy |
| 3221225781 | `0xC0000135` | DLL not found |
| 3221225477 | `0xC0000005` | Access violation (genuine crash) |

## 5. Interpret the pattern

**Clean exit, no failures before it** → OneDrive chose to quit. Look for a
successful registry read just before the `Thread_Exit` / `Process_Exit`
sequence. Policy and licensing checks look like this.

**`NAME NOT FOUND` (`0xC0000034`) on a DLL** → missing dependency. Reinstall.

**`ACCESS DENIED` (`0xC0000022`) on the exe or its DLLs** → ACL or blocking
agent. Check `icacls` on the binary, then the EDR console.

**Process starts and exits with nothing obviously failing** → the block is
below ProcMon's visibility (kernel-level EDR process-creation callback). Go to
the security vendor's console; local logs will never show it.

### Noise to ignore

- `FileSystemControl` returning `0xC0000010` (`STATUS_INVALID_DEVICE_REQUEST`) —
  normal, the FSCTL isn't supported on that volume.
- `RegOpenKey` returning `0xC0000034` on `WOW6432Node` paths — normal probing.
- `0x104` (`REPARSE`) on registry opens — normal redirection.

---

## Worked example

Trace tail, immediately before termination:

```
RegOpenKey    HKLM\Software\Policies\Microsoft\Windows\OneDrive              SUCCESS
RegQueryValue HKLM\...\Windows\OneDrive\DisableFileSyncNGSC                  SUCCESS
              Type: REG_DWORD, Length: 4, Data: 1
RegCloseKey   HKLM\SOFTWARE\Policies\Microsoft\Windows\OneDrive              SUCCESS
Thread_Exit
Thread_Exit
Thread_Exit
Thread_Exit
Process_Exit  Exit Status: 2147943660  (0x8007046C)
```

**Diagnosis:** `DisableFileSyncNGSC = 1` is the "Prevent the usage of OneDrive
for file storage" policy. OneDrive read it, obeyed it, and exited. Not a crash.

**Why it defeated every other check:** machine-wide (HKLM, so every profile
fails identically), survives a clean reinstall (registry, not binaries), writes
no logs (exits before logging starts), and generates no crash event (clean exit).

**Fix:**

```powershell
# Elevated
Remove-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive" -Name DisableFileSyncNGSC
```

Then relaunch OneDrive non-elevated.

**MSP note — find out who set it before you delete it.** This value is settable three ways, and deleting the registry value only sticks if the source is gone:

| Source | Where to fix it |
|---|---|
| Group Policy | **Computer Configuration > Administrative Templates > Windows Components > OneDrive > Prevent the usage of OneDrive for file storage** (`SkyDrive.admx`). Set to **Disabled**, then `gpupdate /force` — leaving it *Not configured* does not clear an already-written key |
| Intune | Settings Catalog / Policy CSP `System/DisableOneDriveFileSync`. Deleting the registry value locally will be re-applied on the next MDM sync |
| Manual / imaging script | Safe to delete outright |

Confirm with `gpresult /h` or the Intune device configuration report before assuming it was set by hand.

---

## Verification / Testing Checklist

- [ ] `Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive"` no longer returns `DisableFileSyncNGSC` (or returns `0`)
- [ ] The policy source is identified and corrected — GPO set to **Disabled**, or the Intune assignment removed
- [ ] OneDrive launches non-elevated and stays running past ~30 seconds
- [ ] `%LOCALAPPDATA%\Microsoft\OneDrive\logs\OD4` is now being written to
- [ ] OneDrive completes sign-in and the cloud icon appears in the notification area
- [ ] The OneDrive folder appears in the File Explorer navigation pane
- [ ] Re-check after a reboot and a `gpupdate /force` — confirms nothing re-applies the value

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| ODL logs at `...\logs\OD4` **are** populated | OneDrive got far enough to log — this runbook isn't the fastest path | Read the ODL logs first; see [Sync Troubleshooting](./Microsoft%20OneDrive%20Sync%20Troubleshooting.md) |
| OneDrive won't launch at all from an RMM shell | Session 0 / non-interactive | Get to the console or an interactive session; this is expected, not a fault |
| Value deleted, OneDrive works, breaks again after reboot | GPO or Intune re-applying it | Fix at the policy source, not the registry |
| GPO set to **Not configured**, key still present | ADMX policies don't clean up on *Not configured* | Set explicitly to **Disabled**, `gpupdate /force`, then confirm the key is gone |
| Trace shows a clean exit but no policy read | Different self-imposed exit (licensing, tenant restriction) | Widen the read to 50+ operations before `Process_Exit`; check `AllowTenantList` / `BlockTenantList` under `HKLM\SOFTWARE\Policies\Microsoft\OneDrive` |
| Nothing fails anywhere in the trace | Kernel-level EDR process-creation block | ProcMon cannot see it — go to the security vendor's console |
| `0xC0000005` access violation | Genuine crash, not a policy exit | Reinstall the sync app; collect a crash dump if it recurs |

---

## Registry paths worth knowing

Two different OneDrive policy locations exist, from **two different ADMX files**. Checking one and finding it empty does **not** rule out the other:

| Path | ADMX | Holds |
|---|---|---|
| `HKLM\SOFTWARE\Policies\Microsoft\Windows\OneDrive` | `SkyDrive.admx` (Windows Components > OneDrive) | `DisableFileSyncNGSC` — the "Prevent the usage of OneDrive for file storage" kill switch. Usually **absent** unless someone deliberately disabled OneDrive |
| `HKLM\SOFTWARE\Policies\Microsoft\OneDrive` | `OneDrive.admx` (the sync app's own ADMX) | Everything else: KFM (`KFMSilentOptIn`, `KFMOptInWithWizard`, `KFMBlockOptIn`), tenant restrictions (`AllowTenantList`, `BlockTenantList`), `FilesOnDemandEnabled`, `SilentAccountConfig`, `GPOSetUpdateRing`. Usually **populated** in a managed tenant |

Check both. The kill switch and the day-to-day sync settings live in different places, and a tech who only looks under `...\Microsoft\OneDrive` — the one that's normally full of values — will conclude no OneDrive policy is applied.

---

## Sources

- Microsoft Learn: [Policy CSP — System > DisableOneDriveFileSync](https://learn.microsoft.com/windows/client-management/mdm/policy-csp-system#disableonedrivefilesync) — maps the policy to `Software\Policies\Microsoft\Windows\OneDrive` / `DisableFileSyncNGSC` / `SkyDrive.admx`
- Microsoft Learn: [Use OneDrive policies to control sync settings](https://learn.microsoft.com/sharepoint/use-group-policy) — the full `HKLM\SOFTWARE\Policies\Microsoft\OneDrive` value reference
- Microsoft Learn: [Process Monitor](https://learn.microsoft.com/sysinternals/downloads/procmon) (Sysinternals)
- Microsoft Learn: [Redirect and move Windows known folders to OneDrive](https://learn.microsoft.com/sharepoint/redirect-known-folders) — KFM registry values
- Microsoft Learn: [NTSTATUS values](https://learn.microsoft.com/openspecs/windows_protocols/ms-erref/596a1078-e883-4972-9bbc-49e60bebca55) and [Win32 error codes](https://learn.microsoft.com/openspecs/windows_protocols/ms-erref/18d8fbe8-a967-4f1c-ae50-99ca8e491d2d) — decoding exit statuses
