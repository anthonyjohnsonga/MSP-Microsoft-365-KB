# Microsoft Exchange Online Email Encryption Setup Guide

**Applies to:** Microsoft 365 tenants with Microsoft Purview Message Encryption entitlement (Microsoft 365 Business Premium, E3, E5)  
**Scope:** Enabling and verifying Microsoft Purview Message Encryption end to end — Azure Rights Management activation, Exchange Online IRM configuration, RMS template troubleshooting, and functional testing. Cloud-only; on-premises AD RMS is out of scope.  
**Last Updated:** August 2026

**Example organization:** Green Moon  
**Example domain:** `greenmoon.com`

> Message Encryption is a Purview feature, but it is enabled and troubleshot almost entirely from Exchange Online PowerShell — hence its home in this folder. See also [Microsoft Purview](../Microsoft%20Purview/README.md) for related data-protection guides.

---

## 1. Prerequisites

Before beginning, confirm the following:

- You have an account with sufficient administrative permissions in Microsoft 365 and Azure Rights Management.
- The affected users have licensing that supports Microsoft Purview Message Encryption, such as Microsoft 365 Business Premium.
- You have access to a licensed test mailbox, such as `encryptiontest@greenmoon.com`.
- Windows PowerShell 5.1 is available for the `AIPService` module.

Check the PowerShell version:

```powershell
$PSVersionTable.PSVersion
```

The major version should be `5` when using the `AIPService` module.

---

## 2. Install the Required PowerShell Modules

Open **Windows PowerShell 5.1 as Administrator**.

```powershell
Install-PackageProvider -Name NuGet -Force
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

Install-Module -Name AIPService -Scope AllUsers -Force
Install-Module -Name ExchangeOnlineManagement -Scope AllUsers -Force
```

Import the modules:

```powershell
Import-Module AIPService
Import-Module ExchangeOnlineManagement
```

Confirm that the AIPService commands are available:

```powershell
Get-Command -Module AIPService
```

---

## 3. Connect to Microsoft 365 Services

Connect to Exchange Online:

```powershell
Connect-ExchangeOnline
```

Connect to Azure Rights Management:

```powershell
Connect-AipService
```

Sign in with an administrator account for the Green Moon tenant when prompted.

---

## 4. Verify Azure Rights Management

Check whether the Azure Rights Management protection service is enabled:

```powershell
Get-AipService
```

Expected result:

```text
Enabled
```

If it is disabled, enable it:

```powershell
Enable-AipService
```

Then verify again:

```powershell
Get-AipService
```

Review the tenant's Azure Rights Management configuration:

```powershell
Get-AipServiceConfiguration
```

Confirm that the following values show as enabled:

```text
FunctionalState             : Enabled
IPCv3ServiceFunctionalState : Enabled
```

---

## 5. Enable Exchange Online IRM

Enable Microsoft Purview Message Encryption and the related Exchange Online IRM settings:

```powershell
Set-IRMConfiguration -AzureRMSLicensingEnabled $true
Set-IRMConfiguration -InternalLicensingEnabled $true
Set-IRMConfiguration -ExternalLicensingEnabled $true
Set-IRMConfiguration -SimplifiedClientAccessEnabled $true
```

Review the configuration:

```powershell
Get-IRMConfiguration | Format-List `
    AzureRMSLicensingEnabled,
    InternalLicensingEnabled,
    ExternalLicensingEnabled,
    SimplifiedClientAccessEnabled,
    LicensingLocation
```

Expected values:

```text
AzureRMSLicensingEnabled      : True
InternalLicensingEnabled      : True
ExternalLicensingEnabled      : True
SimplifiedClientAccessEnabled : True
```

The `LicensingLocation` value may initially be empty.

---

## 6. Test RMS Template Retrieval

Run:

```powershell
Get-RMSTemplate | Format-Table Name,Type,Guid -AutoSize
```

Then test the IRM configuration with a licensed mailbox:

```powershell
Test-IRMConfiguration `
    -Sender encryptiontest@greenmoon.com `
    -Recipient encryptiontest@greenmoon.com
```

A successful test should end with:

```text
OVERALL RESULT: PASS
```

If the test passes and `Get-RMSTemplate` returns templates, continue to the final functional test.

---

## 7. Fix “Failed to Acquire RMS Templates”

If the test returns the following error:

```text
FAIL: Failed to acquire RMS templates.
OVERALL RESULT: FAIL
```

retrieve the tenant-specific RMS licensing URL:

```powershell
$RMSConfig = Get-AipServiceConfiguration
$LicenseUri = $RMSConfig.LicensingIntranetDistributionPointUrl
```

Display the URL before applying it:

```powershell
$LicenseUri
```

It should resemble the following example:

```text
https://11111111-2222-3333-4444-555555555555.rms.na.aadrm.com/_wmcs/licensing
```

Apply it to Exchange Online:

```powershell
Set-IRMConfiguration `
    -LicensingLocation $LicenseUri `
    -InternalLicensingEnabled $true `
    -AzureRMSLicensingEnabled $true
```

Verify that the URL was saved:

```powershell
(Get-IRMConfiguration).LicensingLocation.AbsoluteUri
```

Refresh internal licensing:

```powershell
Set-IRMConfiguration -InternalLicensingEnabled $false -Force
Set-IRMConfiguration -InternalLicensingEnabled $true
```

Reconnect to Exchange Online:

```powershell
Disconnect-ExchangeOnline -Confirm:$false
Connect-ExchangeOnline
```

Retest:

```powershell
Get-RMSTemplate | Format-Table Name,Type,Guid -AutoSize

Test-IRMConfiguration `
    -Sender encryptiontest@greenmoon.com `
    -Recipient encryptiontest@greenmoon.com
```

---

## 8. Allow Time for Microsoft 365 Propagation

The configuration may not begin working immediately after setting `LicensingLocation` or refreshing internal licensing.

If all settings appear correct but `Get-RMSTemplate` remains blank, leave the configuration in place and allow Microsoft 365 time to synchronize Azure Rights Management templates with Exchange Online.

Recommended approach:

1. Retest after approximately one hour.
2. Retest later the same day.
3. Allow until the next day before assuming that the tenant has a backend provisioning problem.

Do not repeatedly disable Azure Rights Management, delete templates, or modify Microsoft-managed protection templates while waiting for synchronization.

---

## 9. Verify Published Azure RMS Templates

If template retrieval continues to fail, inspect the Azure RMS templates:

```powershell
Get-AipServiceTemplate
```

Example output might include:

```text
Confidential \ All Employees
Highly Confidential \ All Employees
```

Check the status of a specific template by using its GUID:

```powershell
Get-AipServiceTemplateProperty `
    -TemplateId "11111111-2222-3333-4444-555555555555" `
    -Names `
    -Status `
    -ReadOnly `
    -ScopedIdentities `
    -EnableInLegacyApps
```

At least one usable template should show:

```text
Status : Published
```

Microsoft-managed templates may also show:

```text
ReadOnly : True
```

Do not attempt to edit Microsoft-managed read-only templates.

---

## 10. Verify the Test User’s License

For a Microsoft 365 Business Premium user, verify that the Rights Management service plans are successfully provisioned.

Connect to Microsoft Graph if required:

```powershell
Connect-MgGraph -Scopes User.Read.All,Directory.Read.All
```

Check the user's service plans:

```powershell
Get-MgUserLicenseDetail -UserId encryptiontest@greenmoon.com |
    Select-Object -ExpandProperty ServicePlans |
    Sort-Object ServicePlanName |
    Format-Table ServicePlanName,ProvisioningStatus -AutoSize
```

Look for the following plans with a status of `Success`:

```text
RMS_S_ENTERPRISE
RMS_S_PREMIUM
EXCHANGE_S_STANDARD
```

Intune service plans showing `PendingInput` or `PendingActivation` do not normally affect email encryption.

---

## 11. Perform a Functional Email Test

After `Test-IRMConfiguration` passes:

1. Sign in to Outlook on the web as `encryptiontest@greenmoon.com`.
2. Create a new email to an external test address.
3. Select **Options** and then **Encrypt**.
4. Test the available options, such as **Encrypt** and **Do Not Forward**.
5. Confirm the external recipient can open the encrypted message.
6. Confirm restrictions such as forwarding or copying behave as expected.

---

## 12. Final Verification Commands

Use this command set for a final health check:

```powershell
Get-AipService

Get-IRMConfiguration | Format-List `
    AzureRMSLicensingEnabled,
    InternalLicensingEnabled,
    ExternalLicensingEnabled,
    SimplifiedClientAccessEnabled,
    LicensingLocation

Get-RMSTemplate | Format-Table Name,Type,Guid -AutoSize

Test-IRMConfiguration `
    -Sender encryptiontest@greenmoon.com `
    -Recipient encryptiontest@greenmoon.com
```

A healthy configuration should have:

- Azure Rights Management enabled.
- Exchange IRM settings enabled.
- A tenant RMS licensing URL populated when required.
- One or more active RMS templates returned by `Get-RMSTemplate`.
- `Test-IRMConfiguration` reporting `OVERALL RESULT: PASS`.
- Successful encrypted-message testing from Outlook.

---

## 13. Troubleshooting Summary

| Symptom | Likely cause or action |
|---|---|
| `Connect-AipService` is not recognized | Install/import the `AIPService` module in Windows PowerShell 5.1. |
| `Get-AipService` returns `Disabled` | Run `Enable-AipService`. |
| `AzureRMSLicensingEnabled` is `False` | Enable it with `Set-IRMConfiguration`. |
| `Get-RMSTemplate` returns nothing | Confirm internal licensing, set the licensing URL, and allow synchronization time. |
| `Test-IRMConfiguration` fails to acquire templates | Populate `LicensingLocation`, refresh internal licensing, reconnect, and retest later. |
| Templates are published but Exchange sees none | Allow time for backend synchronization; escalate only if it remains broken after an appropriate propagation period. |
| A user cannot encrypt but the tenant test passes | Verify the user's license, service plans, mailbox, Outlook policy, and client behavior. |

---

## 14. Disconnect When Finished

```powershell
Disconnect-AipService
Disconnect-ExchangeOnline -Confirm:$false
```

---

## Sources

- Microsoft Learn: [Set up Microsoft Purview Message Encryption](https://learn.microsoft.com/en-us/purview/set-up-new-message-encryption-capabilities)
- Microsoft Learn: [Install the AIPService PowerShell module](https://learn.microsoft.com/en-us/purview/install-aipservice-powershell)
- Microsoft Learn: [Activate Azure Rights Management](https://learn.microsoft.com/en-us/purview/activate-rights-management-service)
- Microsoft Learn: [Get-RMSTemplate](https://learn.microsoft.com/en-us/powershell/module/exchangepowershell/get-rmstemplate?view=exchange-ps)
- Microsoft Learn: [Microsoft Purview Message Encryption FAQ](https://learn.microsoft.com/en-us/purview/ome-faq)

