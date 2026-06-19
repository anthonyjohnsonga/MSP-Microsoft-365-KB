# SSPR Deployment Guide — Cloud-Only & Hybrid (Entra Cloud Sync)

**Scope:** Covers enabling Self-Service Password Reset (SSPR) for cloud-only Entra ID tenants and hybrid tenants synced via **Microsoft Entra Cloud Sync** (lightweight provisioning agent — not classic Entra Connect Sync). Current as of June 2026, post legacy MFA/SSPR policy deprecation (Sept 30, 2025).

---

## 1. Licensing Prerequisites

| Capability | Required license |
|---|---|
| Cloud-only password change | Any tier (Entra ID Free included) |
| Cloud-only password reset | Microsoft 365 Business Standard, Business Premium, or Entra ID P1/P2 |
| Hybrid reset + writeback | Microsoft 365 Business Premium or Entra ID P1/P2 |

Cloud Sync password writeback specifically requires **Entra ID P1** (or trial) on the tenant.

---

## 2. Pre-Flight: Check the Tenant's Auth Methods Migration State

Before touching SSPR, check where the client tenant sits in the legacy → unified policy migration. This determines where you actually configure authentication methods.

1. Go to **Entra ID > Authentication methods > Policies**.
2. Click **Manage migration**.
3. Note the state:
   - **Pre-migration** — legacy MFA/SSPR policies still drive registration; Authentication methods policy used for auth only.
   - **Migration in Progress** — both legacy and unified policy settings are respected.
   - **Migration Complete** — only the unified Authentication methods policy applies; legacy settings ignored.

**MSP note:** Most client tenants you pick up cold will be in Pre-migration or Migration in Progress by default. Document this state per client — it changes which blade you actually need to edit, and settings are *not* synced between the legacy and unified policies, so a method left enabled in either one still works.

**Exception:** Security questions can currently only be managed in the legacy SSPR policy. Don't disable that policy if a client still uses them.

---

## 3. Phase 1 — Enable SSPR (applies to cloud-only AND hybrid)

### 3.1 Turn on SSPR
1. **Entra ID > Password reset > Properties**.
2. Set **Self service password reset enabled** to **Selected** (pilot group) or **All**.
3. **Save**.

Recommend starting with a pilot group (e.g., `SSPR-Test-Group`) before rolling to All — Entra only supports one group via the portal UI directly, but nested groups are supported if you need to combine populations.

### 3.2 Configure required authentication methods (unified policy — not legacy)
1. **Entra ID > Authentication methods > Policies**.
2. Enable the methods you want available for SSPR (Microsoft Authenticator, phone, email, etc.), scoped to **All users** or a target group.
3. Methods enabled here work for both sign-in and SSPR — note FIDO2/Windows Hello are sign-in-only, and security questions are SSPR-only (legacy policy, per Section 2).

### 3.3 Number of methods required + registration behavior
- The **Number of methods required to reset** control still lives under the legacy SSPR policy blade (**Password reset > Authentication methods**) even post-migration — this one setting wasn't moved yet. Set to **2**.
- **Password reset > Registration**: set **Require users to register when signing in** to **Yes**, and set reconfirmation interval (180 days is a reasonable default).

### 3.4 Notifications & branding
- **Password reset > Notifications**: enable user notification on reset, and admin notification when another admin resets their password.
- **Password reset > Customization**: set a custom helpdesk URL/email so users have somewhere to go if SSPR fails.

At this point, **cloud-only clients are done.** Skip to Section 5 (securing registration) and Section 6 (testing).

---

## 4. Phase 2 — Hybrid Clients: Enable Cloud Sync Password Writeback

Use this section only for clients syncing via **Entra Cloud Sync** (lightweight agent, not the full Entra Connect Sync client). Cloud Sync writeback can run side-by-side with Entra Connect if a client has both, scoped to different domains/users.

### 4.1 Prerequisites
- Entra ID P1 (or trial) on the tenant.
- Account with **Hybrid Identity Administrator** role.
- SSPR already enabled (Phase 1 complete).
- On-prem Cloud Sync agent at **version 1.1.977.0 or later**. Check the agent version before proceeding — older agents will silently fail writeback.

### 4.2 Confirm service account permissions
Permissions are configured by default for Cloud Sync. If writeback fails later, the group Managed Service Account needs:
- Reset password
- Write permissions on `lockoutTime`
- Write permissions on `pwdLastSet`
- Extended right for **Unexpire Password** on the root object of each domain in the forest (must apply to *this object and all descendant objects*, or it won't display correctly)

To reset permissions via PowerShell on the Cloud Sync agent server, using on-prem Enterprise Admin credentials:

```powershell
Import-Module 'C:\Program Files\Microsoft Azure AD Connect Provisioning Agent\Microsoft.CloudSync.Powershell.dll'
Set-AADCloudSyncPermissions -PermissionType PasswordWriteBack -EACredential $(Get-Credential)
```

Allow up to an hour for permission replication across all objects.

### 4.3 Enable writeback — Entra side (this step is required, not optional)

Cloud Sync being capable of writeback isn't the same as SSPR actually using it — you have to explicitly tell SSPR to use it on the Entra side. Two ways to do it; both land in the same place (verified current against Microsoft Learn, last reviewed June 2026):

**Admin Center method:**
1. **Entra ID > Password reset > On-premises integration**.
2. Check **Enable password write back for synced users**.
3. If a Cloud Sync provisioning agent is detected, also check **Write back passwords with Microsoft Entra Connect cloud sync** (you may also see this labeled **Microsoft Entra Cloud Sync** depending on portal version — same setting, just wording drift between doc revisions).
4. Set **Allow users to unlock accounts without resetting their password** to **Yes**.
5. **Save**.

**PowerShell method (run on the agent server):**

```powershell
Import-Module 'C:\Program Files\Microsoft Azure AD Connect Provisioning Agent\Microsoft.CloudSync.Powershell.dll'
Set-AADCloudSyncPasswordWritebackConfiguration -Enable $true -Credential $(Get-Credential)
```

**Troubleshooting — checkbox greyed out:** If "Write back passwords with Microsoft Entra Connect cloud sync" is greyed out with a "No agents have been detected" warning, that's almost always the agent itself — not a portal bug. Confirm the agent shows healthy under **Entra ID > Hybrid management > Cloud sync** before troubleshooting anything else.

### 4.4 On-prem GPO: Minimum password age
If you need to test resets more than once a day (or writeback intermittently fails for real users), set:
- `Computer Configuration > Policies > Windows Settings > Security Settings > Account Policies > Password Policy > Minimum password age` → **0 days**
- Run `gpupdate /force` on the DC, or wait for normal GPO replication.

If this is left above 0, writeback will fail once the on-prem policy evaluates the change as "too soon."

### 4.5 Know the writeback gaps (this catches people)

**Writeback works for:**
- End-user voluntary or forced (expired) password change
- End-user self-service reset from the sign-in page
- Admin-initiated reset from the **Entra admin center** or **Microsoft Graph API**

**Writeback does NOT happen for:**
- A user resetting their own password via PowerShell or Graph API directly
- An admin resetting a user's password via PowerShell cmdlets
- An admin resetting a user's password from the **Microsoft 365 admin center** (different surface than Entra admin center — easy to mix up)
- An admin resetting their own password (admin-on-admin SSPR/writeback isn't supported)

If a client's help desk habitually resets passwords from the M365 admin center instead of the Entra admin center, their on-prem password will silently drift out of sync with the cloud one. Worth flagging in onboarding.

---

## 5. Secure the Registration Process (both paths)

SSPR/MFA registration itself is a spray-attack target — don't deploy SSPR without this.

1. **Named location**: Entra ID > Security > Named locations > add the client's public office IP(s). Leave "trusted location" unchecked unless you have a specific reason to mark it trusted elsewhere.
2. **Conditional Access policy**:
   - Users: All users
   - Cloud apps or actions > User actions > **Register security information**
   - Conditions > Locations > Include: Any location; Exclude: the named location(s) above
   - Grant: **Block access**
   - Enable the policy
3. Combined (unified) registration experience has been on by default tenant-wide since Sept 2022 — no separate toggle needed.

**Known limitation:** a couple of practitioners have reported that the "I can't access my account" / forgot-password flow from the sign-in page can still allow SSPR to proceed even when this CA policy blocks the standard registration interrupt. Test this specifically against the client's tenant before treating registration as fully locked down. For tighter control, consider scoping an **Authentication Strength** requirement in addition to the location-based block, rather than relying on location exclusion alone.

---

## 6. Testing Checklist

- [ ] Confirm tenant licensing covers the SSPR tier you're deploying
- [ ] Register a non-admin pilot user at `aka.ms/ssprsetup`
- [ ] Reset that user's password at `aka.ms/sspr` (incognito/InPrivate window)
- [ ] For hybrid: confirm the new password authenticates on-prem (test against a DC-bound resource, not just cloud apps)
- [ ] Confirm reset/notification email fires
- [ ] From a non-trusted IP, confirm registration is blocked per the CA policy
- [ ] From a trusted IP, confirm registration proceeds normally
- [ ] If writeback: test via the Entra admin center reset path AND the end-user self-reset path — these are the two supported paths; don't assume M365 admin center behaves the same way

---

## 7. Sources

- Microsoft Learn: [Plan a Microsoft Entra SSPR deployment](https://learn.microsoft.com/en-us/entra/identity/authentication/concept-sspr-deploy)
- Microsoft Learn: [Tutorial: Enable Microsoft Entra SSPR](https://learn.microsoft.com/en-us/entra/identity/authentication/tutorial-enable-sspr)
- Microsoft Learn: [Manage authentication methods for Microsoft Entra ID](https://learn.microsoft.com/en-us/entra/identity/authentication/concept-authentication-methods-manage)
- Microsoft Learn: [Enable Microsoft Entra Connect cloud sync password writeback](https://learn.microsoft.com/en-us/entra/identity/authentication/tutorial-enable-cloud-sync-sspr-writeback)
- Microsoft Learn: [SSPR writeback concepts](https://learn.microsoft.com/en-us/entra/identity/authentication/concept-sspr-writeback)
- Ali Tajran (Microsoft MVP): [Enable Microsoft Entra SSPR](https://www.alitajran.com/self-service-password-reset/)
- Ali Tajran (Microsoft MVP): [Secure MFA and SSPR registration with Conditional Access](https://www.alitajran.com/secure-mfa-and-sspr-registration/)
