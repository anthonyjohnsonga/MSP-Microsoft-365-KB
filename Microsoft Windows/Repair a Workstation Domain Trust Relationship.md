# Repair a Workstation Domain Trust Relationship

**Applies to:** AD domain-joined Windows 11 workstations; Windows 10 under an applicable support arrangement; Windows PowerShell 5.1<br>
**Scope:** Test and repair a workstation's Active Directory secure channel without first removing and rejoining the domain; excludes domain controllers and Entra-only joined devices<br>
**Last Updated:** October 2026

---

## Overview

Sign in to the affected workstation with an authorized local administrator account and open **Windows PowerShell > Run as administrator**. Confirm domain-controller connectivity, test the secure channel, and repair it only if the test fails.

Use this procedure for the error **The trust relationship between this workstation and the primary domain failed**. A failed test can also reflect connectivity problems; verify prerequisites before resetting credentials. Hybrid joined workstations can use this AD repair, but it does not repair Microsoft Entra registration.

## Prerequisites

| Requirement | Detail |
|---|---|
| Local access | A working local administrator account and an elevated Windows PowerShell 5.1 session on the affected workstation. |
| Domain credentials | An account permitted to repair the workstation's secure channel/reset its computer account password. Use appropriately delegated permissions; Domain Admin membership is not inherently required. |
| AD connectivity | Corporate LAN or VPN access to a healthy writable domain controller. The workstation must use DNS that resolves the customer's AD domain and DC records correctly. |
| Computer account | Confirm the expected AD computer account exists and is enabled. Investigate duplicate names, unexpected deletion, or recent restore/reimage activity. |
| Time and services | Check workstation time and Windows Time/Netlogon status if authentication or discovery fails. |
| Licensing | Built-in Windows commands; no additional Microsoft 365 license or PowerShell module is required. |

**MSP note:** Verify the endpoint, AD domain, and customer-specific delegated account before prompting for credentials. Use `DOMAIN\username` or the appropriate domain UPN at the prompt. Keep credentials and customer identifiers out of scripts and public examples.

---

## 1. Confirm Domain Membership and Connectivity

1. On the affected workstation, open elevated Windows PowerShell and run:

   ```powershell
   hostname.exe
   Get-CimInstance Win32_ComputerSystem |
       Select-Object Name, Domain, PartOfDomain, DomainRole
   ```

2. Confirm `PartOfDomain` is `True` and the domain is correct. Stop if the computer is a domain controller (`DomainRole` 4 or 5); this runbook is for workstations.
3. Connect to the corporate network or required VPN. Replace the example domain below and check DC discovery:

   ```powershell
   nltest.exe /dsgetdc:contoso.com
   ```

4. If discovery fails, resolve DNS, connectivity, time, or DC availability before continuing. Successful discovery alone does not prove the secure channel is healthy.

## 2. Test the Secure Channel

```powershell
Test-ComputerSecureChannel -Verbose
```

- **True:** The channel passed this test. Investigate the original sign-in failure rather than resetting it automatically.
- **False or an error:** Review the error and confirm prerequisites, then proceed to repair if a broken channel is indicated.

## 3. Repair the Secure Channel

1. Prompt for the delegated domain credentials and attempt repair:

   ```powershell
   $domainCredential = Get-Credential
   Test-ComputerSecureChannel -Repair -Credential $domainCredential -Verbose
   ```

2. Check the result, then run a fresh test:

   ```powershell
   Test-ComputerSecureChannel -Verbose
   ```

3. Expect `True`. If it succeeds, skip the alternative method below and continue to section 5.

To target a known healthy writable DC, use `-Server` consistently for repair and verification. Replace the illustrative FQDN:

```powershell
Test-ComputerSecureChannel -Repair -Server "dc01.contoso.com" -Credential $domainCredential -Verbose
Test-ComputerSecureChannel -Server "dc01.contoso.com" -Verbose
```

## 4. Alternative: Reset the Machine Account Password

Use this as an alternative repair path when appropriate to the diagnosed failure, rather than routinely running it after a successful secure-channel repair. Investigate access, discovery, or replication errors before attempting another reset.

In the same elevated session, with the credential variable from section 3:

```powershell
Reset-ComputerMachinePassword -Server "dc01.contoso.com" -Credential $domainCredential -ErrorAction Stop
Test-ComputerSecureChannel -Server "dc01.contoso.com" -Verbose
```

Replace the example with a healthy writable DC in the workstation's domain. The reset cmdlet normally produces no output; verify success with the subsequent test. If this is a new PowerShell session, obtain `$domainCredential` again with `Get-Credential`.

## 5. Restart and Verify Domain Sign-In

1. After the secure channel tests successfully, save work and arrange a workstation restart. Confirm how the required corporate/VPN connectivity will be available for domain sign-in.
2. Restart the workstation in the agreed maintenance window.
3. Sign in with the intended domain account while DC connectivity is available. Cached sign-in by itself is not proof of restored domain communication.
4. Open elevated Windows PowerShell and repeat:

   ```powershell
   Test-ComputerSecureChannel -Verbose
   ```

5. Verify authorized access to a domain resource and record the result. Close the repair session when finished.

## Verification / Testing Checklist

- [ ] The target was an AD domain-joined workstation, not a domain controller or Entra-only device.
- [ ] DNS, DC discovery, and required network connectivity were confirmed.
- [ ] Repair completed and a fresh secure-channel test returned `True`.
- [ ] The workstation restarted and domain sign-in was tested with DC connectivity.
- [ ] An authorized domain resource is accessible.
- [ ] The ticket records the method, selected DC if specified, errors, and verification results without credentials.

## Troubleshooting

| Symptom | Check / next action |
|---|---|
| Domain controller cannot be found | Verify AD DNS, VPN routes, DC availability, and relevant firewall access. |
| Access denied | Confirm elevation on the workstation and delegated rights for the correct AD computer account. |
| Computer account missing or disabled | Investigate its AD state and the reason for the change before proceeding. |
| Repair fails against one DC | Check that DC's health and AD replication; use a known healthy writable DC only after investigating the difference. |
| Trust failure returns after repair | Investigate AD replication, duplicate computer names, cloning, or restores that may reintroduce a password mismatch. |
| Domain sign-in fails but the secure channel is healthy | Investigate the user account, credentials, time, network, and sign-in policy separately. |

---

## Sources

- Microsoft Learn: [Test-ComputerSecureChannel](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.management/test-computersecurechannel?view=powershell-5.1)
- Microsoft Learn: [Reset-ComputerMachinePassword](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.management/reset-computermachinepassword?view=powershell-5.1)
- Microsoft Learn: [Broken trust relationship between a domain-joined device and its domain](https://learn.microsoft.com/en-us/troubleshoot/windows-server/windows-security/broken-trust-relationship-domain-joined-device-its-domain-secure-channel-issues)
