# Windows Hello PIN Reset Guide

**Applies to:** Windows 11; Windows Hello and Windows Hello for Business on managed endpoints<br>
**Scope:** Reset a user's PIN or recover Windows Hello enrollment using container deletion, with manual NGC-folder removal as a recovery fallback<br>
**Last Updated:** October 2026

---

## Overview

Start at **Settings > Accounts > Sign-in options > PIN (Windows Hello)**. Use **I forgot my PIN** for a forgotten PIN before removing the underlying enrollment. If the enrollment is damaged or must be removed, use the container-reset procedure below.

The repository owner has confirmed that the recovery approach in the original draft works. Manual NGC-folder removal is retained as a field-tested fallback; the Microsoft sources below document PIN reset and container deletion, rather than the manual folder procedure.

---

## Prerequisites

| Requirement | Detail |
|---|---|
| Alternative sign-in | Verify a working password or another permitted Windows sign-in method before removing Hello. Confirm the user can complete MFA for enrollment. |
| User session | Run the container command in the affected user's interactive session. An RMM shell running as SYSTEM or another administrator targets a different security context. |
| Administrator access | Required for protected-folder recovery. Record any ownership or permission changes before applying them. |
| Connectivity | Provide internet access for organizational authentication and the corporate network/VPN access required by the customer's Hello deployment. |
| Licensing and policy | This local repair requires no additional license. Existing Intune, Entra, and Hello deployment requirements still apply. Confirm enrollment is permitted by effective policy. |
| Passkey recovery | Check **Settings > Accounts > Passkeys**, where available, and arrange alternative access to affected services before deleting the container. |

**Credential impact:** Container deletion removes associated credentials, including locally stored WebAuthn/FIDO credentials. Treat it as an enrollment reset, rather than a change to the PIN alone. See the [certutil reference](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/certutil#-deletehellocontainer).

**MSP note:** Confirm the customer, endpoint, and affected account in the service ticket. On shared devices, plan recovery for every user potentially affected by removing the machine's NGC folder. Keep identifiers and diagnostic output out of this public guide.

---

## 1. Try the Built-In PIN Reset

1. Sign in using an available alternative method.
2. Open **Settings > Accounts > Sign-in options > PIN (Windows Hello) > I forgot my PIN**.
3. Complete identity verification and configure a new PIN. If the reset completes, go to the verification checklist.
4. If reset is unavailable or fails because enrollment is damaged, continue to section 2.

For managed deployments, check the customer's [PIN reset configuration and connectivity requirements](https://learn.microsoft.com/en-us/windows/security/identity-protection/hello-for-business/pin-reset). Reset behavior depends on whether destructive or non-destructive recovery is configured.

## 2. Delete the Affected User's Hello Container

1. Confirm the alternative sign-in and passkey recovery preparations above.
2. Open PowerShell in the affected user's session using that user's credentials. Avoid **Run as different user** with a technician account.
3. Run:

   ```powershell
   certutil.exe -deleteHelloContainer
   ```

4. Check the command result. If it fails, record the error before considering section 3.
5. Sign out and sign back in using the alternative method, then continue to section 4.

Deleting the container does not disable organizational Hello policy. A managed device may prompt for enrollment again.

## 3. Recover by Removing the NGC Folder if Needed

Use this fallback when the normal reset and container command cannot resolve the issue. Skip it if section 2 succeeded. Removing the shared folder can affect multiple users on the endpoint.

1. Arrange a maintenance window, verify alternative sign-in for affected users, and sign out other users.
2. Use an authorized local administrator account to locate:

   ```text
   C:\Windows\ServiceProfiles\LocalService\AppData\Local\Microsoft\NGC
   ```

3. Record the folder's existing owner and permissions. If access is denied, use **NGC > Properties > Security > Advanced** to take ownership and grant the administrator the access required to remove that folder. Apply changes only to **NGC** and its contents; do not grant broad permissions on the parent **Microsoft** folder.
4. Delete the **NGC** folder at the exact path above. If it remains locked or access is denied, stop and investigate the error before making further permission changes.
5. Restart Windows, sign in using the alternative method, and continue to section 4.

## 4. Reconfigure Windows Hello

1. Open **Settings > Accounts > Sign-in options > PIN (Windows Hello)** and select **Set up**, or complete the organization's enrollment prompt.
2. Complete identity verification and create a PIN that meets effective policy.
3. Check facial recognition or fingerprint sign-in and reconfigure it if needed.
4. Restore access to services whose local passkeys were removed and register replacement passkeys where required.

For Intune-managed cloud Kerberos trust deployments, use the [Windows Hello for Business Cloud Kerberos Trust Deployment Guide](../Microsoft%20Intune/Windows%20Hello%20for%20Business%20Cloud%20Kerberos%20Trust%20Deployment%20Guide.md) to check policy and on-premises resource access.

---

## Verification / Testing Checklist

- [ ] The affected user can sign out and sign back in with the new PIN.
- [ ] Configured biometric sign-in works after enrollment.
- [ ] Required work applications and on-premises resources remain accessible.
- [ ] Affected passkey-protected services are accessible and replacement credentials are registered.
- [ ] Other users on a shared endpoint can sign in after manual NGC removal.
- [ ] Any temporary permission changes are resolved; no broad access was granted to the parent folder.
- [ ] The ticket records the method used, command result, and sign-in verification.

## Recovery and Rollback

Deleted Hello credentials cannot be restored by undoing the command or recreating an empty NGC folder. Recovery requires alternative sign-in followed by fresh enrollment. Re-create removed passkeys through each service's account-recovery or credential-registration process.

If manual recovery stops before deletion, restore any ownership and permissions changed during that attempt using the recorded originals. If enrollment still fails, retain alternative access and troubleshoot policy, connectivity, or device registration before repeating deletion.

## Troubleshooting

| Symptom | Check | Next action |
|---|---|---|
| Command succeeds but the affected user's PIN remains | Execution account and session | Confirm the command ran as the affected user, then sign out and back in. |
| Access denied during NGC recovery | Administrator access, folder ownership, and exact target | Inspect permissions on NGC only; avoid changing the parent folder. |
| Hello enrollment returns after removal | Effective Intune or Group Policy settings | Complete enrollment if policy requires it. Removal alone does not disable Hello. |
| New PIN setup fails | Identity verification, network access, and policy conflicts | Capture the error and review the customer's deployment requirements. |
| A website passkey no longer works | Whether its credential was stored locally | Use the prepared alternative method and register a replacement. |
| Another user loses Hello sign-in after NGC removal | Shared-device impact | Have that user sign in with an alternative method and enroll again. |

---

## Sources

- Microsoft Learn: [Windows Hello for Business frequently asked questions](https://learn.microsoft.com/en-us/windows/security/identity-protection/hello-for-business/faq)
- Microsoft Learn: [certutil — DeleteHelloContainer](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/certutil#-deletehellocontainer)
- Microsoft Learn: [Windows Hello for Business PIN reset](https://learn.microsoft.com/en-us/windows/security/identity-protection/hello-for-business/pin-reset)
