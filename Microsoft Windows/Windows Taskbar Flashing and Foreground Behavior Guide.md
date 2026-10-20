# Windows Taskbar Flashing and Foreground Behavior Guide

**Applies to:** Windows 11; Windows 10 endpoints retained under an applicable support arrangement<br>
**Scope:** Adjust per-user taskbar attention flashing and foreground lock behavior; includes the registry workaround from the original draft<br>
**Last Updated:** October 2026

---

## Overview

Start at **Settings > Personalization > Taskbar > Taskbar behaviors > Show flashing on taskbar apps** on Windows 11 when the goal is to turn taskbar attention flashing on or off. Availability and labels can vary by Windows build.

For a targeted registry workaround, the original draft changes `ForegroundFlashCount` to `1` and `ForegroundLockTimeout` to `0` under `HKEY_CURRENT_USER\Control Panel\Desktop`. These settings concern taskbar attention requests and foreground activation. They do not establish a fix for desktop icons repeatedly redrawing, Explorer restarting, or the whole display flickering.

**Behavior change:** A zero foreground lock timeout removes that particular delay protecting against foreground activation after user input. It can make focus interruptions more likely; other foreground restrictions still apply. Keep this change optional and test it separately from the flash-count adjustment.

The Microsoft references explain the associated behavior and Windows settings. They do not validate this registry pair as a universal flickering fix. This guide has not been independently tested on an endpoint during preparation.

## Prerequisites

| Requirement | Detail |
|---|---|
| Session and permissions | Use the affected user's interactive session. Normal access to that user's registry hive is sufficient; do not run as a different administrator or SYSTEM. |
| Licensing | No additional Microsoft 365 license is required for this local Windows setting. |
| Backup | Record the original value, type, and whether each entry exists before editing. Export the Desktop key as a secondary backup. |
| Test case | Identify the application and action that trigger flashing or unwanted focus changes so the result can be reproduced. |
| Managed devices | Check for Group Policy, Intune scripts, or other management that may reapply the values. Arrange changes through the customer's management process where applicable. |

**MSP note:** `HKEY_CURRENT_USER` applies to the account running Registry Editor. Pilot in one affected profile, record the Windows build and result, and avoid deploying this workaround across tenants without validation.

---

## 1. Identify the Symptom

1. Determine whether an application's taskbar button flashes to request attention, or whether icons/the entire display visibly redraw or flicker.
2. For full-screen flickering, follow [Microsoft's screen-flickering troubleshooting](https://support.microsoft.com/en-au/windows/hardware/display-graphics/troubleshoot-screen-flickering-in-windows) to distinguish display-driver and app problems.
3. For Windows 11 taskbar attention flashing, try **Settings > Personalization > Taskbar > Taskbar behaviors > Show flashing on taskbar apps** first. Record its original state and test the result.
4. Continue only if a targeted adjustment to flashing or foreground behavior is still needed. Record the original symptom before changing anything else.

## 2. Back Up the Existing Settings

1. In the affected user's session, press **Windows+R**, enter `regedit`, and open Registry Editor. If elevation requires another account, stop and arrange access to the correct user hive rather than editing that administrator's settings.
2. Navigate to:

   ```text
   HKEY_CURRENT_USER\Control Panel\Desktop
   ```

3. Record the existence, type, and original data for `ForegroundFlashCount` and `ForegroundLockTimeout` in the service ticket. Use **Decimal** when recording numeric data and label the base.
4. Right-click **Desktop > Export**, select **Selected branch**, and save the `.reg` file in the customer's approved support location. Keep this backup out of the public repository.

## 3. Adjust Flashing and Test Foreground Behavior

1. In the Desktop key, locate `ForegroundFlashCount`. If absent, create a **DWORD (32-bit) Value** with that exact name. If an existing entry has a different type, investigate before changing it.
2. Set **Base** to **Decimal** and **Value data** to `1`.
3. Save work, sign out, and sign back in. Reproduce the original taskbar attention request and assess whether this adjustment is sufficient.
4. Only if foreground behavior also needs changing, return to the same key and set `ForegroundLockTimeout` to decimal `0`. If absent, create it as a **DWORD (32-bit) Value**. The correct spelling is **ForegroundLockTimeout**; do not create `ForgroundLockTimeout` from the original draft.
5. Save work, sign out, and sign back in again. Test taskbar attention behavior and whether background applications interrupt typing or take focus unexpectedly.

| Value | Draft value (decimal) | Intended effect / limitation |
|---|---|---|
| `ForegroundFlashCount` | `1` | Requests one taskbar flash for the system's rejected foreground-switch notification. Applications can use other flashing behavior. |
| `ForegroundLockTimeout` | `0` | Removes the foreground lock delay after user input. It does not guarantee that every application can take focus. |

Microsoft documents these behaviors through [SystemParametersInfo](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-systemparametersinfow). Validate the direct registry workaround on the affected build after a fresh sign-in.

## Verification / Testing Checklist

- [ ] The change was applied to the affected user's hive.
- [ ] Original values, types, existence, and taskbar setting state were recorded.
- [ ] The original application and action were tested after signing out and back in.
- [ ] Taskbar flashing meets the user's needs.
- [ ] Background applications do not cause unwanted focus interruptions.
- [ ] Values remain as intended after policy processing and a fresh sign-in.
- [ ] Unhelpful changes were rolled back and the outcome was recorded in the ticket.

## Rollback

1. Open Registry Editor in the same user's session and return to the Desktop key.
2. Restore only the changed entries to their recorded original types and data. If an entry did not exist before the procedure, delete only the entry you created.
3. Restore **Show flashing on taskbar apps** to its previous state if you changed it.
4. Save work, sign out, and sign back in; repeat the original test.

Use the exported key as a reference or controlled recovery backup. Importing the whole Desktop key can overwrite unrelated preferences changed since export, and importing does not remove values that were originally absent. Prefer restoring the two recorded entries individually.

## Troubleshooting

| Symptom | Check / next action |
|---|---|
| Flashing continues | Check the taskbar setting, user hive, fresh sign-in, and the application's own notification behavior. This adjustment does not control every flashing mechanism. |
| Applications unexpectedly take focus | Restore the original `ForegroundLockTimeout` and test again. Retain the flash-count change only if useful. |
| Values revert | Identify the policy or management script reapplying them and resolve the setting at its source. |
| Desktop icons or the entire screen still flicker | Investigate Explorer, the affected application, or the display driver using the symptom-specific guidance; stop repeating the registry workaround. |
| The new entry has no effect | Verify the exact value name and type. Do not leave a misspelled entry created during this procedure. |

---

## Sources

- Microsoft Support: [Customize the Taskbar in Windows](https://support.microsoft.com/en-us/windows/experience/personalization/customize-the-taskbar-in-windows)
- Microsoft Learn: [SystemParametersInfoW — foreground flash count and foreground lock timeout](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-systemparametersinfow)
- Microsoft Learn: [SetForegroundWindow — foreground activation restrictions](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-setforegroundwindow)
- Microsoft Support: [Troubleshoot screen flickering in Windows](https://support.microsoft.com/en-au/windows/hardware/display-graphics/troubleshoot-screen-flickering-in-windows)
