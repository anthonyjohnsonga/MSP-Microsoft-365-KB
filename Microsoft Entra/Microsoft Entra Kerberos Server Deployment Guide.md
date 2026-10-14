# Microsoft Entra Kerberos Server Deployment Guide

**Applies to:** Microsoft Entra ID; Active Directory Domain Services; Windows Hello for Business cloud Kerberos trust<br>
**Scope:** Create and verify Microsoft Entra Kerberos server objects, then hand off to workstation policy deployment.<br>
**Last Updated:** October 2026

**Example organization:** ABC Company. All company identifiers, domains, server names, IDs, key versions, and timestamps below are fictional. The `.example` domain is reserved for documentation. Replace these examples with the appropriate values when using the guide.

This guide covers installing the required PowerShell module, checking for an existing Microsoft Entra Kerberos server object, creating it if necessary, and verifying that it was created successfully.

## Prerequisites

| Requirement | Detail |
|---|---|
| Management server | Use the Entra Connect server or a server with `Microsoft.Online.PasswordSynchronization.Rpc.dll` installed. Module installation alone does not supply every creation prerequisite. Open an elevated PowerShell session. |
| Cloud permissions | Microsoft Entra **Hybrid Identity Administrator** in the correct customer tenant. |
| AD permissions | Domain Admin in the target domain and Enterprise Admin in its forest for setup. |
| Identity | Synchronized users with `onPremisesSamAccountName`, `onPremisesDomainName`, and `onPremisesSecurityIdentifier` populated. |
| Domain controllers | Supported, patched Windows Server 2016 or later; adequate writable DC capacity in authentication sites. If DC Kerberos encryption policy is restricted, allow AES256_HMAC_SHA1. |
| Pilot | A synchronized standard user, an Entra joined or hybrid joined client, and connectivity to Entra ID, AD DNS, a writable DC, and an authorized resource. |
| Licensing | Cloud trust itself does not require Entra ID P1/P2. Intune management, automatic enrollment, and Conditional Access have separate licensing requirements; see the companion guide. |
| AD verification | ActiveDirectory PowerShell module/RSAT and permission to read objects in the target domain. |

**MSP note:** Confirm tenant, forest, domain, and cloud environment before running commands. Repeat setup for each domain containing users who need this capability. Reuse existing Entra Kerberos infrastructure used by FIDO2 on-premises SSO. Do not relax privileged-account password replication restrictions to make an administrator account pass the workstation test.

For supported client versions, policy deployment, and licensing details, see the [Intune Cloud Kerberos Trust Deployment Guide](../Microsoft%20Intune/Windows%20Hello%20for%20Business%20Cloud%20Kerberos%20Trust%20Deployment%20Guide.md).

## 1. Install the Required Module

Open **PowerShell as Administrator** on the server you’re using.

Microsoft uses the **AzureADHybridAuthenticationManagement** module to create and manage the Microsoft Entra Kerberos server object.

Run:

```powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
Install-Module AzureADHybridAuthenticationManagement -Scope AllUsers -AllowClobber
```

Then import the module:

```powershell
Import-Module AzureADHybridAuthenticationManagement
```

---

## 2. Set the Domain Name

Set the `$domain` variable to the organization's **Active Directory DNS domain name**.

Example:

```powershell
$domain = "ad.abccompany.example"
```

> Replace `ad.abccompany.example` with the actual on-premises Active Directory domain.

---

## 3. Prompt for Cloud and Domain Credentials

You will need:

- A Microsoft Entra account with the required Entra administrative role.

- An Active Directory account with the necessary domain-level administrative permissions.

Run:

```powershell
$cloudCred = Get-Credential -Message "Enter a Microsoft Entra account with the required Entra admin role"

$domainCred = Get-Credential -Message "Enter an Active Directory account that is Domain Admin and Enterprise Admin"
```

Enter the AD username in UPN form, such as `ad-admin@ad.abccompany.example`, especially when managing another domain.

The credential-based workflow above remains available. **For a cloud account protected by MFA or other modern authentication requirements, use interactive sign-in instead of `-CloudCredential`:**

```powershell
$userPrincipalName = "hybrid-admin@abccompany.example"
# Keep $domainCred from the AD credential prompt above.
```

In the following check, creation, and verification commands, replace `-CloudCredential $cloudCred` with `-UserPrincipalName $userPrincipalName`. For example:

```powershell
Get-AzureADKerberosServer -Domain $domain -UserPrincipalName $userPrincipalName -DomainCredential $domainCred
```

Do not weaken MFA to use the credential-based path. If the current Windows account has the required AD rights, Microsoft also documents omitting `-DomainCredential`; consult the source for the Protected Users caveat.

**Cloud environment:** These examples assume Azure Commercial. For a sovereign cloud, inspect `Get-AzureADKerberosServerEndpoint` and configure the appropriate endpoint using Microsoft's setup instructions before proceeding.

---

## 4. Check Whether Microsoft Entra Kerberos Already Exists

Before creating anything, check whether the Microsoft Entra Kerberos server object already exists.

Run:

```powershell
Get-AzureADKerberosServer -Domain $domain -CloudCredential $cloudCred -DomainCredential $domainCred
```

If the command returns an existing Kerberos server object, Microsoft Entra Kerberos may already be configured.

Do **not** immediately run the creation command if an existing object is returned. Review the existing configuration first.

---

## 5. Create the Microsoft Entra Kerberos Server Object

If the check succeeds and confirms that the object does not exist, create it using the matching authentication method below. An authentication, permission, or connectivity error does not prove absence.

```powershell
Set-AzureADKerberosServer -Domain $domain -CloudCredential $cloudCred -DomainCredential $domainCred
```

For interactive cloud authentication:

```powershell
Set-AzureADKerberosServer -Domain $domain -UserPrincipalName $userPrincipalName -DomainCredential $domainCred
```

Run only the variant appropriate to your environment. This creates the required Microsoft Entra Kerberos objects in Active Directory and publishes the corresponding information to Microsoft Entra ID.

Allow the command to complete before proceeding with verification.

---

## 6. Confirm the Kerberos Server Was Created Successfully

Run:

```powershell
Get-AzureADKerberosServer -Domain $domain -CloudCredential $cloudCred -DomainCredential $domainCred
```

A successful configuration should return information similar to:

```text
Id                 : 12345
UserAccount        : CN=krbtgt_AzureAD,CN=Users,DC=ad,DC=abccompany,DC=example
ComputerAccount    : CN=AzureADKerberos,OU=Domain Controllers,DC=ad,DC=abccompany,DC=example
DisplayName        : ad.abccompany.example
DomainDnsName      : ad.abccompany.example
KeyVersion         : 10001
KeyUpdatedOn       : 1/15/2026 10:00:00 AM
KeyUpdatedFrom     : ABC-DC01.ad.abccompany.example
CloudDisplayName   : ad.abccompany.example
CloudDomainDnsName : ad.abccompany.example
CloudId            : 12345
CloudKeyVersion    : 10001
CloudKeyUpdatedOn  : 1/15/2026 10:00:00 AM
```

### What to Verify

| Comparison | Expected result |
|---|---|
| `Id` and `CloudId` | Match. |
| `DomainDnsName` and `CloudDomainDnsName` | Match the target AD DNS domain, not the tenant email suffix. |
| `KeyVersion` and `CloudKeyVersion` | Match. |
| `KeyUpdatedOn` and `CloudKeyUpdatedOn` | Populated and match. |
| `UserAccount`, `ComputerAccount`, and `KeyUpdatedFrom` | Identify the expected domain objects and DC. |

The output above is illustrative. Do not expect the sample IDs, versions, or dates in a real deployment.
### Note About a Blank `UpdatedOn` Value

**Observed in deployments using this guide:** Immediately after configuring Microsoft Entra Kerberos, you may notice that an additional `UpdatedOn` property at the bottom of the output is blank.

If the important Kerberos properties are populated and the following values match:

```text
KeyVersion       : <value>
CloudKeyVersion  : <same value>
```

and both of these contain timestamps:

```text
KeyUpdatedOn
CloudKeyUpdatedOn
```

a blank generic `UpdatedOn` property by itself is **not necessarily an indication that the configuration failed**.

Do not delete or recreate the Kerberos object based solely on this field being blank immediately after configuration.

Microsoft Learn documents the specific key properties above, but does not define the generic `UpdatedOn` field or promise that it will populate later. Recheck the documented properties and complete the workstation test; do not infer failure or success from that field alone.

---

## 7. Verify the Active Directory Objects

You can also verify that the corresponding objects were created in Active Directory.

Check for the Azure AD Kerberos `krbtgt` account:

```powershell
Get-ADUser -Filter 'SamAccountName -like "krbtgt_AzureAD*"' -Server $domain -Credential $domainCred
```

You should see an account similar to:

```text
Name              : krbtgt_AzureAD
ObjectClass       : user
SamAccountName    : krbtgt_AzureAD
Enabled           : False
```

The account being **disabled is expected**. Do not manually enable it.

Next, check for the AzureADKerberos computer object:

```powershell
Get-ADComputer -Identity AzureADKerberos -Server $domain -Credential $domainCred
```

You should see an object similar to:

```text
Name              : AzureADKerberos
ObjectClass       : computer
SamAccountName    : AzureADKerberos$
Enabled           : False
```

These objects confirm the AD-side presence. Object existence alone does not verify cloud publication or workstation SSO. Treat the computer Enabled value above as illustrative; do not manually toggle these managed objects to match sample output.

---

## 8. Configure and Verify a Pilot Workstation

Creating the server object establishes infrastructure; configure WHfB on the client before testing it. Follow the [Intune Cloud Kerberos Trust Deployment Guide](../Microsoft%20Intune/Windows%20Hello%20for%20Business%20Cloud%20Kerberos%20Trust%20Deployment%20Guide.md) for policy assignment, provisioning, and conflicts.

For a GPO-managed hybrid joined pilot, use **Computer Configuration > Administrative Templates > Windows Components > Windows Hello for Business**:

| Setting | Value |
|---|---|
| Use Windows Hello for Business | Enabled |
| Use cloud Kerberos trust for on-premises authentication | Enabled |
| Use a hardware security device | Enabled after TPM validation; recommended, not mandatory for cloud trust |

Keep certificate trust unconfigured. Choose GPO or Intune for WHfB management; avoid mixing them. GPO takes precedence and `MDMWinsOverGP` does not apply to PassportForWork policies.

### Missing Cloud Trust Setting in Group Policy

Back up the existing Central Store and follow [Microsoft's Central Store guidance](https://learn.microsoft.com/en-us/troubleshoot/windows-client/group-policy/create-and-manage-central-store). Obtain matching ADMX/ADML versions from a supported Windows client:

```text
C:\Windows\PolicyDefinitions\Passport.admx
C:\Windows\PolicyDefinitions\en-US\Passport.adml
```

For ABC Company's illustrative AD domain, the destination is:

```text
\\ad.abccompany.example\SYSVOL\ad.abccompany.example\Policies\PolicyDefinitions\Passport.admx
\\ad.abccompany.example\SYSVOL\ad.abccompany.example\Policies\PolicyDefinitions\en-US\Passport.adml
```

Use the appropriate ADML language folders for administrators. Reopen Group Policy Management and verify the setting appears. Changing templates exposes policy settings; it does not configure or deploy them.

### Verify Sign-In and Resource Access

1. Use a synchronized standard user. On hybrid joined devices, the first Hello sign-in requires DC connectivity.
2. After signing in with Hello, run this in that user's **non-elevated** session:

   ```powershell
   dsregcmd.exe /status
   ```

3. Confirm `AzureAdJoined : YES`, `NgcSet : YES`, and `AzureAdPrt : YES`. Hybrid joined devices also require `DomainJoined : YES`; Entra joined devices normally show `DomainJoined : NO`.
4. On current Windows builds, `OnPremTgt : YES` indicates the partial ticket for on-premises access. `CloudTgt` refers to cloud resources and is not proof of AD SSO. Output labels vary by Windows version.
5. Open an authorized share by DNS name, such as `\\ABC-FS01.ad.abccompany.example\PilotShare`, without supplying alternate credentials. In the same session, run:

   ```powershell
   klist.exe
   ```

6. Verify a full AD `krbtgt` ticket, a `cifs` service ticket for the server, and access without a password prompt. The partial ticket and successful Hello provisioning alone are insufficient.

## Verification Checklist

- [ ] Correct customer tenant, forest, domain, and cloud endpoint confirmed.
- [ ] Existing-object check completed successfully before any creation.
- [ ] AD user and computer objects found in the intended domain.
- [ ] On-premises and cloud IDs, domain names, key versions, and key timestamps match.
- [ ] Generic blank `UpdatedOn` treated as an observation, not a documented health criterion.
- [ ] Client policy and provisioning completed with the chosen management source.
- [ ] Standard pilot user signs in with Hello and receives a partial on-premises ticket.
- [ ] Full AD TGT, resource service ticket, and prompt-free authorized access verified.
- [ ] Key maintenance and recovery ownership recorded for the customer.

## Troubleshooting

| Symptom | Action |
|---|---|
| Cloud sign-in fails with credential parameters | Use the documented interactive `-UserPrincipalName` variant for MFA-protected accounts; verify the tenant and role. |
| Cross-domain RPC authentication fails | Use AD credentials in UPN format and review Microsoft's Protected Users/current-logon guidance. |
| Object check returns an error | Resolve authentication, rights, dependencies, or connectivity; do not treat an error as permission to create another object. |
| Cloud and AD values differ | Review publication, domain selection, and AD replication. Preserve sanitized evidence before making changes. |
| Blank generic `UpdatedOn` | Evaluate documented key properties and the client resource test. Do not delete/recreate solely for this field. |
| Partial ticket exists but access fails | Check writable DC reachability, DNS, clock skew, SPNs, and resource permissions; inspect service tickets. |
| Privileged account cannot use cloud trust | Test a standard user; retain the default AzureADKerberos password replication restrictions. |

## Maintenance and Rollback

Use the Entra Kerberos module's documented `-RotateServerKey` workflow for scheduled key rotation so AD and Entra stay aligned. Follow the customer's krbtgt maintenance schedule; do not rotate this account with an unrelated AD-only tool.

For client-policy rollback, use the companion Intune guide and preserve an alternate sign-in method. Infrastructure removal affects every deployment using this domain's Entra Kerberos server, including FIDO2 on-premises SSO. Inventory dependencies before an approved retirement, then use Microsoft's documented `Remove-AzureADKerberosServer` workflow to remove both sides. Do not manually delete the AD objects as a troubleshooting shortcut. Restore Central Store templates from the recorded backup if a template update must be reversed.

**Validation scope:** The owner reports successful use of the original setup workflow in multiple deployments. This revision was checked against Microsoft Learn; no tenant commands were executed during this review. The generic `UpdatedOn` note remains an explicitly labeled field observation.

## Sources

- Microsoft Learn: [Microsoft Entra Kerberos setup, authentication variants, verification, rotation, and removal](https://learn.microsoft.com/en-us/entra/identity/authentication/howto-authentication-passwordless-security-key-on-premises).
- Microsoft Learn: [WHfB cloud Kerberos trust deployment](https://learn.microsoft.com/en-us/windows/security/identity-protection/hello-for-business/deploy/hybrid-cloud-kerberos-trust).
- Microsoft Learn: [Configure WHfB and policy precedence](https://learn.microsoft.com/en-us/windows/security/identity-protection/hello-for-business/configure).
- Microsoft Learn: [dsregcmd diagnostics](https://learn.microsoft.com/en-us/entra/identity/devices/troubleshoot-device-dsregcmd).
- Microsoft Learn: [Introduction to Microsoft Entra Kerberos](https://learn.microsoft.com/en-us/entra/identity/authentication/kerberos).
- Microsoft Learn: [Create and manage the Group Policy Central Store](https://learn.microsoft.com/en-us/troubleshoot/windows-client/group-policy/create-and-manage-central-store).
- Microsoft Learn: [Get-ADComputer](https://learn.microsoft.com/en-us/powershell/module/activedirectory/get-adcomputer?view=windowsserver2025-ps).
