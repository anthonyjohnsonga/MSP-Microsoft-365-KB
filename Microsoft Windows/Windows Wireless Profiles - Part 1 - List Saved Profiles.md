# Windows Wireless Profiles - Part 1 - List Saved Profiles

**Applies to:** Windows 11; Windows 10 under an applicable support arrangement<br>
**Scope:** List locally saved Wi-Fi profiles and identify the exact profile name for inspection<br>
**Last Updated:** October 2026

---

## Overview

Open **Command Prompt** on the affected endpoint and run `netsh wlan show profiles` to list saved wireless profiles. This lists stored configuration, rather than nearby networks or a complete connection history.

This is Part 1 of a two-part series. Continue to [Part 2 - View a Saved Wi-Fi Password](./Windows%20Wireless%20Profiles%20-%20Part%202%20-%20View%20a%20Saved%20Wi-Fi%20Password.md) only when the support task requires viewing a saved shared key.

## Prerequisites

| Requirement | Detail |
|---|---|
| Endpoint | A Windows computer with a wireless adapter and the WLAN AutoConfig service available. |
| Session | Use the affected user's session for user-specific profiles. A different administrator or SYSTEM session can have a different profile view. |
| Permissions | Start with a normal Command Prompt for listing profiles. Part 2 requires an elevated session to inspect a saved key. |
| Licensing | Built-in Windows command; no additional Microsoft 365 license or PowerShell module is required. |

**MSP note:** Confirm the customer's endpoint and user context. Record only the profile information needed for the ticket; profile names can identify customer networks.

---

## 1. List Saved Profiles

1. Open **Start > Command Prompt** on the affected endpoint.
2. Run:

   ```cmd
   netsh wlan show profiles
   ```

3. Locate the intended profile under the reported interface. Policy and user profiles can appear in separate groups.
4. Record the exact profile name, including spaces. Do not assume the profile name and broadcast network name are identical.

## 2. Inspect the Selected Profile

Replace `Example WiFi` with the exact saved profile name:

```cmd
netsh wlan show profile name="Example WiFi"
```

Review the SSID and authentication settings to confirm the intended profile. This command does not request a clear-text key. If multiple wireless interfaces exist, identify the correct interface with `netsh wlan show interfaces` and add its exact name:

```cmd
netsh wlan show profile name="Example WiFi" interface="Wi-Fi"
```

The interface and profile names in these examples are illustrative. If authorized key inspection is needed, continue to [Part 2](./Windows%20Wireless%20Profiles%20-%20Part%202%20-%20View%20a%20Saved%20Wi-Fi%20Password.md).

## Verification / Testing Checklist

- [ ] The correct endpoint and user context were selected.
- [ ] The intended saved profile and interface were identified.
- [ ] Profile details match the expected network and authentication method.
- [ ] No customer-specific output was added to the public knowledge base.

## Troubleshooting

| Symptom | Check / next action |
|---|---|
| No wireless interface is reported | Check adapter presence, drivers, and WLAN AutoConfig status. |
| The profile is not listed | Confirm endpoint, user context, interface, and whether the profile was ever saved or has been removed. |
| Profile not found when inspecting it | Copy the exact name from the list and enclose it in straight double quotes. |
| Saved profile exists but connection fails | Listing confirms stored configuration only; investigate signal, authentication, and current network configuration separately. |

## Rollback

These inspection commands do not change profiles or connection settings, so no configuration rollback is required. Close the terminal and handle any copied output under the customer's support-data policy.

---

## Sources

- Microsoft Learn: [netsh wlan](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/netsh-wlan)
