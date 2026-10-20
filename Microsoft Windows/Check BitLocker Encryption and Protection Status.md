# Check BitLocker Encryption and Protection Status

**Applies to:** Windows 11; Windows 10 under an applicable support arrangement; BitLocker and Windows device encryption<br>
**Scope:** Inspect local volume encryption and protection status with manage-bde; does not change encryption or key protectors<br>
**Last Updated:** October 2026

---

## Overview

Open **Command Prompt > Run as administrator** and run `manage-bde -status` to inspect local drives. Check both encryption progress and protection state: an encrypted volume can have protection suspended or otherwise off.

This is a local status check, not proof that recovery information is backed up or that the device meets every customer compliance requirement.

## Prerequisites

| Requirement | Detail |
|---|---|
| Permissions | An elevated Command Prompt on the endpoint being inspected. |
| Windows components | The built-in `manage-bde` tool must be available. No PowerShell module is required. |
| Licensing | No additional Microsoft 365 license is needed for this check. BitLocker enablement and centralized management have their own edition and licensing requirements; device encryption is also available on eligible devices. |
| Expected state | Know which volumes the customer requires encrypted and protected, and the expected encryption method. |

**MSP note:** Confirm the customer's endpoint and compare each required volume with its policy. Record status in the customer's ticket without publishing device identifiers or recovery secrets.

---

## 1. Check All Local Drives

1. Open **Start**, search for **Command Prompt**, and select **Run as administrator**.
2. Run:

   ```cmd
   manage-bde -status
   ```

3. Locate the operating system volume and any required data volumes. Read each volume separately rather than assuming the state of one drive applies to the others.

## 2. Check a Specific Drive

For the typical Windows volume:

```cmd
manage-bde -status C:
```

Replace `C:` with the actual target drive letter, such as `D:` for a data volume.

## 3. Interpret the Result

| Field | Interpretation |
|---|---|
| Conversion Status | Indicates whether encryption/decryption is complete, running, or paused. Used-space-only encryption can be a completed state. |
| Percentage Encrypted | Shows conversion progress; assess it alongside conversion and protection status. `100%` alone does not establish active protection. |
| Protection Status | **Protection On** indicates protection is active. **Protection Off** needs investigation even when the volume is encrypted, such as checking for an approved suspension or incomplete provisioning. |
| Lock Status | **Unlocked** means Windows can currently access the volume. An unlocked operating system volume during a running session does not mean its data is unencrypted. |
| Encryption Method | Compare the reported method with the customer's required cipher and policy. |
| Key Protectors | Shows configured protector types. Their presence does not prove recovery information is backed up or retrievable. |

For a volume expected to be protected, confirm completed encryption and **Protection On**, then compare the remaining fields with policy. If encryption is still running, recheck later and record progress. Output labels vary by Windows language.

## Verification / Testing Checklist

- [ ] The correct endpoint and drive letters were inspected from an elevated session.
- [ ] Every required volume was reviewed independently.
- [ ] Conversion progress, protection state, and encryption method were compared with customer requirements.
- [ ] Any unexpected state was recorded and referred to the appropriate encryption-management process.
- [ ] Recovery-key backup was verified separately where required; local status alone was not accepted as evidence of escrow.

## Troubleshooting

| Symptom | Check / next action |
|---|---|
| Access denied | Confirm Command Prompt is running as administrator. |
| manage-bde is unavailable | Confirm the Windows edition, installed components, and execution environment before selecting another inspection method. |
| Drive not found | Verify the actual drive letter and whether the volume is attached and visible. |
| Encrypted but Protection Off | Check approved maintenance suspension, provisioning state, and effective policy before making changes. |
| Conversion is paused or incomplete | Review power state, maintenance activity, and the managing system's errors; capture progress before troubleshooting. |
| Local result differs from Intune/RMM | Confirm device identity and reporting timestamps. Compare fresh local output with the management system's latest check-in. |

The commands in this guide only inspect status, so no configuration rollback is required. Encryption, suspension, decryption, and protector changes should follow a separate approved procedure.

---

## Sources

- Microsoft Learn: [manage-bde status](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/manage-bde-status)
- Microsoft Learn: [BitLocker overview, licensing, and device encryption](https://learn.microsoft.com/en-us/windows/security/operating-system-security/data-protection/bitlocker/)
