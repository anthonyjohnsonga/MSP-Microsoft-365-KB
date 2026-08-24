# Microsoft 365 Apps

MSP technician reference documentation for the Microsoft 365 Apps desktop clients (Word, Excel, PowerPoint, Outlook) on Windows and macOS — activation, licensing state, and client-side identity caching.

---

### [Microsoft 365 Apps for Mac — Stale Tenant Activation Fix](./Microsoft%20365%20Apps%20for%20Mac%20Stale%20Tenant%20Activation%20Fix.md)

Word/Excel/PowerPoint stuck in "Ready to View Documents" view-only mode on a Mac after a tenant-to-tenant migration or UPN change, while the license is correctly assigned and sign-in succeeds. Covers confirming the diagnosis with `defaults read` against `OfficeActivationEmailAddress` and `TenantIDKey`, the surgical vs. nuke-the-plist cleanup of `com.microsoft.office`, stale ADAL identity blocks, the `killall cfprefsd` flush, verifying via `licensingV2.plist`, the keychain and license-file escalation path, the Windows registry equivalent with `vnextdiag.ps1`, and the MDM-reapplies-the-stale-value gotcha. Includes the key diagnostic insight — successful auth with no license files written means the client is querying the wrong tenant — and the post-migration sweep to catch other affected machines before they generate tickets.

## Topics Covered

- Office for Mac activation and view-only / reduced functionality mode
- Stale tenant pointers surviving an Office uninstall/reinstall
- `com.microsoft.office` preferences domain and ADAL identity caching
- Office keychain entries and `licensingV2.plist`
- Windows `HKCU\...\Office\16.0\Common\Identity` equivalent
- Post-tenant-migration client remediation
