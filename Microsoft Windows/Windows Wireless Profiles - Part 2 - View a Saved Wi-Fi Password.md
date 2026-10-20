# Windows Wireless Profiles - Part 2 - View a Saved Wi-Fi Password

**Applies to:** Windows 11; Windows 10 under an applicable support arrangement; saved Wi-Fi profiles using a shared key<br>
**Scope:** Inspect the locally saved shared key for one authorized wireless profile<br>
**Last Updated:** October 2026

---

## Overview

Open an elevated **Command Prompt** and run `netsh wlan show profile name="Example WiFi" key=clear`, replacing the example with the exact saved profile name. Look for **Key Content** under **Security settings**; labels vary with the Windows display language.

Start with [Part 1 - List Saved Profiles](./Windows%20Wireless%20Profiles%20-%20Part%201%20-%20List%20Saved%20Profiles.md) to identify the profile. This procedure displays a stored shared key; enterprise Wi-Fi using 802.1X credentials or certificates does not necessarily have a shared password to reveal.

## Prerequisites

| Requirement | Detail |
|---|---|
| Authorized task | Customer authorization to inspect the selected network's saved key. |
| Permissions | Local administrator access and an elevated Command Prompt on the endpoint holding the profile. |
| Profile | Exact profile and interface names from Part 1. Verify the profile remains visible if elevation uses a different account. |
| Credential handling | Use a session where displayed secrets will not be captured in shared recordings or logs. Do not redirect clear-text output into tickets or repository files. |
| Licensing | Built-in Windows command; no additional Microsoft 365 license or PowerShell module is required. |

**MSP note:** Confirm the customer's endpoint and inspect only the required profile. Keep customer network names and passwords out of screenshots and this public repository. Use the customer's approved credential vault if retention is necessary.

---

## 1. Open an Elevated Command Prompt

1. Open **Start**, search for **Command Prompt**, and select **Run as administrator**.
2. Complete the elevation prompt with an authorized account.
3. Confirm the intended profile is visible:

   ```cmd
   netsh wlan show profiles
   ```

If the profile is missing after elevation, return to [Part 1](./Windows%20Wireless%20Profiles%20-%20Part%201%20-%20List%20Saved%20Profiles.md) and check user context and interface selection.

## 2. View the Selected Profile's Saved Key

1. Replace `Example WiFi` with the exact profile name and run:

   ```cmd
   netsh wlan show profile name="Example WiFi" key=clear
   ```

2. For a specific wireless interface, use its exact name:

   ```cmd
   netsh wlan show profile name="Example WiFi" interface="Wi-Fi" key=clear
   ```

3. Review **Security settings > Key Content**. Treat the displayed value as a credential.
4. If the field is absent, inspect the authentication method and permissions before concluding that a shared key can be recovered. Do not publish the output as an example.

The saved value may be outdated if the network password changed after the profile was saved. Displaying a key does not prove it currently grants access.

## Verification / Testing Checklist

- [ ] The selected profile belongs to the authorized support task.
- [ ] The correct profile and interface were used in an elevated session.
- [ ] A shared key was displayed, or its absence was explained by the profile/authentication context.
- [ ] Any connection test was approved and planned to avoid disrupting remote access.
- [ ] No secret was retained in terminal captures, ticket attachments, or repository content.

## Troubleshooting

| Symptom | Check / next action |
|---|---|
| Profile not found | Verify spelling, straight double quotes, interface, and execution account against Part 1. |
| Access denied or no Key Content | Confirm elevation, profile access, and the authentication method. Do not weaken policy or profile permissions to force disclosure. |
| Enterprise profile has no shared key | Investigate its configured 802.1X method or certificate deployment; there may be no common Wi-Fi password. |
| Displayed key does not work | Confirm the intended network and whether its password has changed. Coordinate with the network owner before updating the profile. |

## Rollback and Cleanup

The commands display profile information without changing the saved key or connection settings, so no configuration rollback is required. Close the terminal after inspection. If the password was inadvertently disclosed through a recording, log, or screenshot, follow the customer's credential-exposure process and coordinate rotation with the network owner.

---

## Sources

- Microsoft Learn: [netsh wlan](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/netsh-wlan)
