# Microsoft Edge Enterprise Sync Troubleshooting

**Applies to:** Microsoft Edge for Business, Microsoft Entra accounts, Microsoft Purview Rights Management  
**Scope:** Diagnose and resolve the “Sync isn't available for this account” error for organizational Edge profiles.  
**Last Updated:** September 2026

---

## Purpose

Use this runbook when Microsoft Edge shows **Sync isn't available for this account** for a Microsoft Entra work or school account.

## Symptoms

- The user can sign into Microsoft Edge, but sync is unavailable.
- The user has a Microsoft 365 subscription that supports Edge enterprise sync.
- The assigned Edge configuration profile does not appear to disable sync.

## 1. Check the effective Edge policies

On the affected device, open the following page in Microsoft Edge:

```text
edge://policy
```

Select **Reload policies**, and then look for these policies:

| Policy | Blocking value | Effect |
| --- | --- | --- |
| `SyncDisabled` | `true` or `1` | Disables Edge cloud synchronization completely. |
| `BrowserSignin` | `0` | Prevents users from signing into an Edge browser profile. |
| `SyncTypesListDisabled` | One or more listed data types | Prevents only the listed data types from syncing. |

If `SyncDisabled` is not present, or is set to `false`/`0`, the effective Edge policy is not disabling synchronization.

> Checking `edge://policy` is important even when the Intune profile does not contain these settings. Another Intune profile, security baseline, Group Policy, registry setting, or management platform could be applying them.

## 2. Confirm the user's licensing

Verify that the affected user has an active license that supports Microsoft Edge enterprise sync, such as Microsoft 365 Business Premium.

The license must be assigned to the affected user; it is not enough for the subscription to exist in the tenant.

## 3. Check the Azure Rights Management service

Microsoft Edge enterprise sync uses the tenant's Azure Rights Management service to protect synchronized organizational data.

Run these commands from a PowerShell session with the AIPService module installed. Sign in with an account assigned an appropriate role, such as **Compliance Administrator** or **Compliance Data Administrator**.

```powershell
Install-Module AIPService -Scope CurrentUser
Import-Module AIPService
Connect-AipService
```

Check the main service state:

```powershell
Get-AipService
```

Check only the relevant configuration properties. This avoids displaying unnecessary tenant-specific identifiers and service URLs:

```powershell
Get-AipServiceConfiguration |
    Select-Object FunctionalState,IPCv3ServiceFunctionalState
```

Check the onboarding scope and IPCv3 service:

```powershell
Get-AipServiceOnboardingControlPolicy
Get-AipServiceIPCv3
```

### Interpret the results

| Check | Healthy result | Meaning of an unhealthy result |
| --- | --- | --- |
| `Get-AipService` | `Enabled` | `Disabled` means the tenant-wide Rights Management service is inactive. |
| `FunctionalState` | `Enabled` | `Disabled` can prevent Edge enterprise sync. |
| `IPCv3ServiceFunctionalState` | `Enabled` | A disabled IPCv3 service can prevent Edge from using the protection service. |
| `Get-AipServiceIPCv3` | `Enabled` | A disabled result requires additional service configuration. |
| Onboarding control | User is included or no restrictive group is configured | A scoped onboarding policy can exclude the affected user from Rights Management. |

An example diagnosis is:

```text
Azure Rights Management service: Disabled
Functional state:               Disabled
IPCv3 service:                  Enabled
Onboarding restriction:         None
```

In this situation, the disabled tenant-wide Rights Management service is the likely cause of Edge sync being unavailable.

## 4. Enable Azure Rights Management

> **Important:** Do not activate Azure Rights Management if the organization currently uses an on-premises Active Directory Rights Management Services (AD RMS) deployment. Review the coexistence and migration requirements first.

If the organization does not use on-premises AD RMS, activate the service from the connected AIPService PowerShell session:

```powershell
Enable-AipService
```

This is a tenant-wide change. It makes Rights Management encryption available to supported services and applications, including Edge enterprise sync, sensitivity-label encryption, Office document protection, and email encryption. It does not automatically encrypt every document or email.

## 5. Verify the service

Run:

```powershell
Get-AipService

Get-AipServiceConfiguration |
    Select-Object FunctionalState,IPCv3ServiceFunctionalState
```

Expected results:

```text
Enabled

FunctionalState             : Enabled
IPCv3ServiceFunctionalState : Enabled
```

## 6. Test Enterprise State Roaming if sync remains unavailable

If Rights Management and IPCv3 are already enabled but Edge still reports `DISABLED_BY_ADMIN`, Microsoft’s troubleshooting sequence recommends temporarily enabling Enterprise State Roaming (ESR).

> **Important:** Chromium-based Edge sync is not part of ESR. This is a tenant-remediation test, and Microsoft states that ESR does not need to remain enabled if turning it on resolves the Edge sync problem.

1. Sign in to the **Microsoft Entra admin center** as a Global Administrator.
2. Browse to **Entra ID > Devices > Overview > Enterprise State Roaming**.
3. Set **Users may sync settings and app data across devices** to **All** or a group containing the pilot user.
4. Save the setting, sign out of the Edge profile, sign back in, and test sync again.
5. If sync begins working, document the result and decide whether to retain or disable ESR according to the tenant’s requirements.

## 7. Confirm sync in Microsoft Edge

After the service reports `Enabled`:

1. Close all Microsoft Edge windows.
2. Reopen Microsoft Edge.
3. If sync is still unavailable, sign out of the Edge browser profile and sign back in.
4. Open:

   ```text
   edge://sync-internals
   ```

5. Review the **Summary** and **Credentials** sections. Confirm that sync is enabled and that errors such as `DISABLED_BY_ADMIN` or token failures are no longer present.
6. Open **Settings > Profiles > Sync** and confirm that synchronization is on.

## Outcome

If Edge sync becomes available after `Enable-AipService`, the root cause was the disabled Azure Rights Management service—not the Edge configuration profile.

## Sources

- [Configure Microsoft Edge enterprise sync](https://learn.microsoft.com/en-us/deployedge/microsoft-edge-enterprise-sync)
- [Diagnose and fix Microsoft Edge sync issues](https://learn.microsoft.com/en-us/deployedge/microsoft-edge-troubleshoot-enterprise-sync)
- [Activate the Azure Rights Management service](https://learn.microsoft.com/en-us/purview/activate-rights-management-service)
- [Enable Enterprise State Roaming in Microsoft Entra ID](https://learn.microsoft.com/en-us/entra/identity/devices/enterprise-state-roaming-enable)
- [SyncDisabled policy reference](https://learn.microsoft.com/en-us/deployedge/microsoft-edge-policies/SyncDisabled)
