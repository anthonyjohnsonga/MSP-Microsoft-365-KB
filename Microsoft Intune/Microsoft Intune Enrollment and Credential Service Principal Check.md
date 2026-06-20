## Entra ID Service Principal Check — Microsoft Intune Enrollment & Azure Credential Configuration Endpoint Service

> Reference for confirming whether these two Microsoft first-party service principals exist in a tenant, what each one does, and how to create them if missing. Both are commonly absent from tenants by default and only matter once you need to reference them in a Conditional Access policy.

---

### Quick Reference

| App ID | Display Name | Purpose |
|---|---|---|
| `d4ebce55-015a-49b5-a083-c84d1797ae8c` | Microsoft Intune Enrollment | Handles device enrollment flows (MDM enrollment, Autopilot, hybrid join, PRT acquisition) |
| `ea890292-c8c8-4433-b5ea-b09d0668e1a6` | Azure Credential Configuration Endpoint Service | Internal Azure service for credential/configuration endpoint operations; relevant when Passkeys are blocked from registration |

---

### What Each App Does

#### Microsoft Intune Enrollment (`d4ebce55-015a-49b5-a083-c84d1797ae8c`)

Documented by Microsoft. This is the resource Conditional Access policies target when you need to apply controls specifically to the device enrollment flow — separately from the main "Microsoft Intune" app.

- **Microsoft Intune** (app) — MFA prompt surfaces on Setup Assistant *and* every Company Portal sign-in.
- **Microsoft Intune Enrollment** (this app) — MFA prompt surfaces once, at Setup Assistant, as a one-time check during enrollment.

> Microsoft's own documentation states this service principal is **not created automatically for new tenants**. It has to be created manually before it will appear in the Conditional Access app picker.

Typical reason an MSP needs this app registered: excluding it (and the main Intune app) from a broad "All cloud apps — require MFA" Conditional Access policy, so background enrollment and Primary Refresh Token (PRT) acquisition don't break. Without the exclusion, Autopilot and hybrid join enrollments can fail because the device can't satisfy an MFA challenge during the unattended provisioning step.

> Current Microsoft guidance (CIS Microsoft 365 Foundations Benchmark, updated guidance circulating as of 2026) trends toward *not* broadly excluding this app and instead applying sign-in frequency controls to it specifically — full exclusion isn't universally "best practice" anymore. Treat the exclusion as a targeted fix for enrollment failures, not a default.

#### Azure Credential Configuration Endpoint Service (`ea890292-c8c8-4433-b5ea-b09d0668e1a6`)

**Not officially documented by Microsoft.** There is no Microsoft Learn article describing this service principal's function. What's known comes from community research (most notably Nathan McNulty's testing, published 2025):

- Believed to be responsible for registering security info gathered by apps like Microsoft Authenticator and the My Sign-ins portal against a user account.
- Becomes operationally relevant during **passkey (FIDO2) registration**. If passkey registration is being blocked — commonly by a Conditional Access policy enforcing Authentication Strength or device compliance on security info registration — excluding this specific service principal from that policy has been found to allow passkey registration to succeed even with Authenticator app protection policy (APP) enforcement still in place.
- Because there's no official documentation, the downstream effects of excluding it from a CA policy aren't fully known. Community guidance recommends scoping any exclusion to a pilot security group rather than applying tenant-wide, and duplicating the existing CA policy rather than editing it in place.

> Treat anything about this app as best-effort community knowledge, not confirmed Microsoft behavior. Flag this caveat in client-facing material if this app comes up in passkey rollout work.

---

### Prerequisites

- Microsoft Graph PowerShell SDK — specifically the `Microsoft.Graph.Authentication` and `Microsoft.Graph.Applications` modules.
- An account with at least **Global Reader** for checking, or **Application Administrator** / **Cloud Application Administrator** for creating.
- Delegated Graph permission scope: `Application.Read.All` (checking) or `Application.ReadWrite.All` (creating).

> If you've hit module-loading errors (assembly version conflicts, "could not find file" errors referencing an old module version path), that's almost always caused by multiple SDK versions stacked in a OneDrive-synced PowerShell module folder, or a stale PowerShell module analysis cache. Reinstalling to `C:\Program Files\PowerShell\Modules` with `-Scope AllUsers` and excluding OneDrive from `$env:PSModulePath` resolves it. Not covered in depth here — flag if you want this written up separately as its own troubleshooting note.

---

### Step 1 — Connect to Graph

```powershell
Import-Module Microsoft.Graph.Authentication
Import-Module Microsoft.Graph.Applications
Connect-MgGraph -Scopes "Application.Read.All"
```

---

### Step 2 — Check Both Service Principals

```powershell
$appsToCheck = @(
    @{ AppId = "d4ebce55-015a-49b5-a083-c84d1797ae8c"; Name = "Microsoft Intune Enrollment" }
    @{ AppId = "ea890292-c8c8-4433-b5ea-b09d0668e1a6"; Name = "Azure Credential Configuration Endpoint Service" }
)

foreach ($app in $appsToCheck) {
    $sp = Get-MgServicePrincipal -Filter "appId eq '$($app.AppId)'"
    if ($sp) {
        Write-Host "$($app.Name) — EXISTS (Object ID: $($sp.Id))" -ForegroundColor Green
    } else {
        Write-Host "$($app.Name) — NOT FOUND" -ForegroundColor Yellow
    }
}
```

**Equivalent direct Graph REST query** (e.g. via Graph Explorer, or `Invoke-MgGraphRequest`):

```
GET https://graph.microsoft.com/v1.0/servicePrincipals?$filter=appId eq 'd4ebce55-015a-49b5-a083-c84d1797ae8c' or appId eq 'ea890292-c8c8-4433-b5ea-b09d0668e1a6'
```

An empty `value: []` array means neither is registered. A populated array tells you which one(s) already exist.

**Manual check (Entra admin center):**

**Identity → Applications → Enterprise applications** → search box → paste the App ID. If nothing returns, it isn't registered.

---

### Step 3 — Create Whichever One Is Missing

Requires `Application.ReadWrite.All` and re-running `Connect-MgGraph` with that scope (or `Application Administrator` / `Cloud Application Administrator` role).

```powershell
Connect-MgGraph -Scopes "Application.ReadWrite.All"

# Microsoft Intune Enrollment
New-MgServicePrincipal -AppId "d4ebce55-015a-49b5-a083-c84d1797ae8c"

# Azure Credential Configuration Endpoint Service
New-MgServicePrincipal -AppId "ea890292-c8c8-4433-b5ea-b09d0668e1a6"
```

Only run the line for the app that returned **NOT FOUND** in Step 2 — there's no need to recreate one that already exists.

**Equivalent Graph REST (POST):**

```
POST https://graph.microsoft.com/v1.0/servicePrincipals
Content-Type: application/json

{
  "appId": "d4ebce55-015a-49b5-a083-c84d1797ae8c"
}
```

---

### Step 4 — Re-Verify

Re-run the Step 2 loop. Both should now report **EXISTS**, and the apps will be selectable in the Conditional Access "Resources" / "Cloud apps" picker within a few minutes.

---

### Notes for Conditional Access Work

- Don't exclude **Microsoft Intune Enrollment** from MFA tenant-wide as a default move — scope it to the specific failure you're solving (enrollment/PRT acquisition breaking under a broad MFA policy), and consider sign-in frequency controls as an alternative to full exclusion per current CIS guidance.
- For **Azure Credential Configuration Endpoint Service**, pilot any exclusion with a dedicated security group and a duplicated CA policy rather than editing a production policy directly — the lack of official documentation means the blast radius of excluding it isn't fully mapped.
