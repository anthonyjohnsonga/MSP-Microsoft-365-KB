# Microsoft Entra Dsregcmd Status Troubleshooting Guide

**Applies to:** Windows 11 device identity, Microsoft Entra join/hybrid join/registration, and related Intune enrollment investigations

**Scope:** Read-only diagnostic collection and interpretation; fact check of the supplied dsregcmd infographic

**Last Updated:** November 8, 2026

## Overview

For user sign-in problems, sign in as the affected user, open a normal PowerShell or Command Prompt window, and run:

```powershell
dsregcmd.exe /status
```

Record the Windows build, signed-in account, collection time, and whether the shell was elevated. For a hybrid-join failure, collect a separate elevated run and label it accordingly. Microsoft uses different collection contexts for [PRT troubleshooting][prt-troubleshoot] and [hybrid-join diagnostics][hybrid]. Do not substitute a technician's administrator session for the affected user's evidence.

**Review result:** The supplied infographic is unsuitable as an unqualified troubleshooting reference. Its device-state example conflicts with Microsoft's documented combinations, four error-code descriptions are wrong, and several sample fields are unsupported by the cited schema. This guide preserves the reviewed findings, not the original image.

**Validation boundary:** Sources were rechecked on November 8, 2026. No customer tenant, device join, enrollment, or repair was tested. Examples below are abbreviated illustrations, not captured customer output. Microsoft Learn defines supported behavior; MVP articles provide corroborating case studies.

## 1. Prerequisites and Customer Context

| Requirement | Check before investigating |
|---|---|
| Local access | Obtain an affected-user session for user diagnostics and authorized elevation for device diagnostics. The status command is a local diagnostic; it does not require granting Global Administrator. |
| Tenant access | Use authorized, scoped access to inspect the relevant customer records. **Entra admin center > Entra ID > Devices > All devices** exposes device identities; Intune and Conditional Access require their own permissions. [Device management][devices] |
| Enrollment licensing | When investigating automatic Intune enrollment, check the Intune subscription, Entra ID P1/P2 entitlement, and user scope under **Intune admin center > Devices > Enrollment > Windows > Automatic Enrollment**. These are service prerequisites, not a license for running the local command. [Automatic enrollment][auto-enroll] |
| Intended state | Confirm whether the device should be Entra joined, hybrid joined, or registered. Registration and MDM enrollment are separate operations. [Registered devices][registered] |
| Private evidence | Keep tenant/device identifiers, usernames, certificate details, correlation IDs, and full logs in the customer's secured ticket or evidence store. Do not commit diagnostic output to this KB. |

**MSP practice:** Confirm the customer directory before portal searches. Match the device identifier rather than relying on a reused hostname. Record the failing application and operation; “SSO broken,” “hybrid join failed,” and “Intune enrollment failed” require different evidence.

## 2. Fact Check of the Image's Eight Sections

The reviewed file was `20261010_025541000_iOS.jpg`, titled *dsregcmd /status – Complete Breakdown with Examples* and credited in the image to Shankar Kumar Sony. This review evaluates its technical claims without reproducing the image or its contact information.

| Image section | Finding and correction |
|---|---|
| Command context | **Overbroad.** Start user/SSO investigation in the affected user's normal session; collect elevated join diagnostics separately. [PRT troubleshooting][prt-troubleshoot], [hybrid troubleshooting][hybrid] |
| 1. Device State | **Incorrect sample.** `AzureAdJoined` and `EnterpriseJoined` cannot both be `YES`. Ordinary hybrid join uses `AzureAdJoined=YES`, `DomainJoined=YES`, `EnterpriseJoined=NO`. [Dsregcmd reference][dsreg] |
| 1. Both join flags `NO` | **Incomplete classification.** A workgroup Windows device can still have an Entra-registered account. Do not interpret lack of join as lack of registration or MDM. [Registered devices][registered] |
| 2. Device Details | **Mostly valid concepts.** Device ID, thumbprint, validity, key provider, and TPM protection are useful. Add `DeviceAuthStatus`; `SUCCESS` means the cloud device exists and is enabled, not complete endpoint health. [Dsregcmd reference][dsreg] |
| 2. Certificate example | **Within the illustrated validity period.** The image's diagnostic timestamp is May 18, 2024, between the certificate's April 12, 2024 start and April 12, 2025 expiry. The dates do not demonstrate an expired certificate; verify validity against the actual incident time. |
| 3. Tenant Details | **Misleading implication.** MDM URLs do not establish enrollment. The Terms of Use URL belongs to `MdmTouUrl`, not the illustrated `MdmTenantId`. [Dsregcmd reference][dsreg] |
| 4. User State | **Corrections needed.** `NgcSet` indicates a user Hello key. `WorkplaceJoined` is user-context registration. Elevation can cause WAM errors. Entra values: `WamDefaultAuthority=organizations`; `WamDefaultId=https://login.microsoft.com`. [Dsregcmd reference][dsreg] |
| 5. SSO State | **Not an all-YES checklist.** `EnterprisePrt` concerns AD FS. `NgcKeyId` belongs to User State. [Dsregcmd reference][dsreg] |
| 5. Kerberos tickets | **Oversimplified.** `OnPremTgt` is a partial ticket for on-premises access; it must be exchanged with a domain controller. `CloudTgt` concerns cloud Kerberos. Neither proves that the requested resource accepted access. [Entra Kerberos][kerberos] |
| 6. Diagnostic Data | **Unverified sample layout.** The illustrated `AzureAdJoinInfo`, `EnterpriseJoinInfo`, and generic `AuthStatus` are not the documented diagnostic schema. Do not build detection scripts around them. [Dsregcmd reference][dsreg] |
| 7. Proxy Configuration | **Useful topic, not proof of connectivity.** Inspect the actual WinHTTP configuration; a configured proxy/PAC does not demonstrate successful endpoint access. [WinHTTP][winhttp] |
| 8. Pre-join Diagnostics | **Incorrect sample layout.** Use actual AD/DRS tests and previous-registration fields. This section applies to domain-joined devices failing hybrid join; its absence elsewhere is expected. [Hybrid troubleshooting][hybrid] |

The image's `DeviceCertificate` subject block and `NgcKeyId (legacy)` are also not documented fields in the reviewed reference. Treat them as unverified illustration, not portable output. [Dsregcmd reference][dsreg]

The final health checklist overstates what the command establishes. PRTs support token acquisition and SSO, while application access still depends on the applicable authentication and authorization conditions. A present PRT is not proof of Intune enrollment, compliance, or successful access to every app. [PRT architecture][prt], [Rudy Ooms case study][rudy]

## 3. Correct the Error-Code Table

Retain the full hexadecimal code, operation, failure phase, server response, and timestamp. Similar-looking enrollment and registration codes are not interchangeable.

| Code | Image's description | Reviewed interpretation and next check |
|---|---|---|
| `0x801c03f2` | Invalid device state | **Incorrect.** `DSREG_E_DIRECTORY_FAILURE`; inspect `DirectoryError` details. A missing synchronized device object is one documented example, not the only cause. [Hybrid troubleshooting][hybrid] |
| `0x80180026` | Credential invalid or missing | **Incorrect.** `MENROLL_E_DEVICE_MANAGEMENT_BLOCKED`; MDM can be blocked by policy or external management state. Inspect the effective enrollment policy before changing credentials. [MDM error constants][mdm-errors] |
| `0x801c001d` | Already registered | **Incorrect.** `DSREG_AUTOJOIN_ADCONFIG_READ_FAILED`; investigate AD/SCP reads and the accompanying error/event. [Hybrid troubleshooting][hybrid] |
| `0x801c0003` | Not domain joined | **Incorrect.** Authorization failure for enrollment. Investigate permissions, limits, and restrictions in the relevant enrollment flow. [Enrollment authorization][authorization] |
| `0x801c02bc` | Join operation failed | **Unverified.** No authoritative mapping was found in the Learn references or MVP material reviewed. Capture the original event/message and escalate with context; do not infer a repair from this caption. |

## 4. Follow the Evidence for the Failing Workload

1. **Check the cloud device record.** Open **Entra ID > Devices > All devices**, locate the matching identity, and inspect its state. A hybrid record marked **Pending** means synchronization occurred but client registration has not completed. [Manage device identities][devices]
2. **Investigate user SSO.** In the affected user's capture, inspect PRT state, update/expiry times, and any `Attempt Status`. Match the attempt's identity and time to the incident. Use Microsoft's [PRT troubleshooting procedure][prt-troubleshoot] to correlate client and server errors.
3. **Investigate hybrid join.** In the elevated capture, identify the failed AD/DRS test and previous-registration phase. Correlate it with **Event Viewer > Applications and Services Logs > Microsoft > Windows > User Device Registration**. [Hybrid troubleshooting][hybrid]
4. **Investigate Intune separately.** For GPO auto-enrollment, check user licensing, enrollment scope, and the deployed MDM policy. Inspect **Event Viewer > Applications and Services Logs > Microsoft > Windows > DeviceManagement-Enterprise-Diagnostic-Provider > Admin**. Events 75/76 help identify auto-enrollment success/failure; correlate the event time with the current attempt. [Diagnose MDM enrollment][mdm-diagnose]
5. **Test the actual symptom.** Reproduce the affected app sign-in or resource access. Document the result separately from join and enrollment status. For on-premises Hello SSO, use the existing [cloud Kerberos trust guide](../Microsoft%20Intune/Windows%20Hello%20for%20Business%20Cloud%20Kerberos%20Trust%20Deployment%20Guide.md).

Illustrative excerpts showing two distinct failure paths:

```text
# User SSO investigation: inspect the PRT attempt, not just device join.
AzureAdPrt            : NO
AcquirePrtDiagnostics : PRESENT
Attempt Status       : <HRESULT from the affected user's attempt>

# Hybrid registration investigation: preserve the server explanation.
Error Phase          : join
Client ErrorCode     : 0x801c03f2
Server ErrorCode     : DirectoryError
Server Message       : <message returned for this registration attempt>
```

Field availability varies with build and scenario; these excerpts are not complete output or pass/fail templates. [PRT troubleshooting][prt-troubleshoot], [hybrid troubleshooting][hybrid]

For a proxy-related incident, this displays the configured WinHTTP proxy without changing it:

```powershell
netsh.exe winhttp show proxy
```

Do not equate that configuration with the browser's user-context route. Review actual connectivity in the failing context, including SYSTEM for hybrid registration. [WinHTTP][winhttp], [hybrid troubleshooting][hybrid]

For MDM or Autopilot evidence, use **Settings > Accounts > Access work or school > the relevant connection > Info > Create report** where available. Alternatively, Microsoft's collection tool can gather the relevant areas. From an authorized elevated shell, choose a private local output location:

```powershell
$diagnosticPath = Join-Path $env:TEMP ('MDMDiag-' + [guid]::NewGuid().ToString() + '.zip')
mdmdiagnosticstool.exe -area 'DeviceEnrollment;DeviceProvisioning;Autopilot' -zip $diagnosticPath
```

Inspect the resulting archive before sharing; it contains device, policy, certificate, registry, and event information. Collection writes an evidence file, not a repair. [Collect MDM logs][collect]

## 5. What the Microsoft MVP Sources Corroborate

| Firsthand source | Useful evidence | Limit of the evidence |
|---|---|---|
| Rudy Ooms, *The 0xd000000d Job 2: Nutty by Intune* (2023, updated 2024) | An Entra-joined device had a PRT but failed MDM enrollment; WAM and event-log investigation exposed a broken AAD BrokerPlugin after migration cleanup. | A specific failure investigation, not proof that every WAM error needs BrokerPlugin repair. Collect evidence before adapting its remediation. [Article][rudy] |
| Peter van der Woude, *Windows 10 MDM troubleshooting* (2019) | Demonstrates collecting enrollment, provisioning, Autopilot, and MDM evidence beyond `dsregcmd`. | Historical screenshots and file inventories; current collection instructions come from Microsoft Learn. [Article][peter], [current collection reference][collect] |

These articles were reviewed as published sources; the MVPs did not personally review this guide. Their award credentials are linked under Sources.

## 6. Verification, Recovery, and MSP Handover

- [ ] Customer tenant and device identity matched in the private case record.
- [ ] Affected-user and elevated captures clearly distinguished.
- [ ] Error code, phase, timestamp, and accompanying server message preserved.
- [ ] Join, PRT, MDM enrollment, and application access evaluated separately.
- [ ] Actual failing operation retested after any separately approved repair.
- [ ] Shared exports sanitized; raw evidence retained only under the customer's retention policy.

**Rollback:** The status and proxy-display commands change no join or policy configuration. Diagnostic collection creates an archive that can be removed according to the customer's evidence-retention rules. No join removal, TPM clearing, certificate deletion, enrollment reset, or BrokerPlugin repair is part of this guide. If a repair is required, document its scope and recovery steps in a separate change record before executing it.

**MSP handover:** Include the intended device state, affected user, collection context, evidence timestamps, unresolved question, and next owner. A different customer's settings or an old screenshot is not a substitute for the target tenant's evidence.

## Sources

- Microsoft Learn: [Dsregcmd status reference][dsreg].
- Microsoft Learn: [Hybrid-join troubleshooting][hybrid].
- Microsoft Learn: [PRT troubleshooting][prt-troubleshoot] and [PRT architecture][prt].
- Microsoft Learn: [Registered devices][registered] and [manage device identities][devices].
- Microsoft Learn: [Microsoft Entra Kerberos][kerberos].
- Microsoft Learn: [Automatic Intune enrollment][auto-enroll], [diagnose MDM enrollment][mdm-diagnose], and [collect MDM logs][collect].
- Microsoft Learn: [MDM registration error constants][mdm-errors] and [enrollment authorization failures][authorization].
- Microsoft Learn: [WinHTTP command reference][winhttp].
- Microsoft MVP Rudy Ooms: [WAM/BrokerPlugin enrollment case study][rudy]; [MVP award background](https://call4cloud.nl/rudy-ooms-and-a-series-of-fortunate-events/).
- Microsoft MVP Peter van der Woude: [Windows 10 MDM troubleshooting][peter]; [author credentials](https://petervanderwoude.nl/about/).

[dsreg]: https://learn.microsoft.com/en-us/entra/identity/devices/troubleshoot-device-dsregcmd
[hybrid]: https://learn.microsoft.com/en-us/entra/identity/devices/troubleshoot-hybrid-join-windows-current
[prt-troubleshoot]: https://learn.microsoft.com/en-us/entra/identity/devices/troubleshoot-primary-refresh-token
[prt]: https://learn.microsoft.com/en-us/entra/identity/devices/concept-primary-refresh-token
[registered]: https://learn.microsoft.com/en-us/entra/identity/devices/concept-device-registration
[devices]: https://learn.microsoft.com/en-us/entra/identity/devices/manage-device-identities
[kerberos]: https://learn.microsoft.com/en-us/entra/identity/authentication/kerberos
[auto-enroll]: https://learn.microsoft.com/en-us/intune/device-enrollment/windows/quickstart-automatic-mdm
[mdm-diagnose]: https://learn.microsoft.com/en-us/windows/client-management/mdm-diagnose-enrollment
[collect]: https://learn.microsoft.com/en-us/windows/client-management/mdm-collect-logs
[mdm-errors]: https://learn.microsoft.com/en-us/windows/win32/mdmreg/mdm-registration-constants
[authorization]: https://learn.microsoft.com/en-us/troubleshoot/mem/intune/device-enrollment/windows-user-cannot-enroll
[winhttp]: https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/netsh-winhttp
[rudy]: https://call4cloud.nl/0xd000000d-intune-enrollment-error/
[peter]: https://petervanderwoude.nl/post/windows-10-mdm-troubleshooting/
