# PowerShell 7

This folder contains helpdesk technician reference guides for installing and configuring PowerShell 7 in a Microsoft 365 environment.

---

### [PnP PowerShell — Entra ID App Registration and Interactive Connection](./PnP%20PowerShell%20Entra%20ID%20App%20Registration%20and%20Connection.md)

Setup guide for the per-tenant Entra ID app registration that PnP PowerShell has required since the shared "PnP Management Shell" app was retired on 9 September 2024. Covers installing `PnP.PowerShell` on PowerShell 7.4+, running `Register-PnPEntraIDAppForInteractiveLogin` (parameters, the four default delegated permissions, admin consent, and how to request a narrower least-privilege set), the `-DeviceLogin` variant for browser-less hosts, and connecting with `Connect-PnPOnline -Interactive -ClientId`. Includes the `ENTRAID_CLIENT_ID` environment variable shortcut and why it's a trap in multi-tenant MSP work, a verification checklist, and a troubleshooting table covering `AADSTS700016`, `AADSTS65001` consent failures, redirect URI mismatches, and PowerShell 5.1 incompatibility.

---

### [Installing PowerShell 7](./Installing%20PowerShell%207.md)

A step-by-step installation guide for PowerShell 7 on both Windows and macOS, written for helpdesk technicians. Covers installing PowerShell 7 on Windows using winget, installing on macOS using Homebrew (including Apple Silicon PATH setup), verifying the installation with `$PSVersionTable`, and installing and connecting the Exchange Online PowerShell module (`ExchangeOnlineManagement`). Also includes a troubleshooting section addressing common issues such as winget not being recognized, UAC prompt failures, Homebrew install errors, and PSGallery trust and permission errors when running `Connect-ExchangeOnline`.
