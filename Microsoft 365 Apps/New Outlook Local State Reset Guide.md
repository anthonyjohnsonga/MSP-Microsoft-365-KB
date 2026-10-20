# New Outlook Local State Reset Guide

**Applies to:** New Outlook for Windows (`olk.exe`) on Windows 11<br>
**Scope:** Reset the affected user's local new Outlook profile and reconfigure accounts when troubleshooting client issues<br>
**Last Updated:** October 2026

---

## Overview

Close new Outlook and run `olk.exe --clearLocalState` in the affected user's session to start with a fresh local profile. Use this when troubleshooting stale account configuration or client issues after checking that the mailbox works in a browser.

This resets the local profile and requires adding accounts again; it is more than a temporary-file cleanup. The command is documented by Outlook MVP Diane Poremsky in [Reset the New Outlook Profile](https://www.slipstick.com/new-outlook/reset-outlook-profile/). It applies to new Outlook, not classic Outlook (`outlook.exe`).

## Prerequisites

| Requirement | Detail |
|---|---|
| User session | Run as the affected signed-in Windows user. A technician account or SYSTEM/RMM shell uses a different user context. Administrator elevation is not required for this procedure. |
| Account access | Verify the user can sign in to each account and complete MFA. Record which accounts must be added again without collecting passwords or tokens. |
| Data preparation | Save open work and confirm important messages and drafts are available through webmail. Preserve any local-only or unsent content before resetting. |
| Connectivity | Internet access and access to the customer's authentication endpoints are required for account setup and synchronization. |
| Licensing | The reset itself requires no additional license. The account must remain eligible to use new Outlook under the customer's existing licensing and access policies; see [licensing in new Outlook](https://learn.microsoft.com/en-us/microsoft-365-apps/outlook/get-started/licensing-options). |

**MSP note:** Confirm the customer and affected Windows profile before running the command. Treat each user's profile separately on shared devices. Keep account identifiers and diagnostic details in the service ticket, rather than this public guide.

---

## 1. Confirm the Issue and Close New Outlook

1. Confirm the issue occurs in **Outlook (new)**. Record the symptom and any error message.
2. Open the affected mailbox in a browser and check sign-in and mail access. If the same issue occurs there, investigate the account, service, or access policy before resetting the client.
3. Complete the data and account-access checks above.
4. Close all new Outlook windows. If `olk.exe` remains running, check for unsaved work before ending it through **Task Manager**.

## 2. Reset Local State

1. In the affected user's session, press **Windows+R**.
2. Enter the following command and select **OK**. Use two hyphens before `clearLocalState`:

   ```text
   olk.exe --clearLocalState
   ```

3. Open **Outlook (new)** if it does not open automatically.
4. Follow the account setup prompts. Sign in with the intended account and complete MFA.
5. Add additional accounts through **Settings > Accounts > Email accounts**, as needed, and allow synchronization to finish.

Do not substitute `outlook.exe`; classic Outlook uses different profile-management procedures.

## 3. Verify the Result

- [ ] The intended accounts are configured in new Outlook.
- [ ] Mail folders and calendar items synchronize as expected.
- [ ] An approved test message sends and a reply is received.
- [ ] The original issue no longer occurs after closing and reopening new Outlook.
- [ ] Required shared or delegated mailboxes are accessible.
- [ ] The ticket records the reset result and any remaining errors.

## Recovery and Rollback

There is no undo step for this local profile reset. Recovery consists of adding accounts again, allowing server data to synchronize, and checking required preferences. This procedure does not delete the server mailbox, but server synchronization cannot recover content that existed only locally and was not preserved before the reset.

If the issue remains, retain the exact error and investigate authentication, service health, policy, or the installed app. Avoid repeated resets without a new diagnostic finding.

## Troubleshooting

| Symptom | Check / next action |
|---|---|
| Windows cannot find `olk.exe` | Confirm new Outlook is installed and launches from Start in this user profile. Repair or reinstall the app if needed using Microsoft's troubleshooting guidance below. Avoid hard-coded version-specific WindowsApps paths. |
| The expected profile did not reset | Confirm new Outlook was closed and the command ran in the affected user's session with two hyphens. |
| Account setup fails | Verify browser sign-in, network access, MFA, licensing, and Conditional Access requirements. Capture the error before making further changes. |
| Mail or settings appear missing | Check the intended account was added and synchronization completed; compare with webmail and reconfigure local preferences as needed. |
| The original issue persists | Follow Microsoft's new Outlook troubleshooting guidance and check whether the issue also affects webmail. |

---

## Sources

- Diane Poremsky, Slipstick Systems: [Reset the New Outlook Profile](https://www.slipstick.com/new-outlook/reset-outlook-profile/) — source for `olk.exe --clearLocalState` and account reconfiguration.
- Microsoft Support: [Outlook for Windows not responding, hangs, freezes, or stops working](https://support.microsoft.com/en-gb/outlook/getstarted/outlook-for-windows-not-responding-hangs-freezes-or-stops-working) — use the new Outlook section.
- Microsoft Learn: [Licensing in new Outlook for Windows](https://learn.microsoft.com/en-us/microsoft-365-apps/outlook/get-started/licensing-options)
