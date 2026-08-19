# PnP PowerShell — Entra ID App Registration and Interactive Connection

**Applies to:** PnP.PowerShell 3.x on PowerShell 7.4+; any Microsoft 365 tenant with SharePoint Online  
**Scope:** Registering the per-tenant Entra ID app that PnP PowerShell now requires, and connecting interactively with it. Certificate/app-only (unattended) authentication is out of scope.  
**Last Updated:** August 2026

---

## Overview

PnP PowerShell used to ship with a shared multi-tenant "PnP Management Shell" app registration, so `Connect-PnPOnline -Url ... -Interactive` worked with no setup. That app was retired on **9 September 2024**. Every tenant now needs its own Entra ID app registration, and `Connect-PnPOnline` needs its client ID.

This is a two-command job, run once per tenant:

```powershell
Register-PnPEntraIDAppForInteractiveLogin `
  -ApplicationName "PnP PowerShell - Name" `
  -Tenant Tenant_Name

Connect-PnPOnline -Url "SharePoint Site URL" `
  -Interactive -ClientId "ClientIDNumber"
```

The first command creates the app and returns a client ID. The second uses that client ID from then on — you never run the registration again for that tenant.

---

## Prerequisites

| Requirement | Detail |
|---|---|
| PowerShell | **7.4.0 or later.** PnP.PowerShell 3.x will not load in Windows PowerShell 5.1. See [Installing PowerShell 7](./Installing%20PowerShell%207.md) |
| Module | `PnP.PowerShell` — `Install-Module PnP.PowerShell -Scope CurrentUser` |
| Role to create the app | **Application Developer** (minimum) or Global Administrator |
| Role to consent | **Global Administrator** — the default permission set is admin-consent-only |
| Role to use it | **SharePoint Administrator** for tenant/site admin work; site permissions are still enforced per-site |
| Tenant identifier | The `.onmicrosoft.com` domain, e.g. `contoso.onmicrosoft.com` |

---

## 1. Install the module

```powershell
Install-Module PnP.PowerShell -Scope CurrentUser
```

Nightly/prerelease builds:

```powershell
Install-Module PnP.PowerShell -AllowPrerelease -Scope CurrentUser
```

Confirm you're on PowerShell 7 before you start — this must report `Core` and `7.4.x` or higher:

```powershell
$PSVersionTable
```

---

## 2. Register the Entra ID app

Run this **once per tenant**, signed in as an account with the roles above.

```powershell
Register-PnPEntraIDAppForInteractiveLogin `
  -ApplicationName "PnP PowerShell - Contoso" `
  -Tenant contoso.onmicrosoft.com
```

| Parameter | Value to supply |
|---|---|
| `-ApplicationName` | The display name of the app registration in Entra ID. Free text — pick something that identifies who created it and why (see the MSP note below) |
| `-Tenant` | The tenant's `.onmicrosoft.com` domain, **not** a GUID and **not** the vanity domain |

**What happens:**

1. The app registration is created as a **public client** with a `http://localhost` redirect URI.
2. The cmdlet pauses (roughly 60 seconds) to let the registration replicate through Entra ID.
3. A browser window opens asking you to consent to the requested permissions. Approve it, or have a Global Admin grant consent later under **Entra admin center > Applications > App registrations > *your app* > API permissions > Grant admin consent**.
4. The cmdlet returns the **client ID (application ID)**. Save it — this is the `-ClientId` you will pass to every future `Connect-PnPOnline`.

**Default permissions granted** (all *delegated* — the app acts as the signed-in user, never above them):

- `AllSites.FullControl` (SharePoint)
- `Group.ReadWrite.All` (Graph)
- `User.ReadWrite.All` (Graph)
- `TermStore.ReadWrite.All` (Graph)

**MSP note:** These defaults are broad. They're delegated, so the app can never do more than the operator's own account, but the consent prompt a client sees will read as extensive. Naming the app `PnP PowerShell - <YourMSP>` makes it obvious in the client's Entra tenant who owns it and stops it looking like an unexplained third-party app during a security review.

### Requesting a narrower permission set

Specify permissions explicitly to keep the consent screen minimal. A read-only reporting app:

```powershell
Register-PnPEntraIDAppForInteractiveLogin `
  -ApplicationName "PnP PowerShell - Contoso (Read Only)" `
  -Tenant contoso.onmicrosoft.com `
  -SharePointDelegatePermissions AllSites.Read `
  -GraphDelegatePermissions User.Read.All
```

Available permission switches: `-SharePointDelegatePermissions`, `-SharePointApplicationPermissions`, `-GraphDelegatePermissions`, `-GraphApplicationPermissions`, `-O365ManagementDelegatePermissions`, `-O365ManagementApplicationPermissions`.

Specifying *any* of these replaces the defaults entirely — list everything you need.

### If a browser isn't available

On a server core install, an SSH session, or anywhere a browser can't launch, add `-DeviceLogin` to authenticate with a device code on another machine:

```powershell
Register-PnPEntraIDAppForInteractiveLogin `
  -ApplicationName "PnP PowerShell - Contoso" `
  -Tenant contoso.onmicrosoft.com `
  -DeviceLogin
```

---

## 3. Connect

Use the client ID returned in step 2:

```powershell
Connect-PnPOnline `
  -Url "https://contoso.sharepoint.com/sites/Finance" `
  -Interactive `
  -ClientId "00000000-1111-2222-3333-444444444444"
```

`-Url` can be any site collection. For tenant-level cmdlets (`Get-PnPTenantSite`, `Set-PnPTenantSite`, etc.) connect to the **admin** site:

```powershell
Connect-PnPOnline `
  -Url "https://contoso-admin.sharepoint.com" `
  -Interactive `
  -ClientId "00000000-1111-2222-3333-444444444444"
```

`-ClientId` has been effectively mandatory since 9 September 2024. Omitting it fails.

### Avoiding the ClientId on every command

Set an environment variable and PnP will pick it up automatically. Use either `ENTRAID_APP_ID` or `ENTRAID_CLIENT_ID`:

```powershell
# Current session only
$env:ENTRAID_CLIENT_ID = "00000000-1111-2222-3333-444444444444"

# Persist for the current user
[Environment]::SetEnvironmentVariable("ENTRAID_CLIENT_ID", "00000000-1111-2222-3333-444444444444", "User")
```

Then `Connect-PnPOnline -Url "https://contoso.sharepoint.com" -Interactive` works on its own.

**MSP note:** Don't set this machine-wide if you work across multiple client tenants — you'll silently connect with the wrong tenant's client ID and get an `AADSTS700016` that looks like a broken app registration. Keep a per-client record of client IDs (PSA/documentation tool) and pass `-ClientId` explicitly instead.

---

## Verification / Testing Checklist

- [ ] `$PSVersionTable` shows PSEdition `Core`, PSVersion 7.4 or higher
- [ ] `Get-Module PnP.PowerShell -ListAvailable` returns a 3.x version
- [ ] The app appears under **Entra admin center > Applications > App registrations** with the name you gave it
- [ ] **API permissions** shows green "Granted for \<tenant\>" against each permission
- [ ] **Authentication** shows a `http://localhost` redirect URI under *Mobile and desktop applications*
- [ ] `Connect-PnPOnline` completes with no error and `Get-PnPContext` returns a context
- [ ] `Get-PnPWeb` returns the expected site title
- [ ] The client ID is recorded in client documentation

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `The term 'Register-PnPEntraIDAppForInteractiveLogin' is not recognized` | Old PnP module — the cmdlet was `Register-PnPAzureADApp` in 1.x | `Update-Module PnP.PowerShell`, or uninstall and reinstall the current release |
| Module installs but no cmdlets work | Running in Windows PowerShell 5.1 | Launch `pwsh` (PowerShell 7.4+). PnP.PowerShell 3.x does not support 5.1 |
| `AADSTS700016: Application with identifier '...' was not found` | Client ID belongs to a different tenant, or the app hasn't replicated yet | Confirm the client ID matches the tenant in `-Url`. If the registration just ran, wait a few minutes and retry |
| `AADSTS65001: The user or administrator has not consented` | Consent was skipped or declined during registration | Grant admin consent: **Entra > App registrations > *app* > API permissions > Grant admin consent** |
| `AADSTS50011: The redirect URI ... does not match` | App was hand-built in the portal without the public-client redirect | Add `http://localhost` under **Authentication > Add a platform > Mobile and desktop applications**, and enable *Allow public client flows* |
| Registration fails with insufficient privileges | Account lacks Application Developer / Global Administrator | Re-run as an eligible account, or activate the PIM role first |
| `Connect-PnPOnline` errors asking for a ClientId | `-ClientId` omitted and no env var set | Pass `-ClientId`, or set `ENTRAID_CLIENT_ID` |
| Connects fine but `Get-PnPTenantSite` fails | Connected to a site collection, not the admin site | Reconnect to `https://<tenant>-admin.sharepoint.com` |
| Access denied on a site despite `AllSites.FullControl` | Delegated permissions never exceed the signed-in user's own rights | Add the operator to the site's Site Collection Administrators, or sign in with an account that has access |

---

## Sources

- PnP PowerShell: [Register-PnPEntraIDAppForInteractiveLogin](https://pnp.github.io/powershell/cmdlets/Register-PnPEntraIDAppForInteractiveLogin.html)
- PnP PowerShell: [Connect-PnPOnline](https://pnp.github.io/powershell/cmdlets/Connect-PnPOnline.html)
- PnP PowerShell: [Register an Entra ID Application](https://pnp.github.io/powershell/articles/registerapplication.html)
- PnP PowerShell: [Installation](https://pnp.github.io/powershell/articles/installation.html)
- Microsoft Learn: [Quickstart: Register an application with the Microsoft identity platform](https://learn.microsoft.com/en-us/entra/identity-platform/quickstart-register-app)
