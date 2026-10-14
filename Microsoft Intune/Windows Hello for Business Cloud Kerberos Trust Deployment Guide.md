# Windows Hello for Business Cloud Kerberos Trust Deployment Guide

**Applies to:** Microsoft Intune; Microsoft Entra joined or hybrid joined Windows devices; synchronized Active Directory users<br>
**Scope:** Deploy cloud Kerberos trust through Intune for passwordless access to on-premises AD resources.<br>
**Last Updated:** October 2026

## Overview

Start at **Intune admin center > Devices > Windows > Configuration**, after validating Microsoft Entra Kerberos for the users' AD domains. Windows Hello for Business (WHfB) uses a device-bound key unlocked by a PIN or biometric gesture. TPM protection is preferred and can be required.

Entra ID supplies a partial ticket-granting ticket (TGT). Windows exchanges it with a domain controller for a full AD TGT, then requests service tickets. AD still controls authorization; cloud trust does not remove domain controllers. See [Microsoft Entra Kerberos](https://learn.microsoft.com/en-us/entra/identity/authentication/kerberos).

## Prerequisites

| Requirement | Confirm before deployment |
|---|---|
| Licensing | Intune licensing for managed users/devices. WHfB cloud trust itself does not require Entra ID P1/P2; automatic MDM enrollment and Conditional Access have separate licensing requirements. |
| Identity | AD users synchronized to Entra ID. PHS/PTA are supported for managed authentication; federation is also supported. Prepare users for MFA during provisioning. |
| Devices | Entra joined or hybrid joined and enrolled in Intune. Entra registration alone is outside this deployment's scope. |
| Windows | Use supported, patched releases. Historical minimums: Windows 10 21H2 + KB5010415 or Windows 11 21H2 + KB5010414. These are feature minimums, not lifecycle recommendations. |
| Domain controllers | Patched Windows Server 2016 or later, adequate writable DC capacity per AD site, and domain/forest functional levels of at least Windows Server 2008 R2. |
| Connectivity | Entra endpoints, AD DNS/DC connectivity for ticket exchange, and access to the target resource; provide VPN where necessary. |
| Hardware | A usable TPM when Require Security Device is enabled. This setting alone does not require TPM 2.0; excluding TPM 1.2 is a separate policy. Prefer TPM 2.0. |
| Intune permissions | An RBAC role permitting configuration profile creation, assignment, and reporting within the customer's scope. |

See [deployment planning](https://learn.microsoft.com/en-us/windows/security/identity-protection/hello-for-business/deploy/) and [PassportForWork CSP](https://learn.microsoft.com/en-us/windows/client-management/mdm/passportforwork-csp).

## 1. Validate Microsoft Entra Kerberos

1. Confirm an Entra Kerberos server object exists for each AD domain containing pilot users. The `AzureADKerberos` computer resembles an RODC but has no physical server.
2. If absent, follow [Microsoft's server setup procedure](https://learn.microsoft.com/en-us/entra/identity/authentication/howto-authentication-passwordless-security-key-on-premises). Use `AzureADHybridAuthenticationManagement` and `Set-AzureADKerberosServer`; verify with `Get-AzureADKerberosServer`. Creation requires the documented RPC DLL dependency, typically available on the Entra Connect server.
3. Arrange AD Domain Admin and Enterprise Admin credentials and an Entra **Hybrid Identity Administrator** account for infrastructure setup. These permissions are separate from Intune policy permissions.
4. Confirm synchronized `onPremisesSamAccountName`, `onPremisesDomainName`, and `onPremisesSecurityIdentifier` attributes. If DC Kerberos encryption policy is restricted, ensure AES256_HMAC_SHA1 is allowed.

**MSP note:** Verify the customer's tenant, forest, domains, and cloud environment. Existing FIDO2 on-premises SSO infrastructure can be reused; FIDO2 enrollment alone does not establish it. Maintain a Kerberos server key rotation process using Microsoft's guidance. Keep credentials and diagnostic identifiers out of shared articles.

## 2. Resolve Policy Conflicts

1. Inventory **Endpoint security > Account protection**, Settings catalog profiles, security baselines, and tenant enrollment WHfB settings.
2. On hybrid joined devices, generate a Group Policy report from an elevated prompt:

   ```powershell
   gpresult.exe /h "$env:TEMP\WHfB-GPResult.html" /f
   ```

3. Choose one WHfB management source. GPO takes precedence over PassportForWork CSP; `MDMWinsOverGP` does not resolve these conflicts. Inspect user policies, which can override device policies.
4. Ensure **Use certificate for on-premises authentication** is not configured for cloud trust. Certificate trust takes precedence when enabled.

Tenant-wide WHfB settings apply at enrollment; changing them does not update already enrolled devices. Use targeted configuration for existing devices. Reuse an appropriate profile where possible; add cloud trust through Settings catalog if the existing policy type does not expose it.

See [configuration and precedence](https://learn.microsoft.com/en-us/windows/security/identity-protection/hello-for-business/configure).

## 3. Create and Assign the Intune Policy

1. Go to **Devices > Windows > Configuration > Create > New policy**.
2. Select **Windows 10 and later** and **Settings catalog**.
3. Name the profile `WIN - WHfB - Cloud Kerberos Trust`.
4. Under **Add settings**, search for **Windows Hello for Business** and configure:

   | Setting | Value | Purpose |
   |---|---|---|
   | Use Windows Hello For Business (Device) | `true` | Enable provisioning. |
   | Use Cloud Trust For On Prem Auth | `Enabled` | Select cloud trust for AD authentication. |
   | Require Security Device | `true` | Require TPM-backed provisioning; recommended after hardware validation. |

5. Assign a small pilot device group. User targeting is also supported; document the chosen scope.
6. Review assignments and create the policy.

If WHfB is already effectively enabled, only cloud trust needs adding. Peter van der Woude's [MVP walkthrough](https://petervanderwoude.nl/post/configuring-windows-hello-for-business-cloud-kerberos-trust/) supports using Settings catalog for this addition; its older portal labels may differ. See also [Microsoft's policy reference](https://learn.microsoft.com/en-us/windows/security/identity-protection/hello-for-business/policy-settings).

## 4. Sync, Provision, and Verify

1. Select **Devices > All devices > [pilot device] > Sync**. Check the profile's device and per-setting status for success or conflicts.
2. Have the user complete WHfB provisioning, then sign out and sign in with the PIN or biometric gesture. Hybrid joined devices need DC connectivity for the first Hello sign-in.
3. Run these in the signed-in user's **non-elevated** session:

   ```powershell
   dsregcmd.exe /status
   klist.exe cloud_debug
   ```

   Check `AzureAdJoined : YES`; hybrid devices also show `DomainJoined : YES`. Check `NgcSet : YES` and `AzureAdPrt : YES`. On current builds, `OnPremTgt : YES` indicates an on-premises partial ticket; `CloudTgt` concerns cloud resources. Field names and prerequisite output vary by Windows version. Neither proves successful AD resource access. See [dsregcmd diagnostics](https://learn.microsoft.com/en-us/entra/identity/devices/troubleshoot-device-dsregcmd).

4. Open an authorized test share by DNS name, for example `\\fileserver.contoso.com\PilotShare`. Replace this illustrative path with the customer's approved resource. Avoid IP addresses for a Kerberos test. In the same session, run:

   ```powershell
   klist.exe
   ```

   Confirm a full AD `krbtgt` ticket and a `cifs` service ticket for that server, plus access without a credential prompt. This tests the path beyond partial-ticket issuance.

5. For provisioning failures, inspect **Event Viewer > Applications and Services Logs > Microsoft > Windows > User Device Registration > Admin**. Entra joined devices do not perform the hybrid cloud trust prerequisite check; Hello provisioning alone does not prove Entra Kerberos is configured.

## 5. Handle Existing Deployments and Limitations

- **Key trust:** Enable cloud trust and sign out/in with Hello; re-enrollment is unnecessary. Preserve DC connectivity for the first hybrid sign-in.
- **Certificate trust:** Requires redeployment. Disable certificate trust, apply cloud trust, verify an alternate sign-in method, then run this as the affected user. It deletes that user's Hello container; sign out/in and provision again.

  ```powershell
  certutil.exe -deletehellocontainer
  ```

- **Privileged AD users:** Default RODC password replication restrictions block direct or indirect privileged group members from cloud trust on-premises authentication. Do not relax those restrictions.
- **RDP/VDI and Run as:** Supplied-credential RDP/VDI and Run as are unsupported with cloud trust. Assess Remote Credential Guard separately for supported remote scenarios.

See [deployment, migration, and limitations](https://learn.microsoft.com/en-us/windows/security/identity-protection/hello-for-business/deploy/hybrid-cloud-kerberos-trust).

## Verification Checklist

- [ ] Correct customer tenant, AD domains, and pilot assignments verified.
- [ ] Entra Kerberos infrastructure and identity attributes validated.
- [ ] GPO/CSP and certificate trust conflicts resolved.
- [ ] Intune reports successful application; user provisions and signs in with Hello.
- [ ] Partial ticket, full AD TGT, and target service ticket verified.
- [ ] Authorized share works without a password prompt.
- [ ] Hybrid first sign-in and subsequent offline unlock tested where applicable.
- [ ] Recovery method and pilot rollback documented before broad rollout.

## Troubleshooting

| Symptom | Check and action |
|---|---|
| Profile pending or conflicting | Check targeting, last check-in, per-setting reports, GPO, and user policy. Sync does not guarantee immediate completion. |
| Hello does not provision | Check prerequisites and User Device Registration events. From an elevated prompt, use `Get-Tpm` to inspect TPM readiness when hardware protection is required. |
| `OnPremTgt : NO` | Check user-context PRT state, synchronized AD attributes, domain-specific Entra Kerberos setup, and privileged group restrictions. |
| Partial ticket exists but share access fails | Check AD DNS, writable DC reachability, time synchronization, server SPNs, service tickets, and resource permissions. A partial ticket is not a full AD TGT. |
| Registry value missing | Inspect Intune reports and all policy sources. Absence from the CSP registry branch alone does not prove cloud trust is unconfigured; GPO uses a different branch. Avoid manual registry fixes. |

## Rollback and Recovery

Pause expansion and restore the pilot's recorded policy configuration through its original management source. Sync and verify the resulting state before resuming deployment. Removing an assignment or disabling provisioning does not necessarily remove existing Hello credentials or restore a previous trust model.

Retain a tested alternate sign-in method. Certificate-trust rollback requires planned certificate/Hello redeployment; container deletion is not routine troubleshooting. Keep shared Entra Kerberos infrastructure during device-policy rollback because other passwordless deployments may depend on it.

**Validation scope:** Documentation reviewed; commands and policy behavior require verification in a safe customer pilot or lab before rollout.

## Sources

- Microsoft Learn: [Cloud Kerberos trust deployment](https://learn.microsoft.com/en-us/windows/security/identity-protection/hello-for-business/deploy/hybrid-cloud-kerberos-trust).
- Microsoft Learn: [Plan a Windows Hello for Business deployment](https://learn.microsoft.com/en-us/windows/security/identity-protection/hello-for-business/deploy/).
- Microsoft Learn: [Microsoft Entra Kerberos setup and key rotation](https://learn.microsoft.com/en-us/entra/identity/authentication/howto-authentication-passwordless-security-key-on-premises).
- Microsoft Learn: [Configure Windows Hello for Business and policy precedence](https://learn.microsoft.com/en-us/windows/security/identity-protection/hello-for-business/configure).
- Microsoft Learn: [Windows Hello for Business policy settings](https://learn.microsoft.com/en-us/windows/security/identity-protection/hello-for-business/policy-settings).
- Microsoft Learn: [PassportForWork CSP](https://learn.microsoft.com/en-us/windows/client-management/mdm/passportforwork-csp).
- Microsoft Learn: [dsregcmd diagnostics](https://learn.microsoft.com/en-us/entra/identity/devices/troubleshoot-device-dsregcmd).
- Microsoft Learn: [Introduction to Microsoft Entra Kerberos](https://learn.microsoft.com/en-us/entra/identity/authentication/kerberos).
- Microsoft MVP Peter van der Woude: [Configuring Windows Hello for Business cloud Kerberos trust](https://petervanderwoude.nl/post/configuring-windows-hello-for-business-cloud-kerberos-trust/) (November 2023; practical corroboration, with current Microsoft documentation governing requirements).
