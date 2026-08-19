# MSP Microsoft 365 Knowledge Base

[![Articles](https://img.shields.io/badge/articles-29-0078D4?style=flat-square)](#-article-index)
[![Product Areas](https://img.shields.io/badge/product%20areas-12-5B2D90?style=flat-square)](#-article-index)
[![Last Commit](https://img.shields.io/github/last-commit/anthonyjohnsonga/MSP-Microsoft-365-KB?style=flat-square&color=00A4EF)](https://github.com/anthonyjohnsonga/MSP-Microsoft-365-KB/commits/main)
[![License: MIT](https://img.shields.io/github/license/anthonyjohnsonga/MSP-Microsoft-365-KB?style=flat-square&color=green)](./LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen?style=flat-square)](./CONTRIBUTING.md)

> *In the beginning, there was a ticket.*
>
> A user could not send email. The helpdesk technician searched, and found nothing written down. So they searched again — this time through memory, through tribal knowledge whispered across Teams chats and half-remembered Teams calls. Eventually, they found the answer. They fixed the ticket. And then... they moved on.
>
> The knowledge dissolved back into the void.
>
> The philosophers asked: *if a solution is found and never written down, did it ever really exist?*
>
> This repository is a refusal to let knowledge die with the ticket.
>
> Every guide here was born from a real problem — a gap between what Microsoft documents and what actually happens at 8am when a client can't attach files in Teams. The goal is simple: the next person who hits that wall shouldn't have to rebuild the answer from scratch.
>
> Knowledge hoarded is knowledge that decays. Knowledge shared compounds.
>
> This is a living document. If you use something here and find it wrong, fix it. If you solve something not covered here, add it. The value of a knowledge base is not in who writes it — it's in whether the next person finds what they need.
>
> *The ticket will always come back. Be ready.*

---

## 📚 Article Index

Every guide and script in the KB. Use <kbd>Ctrl</kbd>+<kbd>F</kbd> on the tags to jump to a topic.

| Area | Guide | What it covers | Tags |
|---|---|---|---|
| **Business Premium** | [Why Microsoft Business Premium](./Microsoft%20Business%20Premium/Why%20Microsoft%20Business%20Premium.pdf) | Sales/justification document making the case for the Business Premium suite | `business-premium` `licensing` `sales` |
| **Copilot** | [Controlling Copilot Access to SharePoint Content](./Microsoft%20Copilot/Microsoft%20Copilot%20SharePoint%20Grounding%20Control%20Guide.md) | Restricted Content Discovery end to end: what RCD does and doesn't block, the four gaps to disclose, the SAM licensing gate (one *assigned* Copilot seat), site classification, CSV-driven apply with a log, validation, and rollback | `copilot` `sharepoint` `restricted-content-discovery` `sam` `governance` `powershell` |
| **Defender** | [Display Name Spoofing Guide](./Microsoft%20Defender/Microsoft%20365%20Display%20Name%20Spoofing%20Guide.md) | Layered defense against external senders impersonating staff: DNS auth, anti-spoofing policies, external-sender tagging, user training | `defender` `email-security` `anti-phishing` `spoofing` |
| **Defender** | [DMARC Rollout Guide](./Microsoft%20Defender/Microsoft%20365%20DMARC%20Rollout%20Guide.md) | Phased move from `p=none` to `p=reject` using `pct=` staging: alignment fixes, exit criteria per phase, subdomain strategy, change control, and rollback | `defender` `email-security` `dmarc` `spf` `dkim` `email-authentication` |
| **Defender** | [SmartScreen & Network Protection](./Microsoft%20Defender/Microsoft%20Defender%20Smartscreen%20Network%20Protection.md) | SmartScreen vs Network Protection coverage, browser gaps, and the 3 Intune policies (EDR onboarding, ASR, web content filtering) | `defender` `mde` `network-protection` `smartscreen` `intune` |
| **Entra** | [Conditional Access Groups](./Microsoft%20Entra/Conditional%20Access%20Groups.md) | The four core CA security groups (Staff, Guest, Break Glass, Admins) with dynamic/assigned membership rules | `entra` `conditional-access` `groups` `identity` |
| **Entra** | [Device Tenant-to-Tenant Migration Runbook](./Microsoft%20Entra/Microsoft%20Entra%20Device%20Tenant%20Migration%20Runbook.md) | Move an Entra-joined Windows device between tenants: source Retire/cleanup, `dsregcmd /leave` + verify, destination join/enroll, Autopilot dereg, profile/OneDrive, and the hybrid safeguard | `entra` `intune` `device-management` `tenant-migration` `dsregcmd` `autopilot` |
| **Entra** | [SSPR Deployment Guide](./Microsoft%20Entra/Microsoft%20SSPR%20Deployment%20Guide.md) | Self-Service Password Reset for cloud-only and hybrid (Entra Cloud Sync) tenants, incl. writeback, registration hardening, and testing | `entra` `sspr` `identity` `hybrid` `cloud-sync` |
| **Entra** | [Guest User Access Authorization Policy](./Microsoft%20Entra/Set%20Authorization%20Policy%20for%20Guest%20User%20Access.md) | Set the tenant-wide guest access level (User / Guest / Restricted) via portal or Graph PATCH, with GUIDs and required roles | `entra` `guest-access` `external-identities` `graph` |
| **Entra** | [Passkey (FIDO2) Policy & Registration Campaign](./Microsoft%20Entra/Microsoft%20Entra%20-%20Passkey%20(FIDO2)%20Policy%20and%20Registration%20Campaign.md) | Configure passkey profiles (device-bound vs. synced, attestation, AAGUID), the hardened admin profile pattern, and the registration campaign; portal + Graph, Microsoft-managed gotchas, and CA enforcement | `entra` `authentication` `passkey` `fido2` `passwordless` `phishing-resistant-mfa` |
| **Exchange Online** | [Mailbox Archiving](./Microsoft%20Exchange%20Online/Microsoft%20Exchange%20Online%20Mailbox%20Archiving.md) | Online vs auto-expanding archive, enabling by license tier, MRM retention tags, holds, Graph, and troubleshooting | `exchange` `archiving` `retention` `compliance` |
| **Exchange Online** | [Exchange Online Guide](./Microsoft%20Exchange%20Online/Microsoft%20Exchange%20Online%20Guide.md) | Comprehensive helpdesk reference: user/shared/resource mailboxes, groups, mail flow, NDR codes, permissions, PowerShell | `exchange` `mailboxes` `mail-flow` `powershell` `helpdesk` |
| **Exchange Online** | [Email Encryption Setup Guide](./Microsoft%20Exchange%20Online/Microsoft%20Exchange%20Online%20Email%20Encryption%20Setup%20Guide.md) | Purview Message Encryption end to end: `AIPService` setup, Azure RMS activation, IRM config, the "failed to acquire RMS templates" `LicensingLocation` fix, and testing | `exchange` `purview` `encryption` `irm` `azure-rms` `powershell` |
| **Graph Scripts** | [MicrosoftGraph.ps1](./Microsoft%20Graph%20API%20Scripts/MicrosoftGraph.ps1) | Installs `Microsoft.Graph.Authentication` and connects with a broad set of admin scopes | `graph` `powershell` `authentication` |
| **Graph Scripts** | [mg-assign-role.ps1](./Microsoft%20Graph%20API%20Scripts/mg-assign-role.ps1) | Assigns an Entra ID role to a user via the Graph beta endpoint | `graph` `powershell` `entra` `roles` |
| **Graph Scripts** | [mg-create-user.ps1](./Microsoft%20Graph%20API%20Scripts/mg-create-user.ps1) | Creates a new Entra ID user via the Graph beta endpoint | `graph` `powershell` `entra` `user-provisioning` |
| **Intune** | [Disable Chrome Password Manager](./Microsoft%20Intune/Microsoft%20Intune%20Google%20Chrome%20Disable%20Password%20Manager.md) | Settings Catalog policy to disable Chrome's built-in password manager (`PasswordManagerEnabled`) | `intune` `chrome` `settings-catalog` `policy` |
| **Intune** | [Properties Catalog](./Microsoft%20Intune/Microsoft%20Intune%20Properties%20Catalog.md) | WMI-based device inventory via Properties Catalog: Resource Explorer, Graph beta, MSP use cases, error 2147749902 | `intune` `inventory` `device-management` `graph` |
| **Intune** | [Windows 11 Hotpatch Notes](./Microsoft%20Intune/Microsoft%20Windows%2011%20Hotpatch%20Notes.md) | Rebootless quality updates for Win11 24H2+: baseline/hotpatch schedule, VBS/HVCI prerequisites, the two Intune policies | `intune` `windows-11` `hotpatch` `updates` |
| **Intune** | [Enrollment & Credential Service Principal Check](./Microsoft%20Intune/Microsoft%20Intune%20Enrollment%20and%20Credential%20Service%20Principal%20Check.md) | Check/create the Intune Enrollment & Azure Credential Config Endpoint service principals via Graph PowerShell; CA exclusion guidance for enrollment/PRT and passkey registration | `intune` `entra` `conditional-access` `service-principal` `graph` `enrollment` |
| **Intune** | [Sysprep for Autopilot Single-Machine Deployment](./Microsoft%20Intune/Microsoft%20Intune%20Sysprep%20for%20Autopilot%20Single-Machine%20Deployment.md) | Bench-to-ship workflow for one machine: `/oobe` vs `/generalize`, Audit mode, hash capture, profile assignment checks, BitLocker key escrow, and the `/generalize`-only error catalogue | `intune` `autopilot` `sysprep` `deployment` `bitlocker` `windows-11` |
| **OneDrive** | [Sync Troubleshooting](./Microsoft%20OneDrive/Microsoft%20OneDrive%20Sync%20Troubleshooting.md) | Resolve sync failures, missing icons, and SharePoint sync/shortcut issues: Quick Fix, Full Fix, and file-recovery workflow | `onedrive` `sharepoint` `sync` `troubleshooting` |
| **OneDrive** | [Over-Quota Report Guide](./Microsoft%20OneDrive/Microsoft%20OneDrive%20Over-Quota%20Report%20Guide.md) | PnP `Get-ODBOverQuotaUsers.ps1` quick guide: scopes, usage, CSV columns, quota tiers, and MSP/GDAP gotchas | `onedrive` `storage-quota` `powershell` `graph` `reporting` |
| **Purview** | [DLP External Sharing Alert](./Microsoft%20Purview/Microsoft%20Purview%20DLP%20External%20Sharing%20Alert%20Policy%20Creation.md) | Monitor-only DLP policy that alerts admins on any external SharePoint/OneDrive share; simulation mode, full wizard walkthrough, and a known-errors table | `purview` `dlp` `sharepoint` `onedrive` `external-sharing` `compliance` |
| **Teams** | [External File Sharing (CsTeamsFilesPolicy)](./Microsoft%20Teams/Teams%20-%20External%20File%20Sharing%20via%20CsTeamsFilesPolicy.md) | Enable file attachments in external chats via `CsTeamsFilesPolicy` (PowerShell only) plus SharePoint external sharing | `teams` `external-sharing` `powershell` `policy` |
| **Windows Server** | [Active Directory FSMO Recovery Guide](./Windows%20Server/Active%20Directory/Active%20Directory%20FSMO%20Recovery%20Guide.md) | Recovering a domain when the FSMO role holder is permanently lost with no backup: seizing all five roles, metadata cleanup, `_msdcs` delegation repair, PDC time source, and full `dcdiag`/`repadmin` validation | `windows-server` `active-directory` `fsmo` `dns` `disaster-recovery` `domain-controller` |
| **PowerShell 7** | [Installing PowerShell 7](./PowerShell%207/Installing%20PowerShell%207.md) | Install PS7 on Windows/macOS, verify the install, add the ExchangeOnlineManagement module, and troubleshoot | `powershell` `installation` `setup` |
| **PowerShell 7** | [PnP PowerShell App Registration & Connection](./PowerShell%207/PnP%20PowerShell%20Entra%20ID%20App%20Registration%20and%20Connection.md) | The per-tenant Entra ID app PnP has required since the shared app was retired: `Register-PnPEntraIDAppForInteractiveLogin`, default vs least-privilege permissions, admin consent, and `Connect-PnPOnline -Interactive -ClientId` | `powershell` `pnp` `sharepoint` `entra` `app-registration` `authentication` |
| **PowerShell 7** | [PowerShell Remoting](./PowerShell%207/PowerShell%20Remoting%20-%20Running%20Commands%20on%20Remote%20Computers.md) | Native `-ComputerName` vs `Invoke-Command` vs `PSSession`, which `-ComputerName` parameters PowerShell 7 removed, `Enable-PSRemoting` and the firewall, the `PowerShell.7.x` endpoint gotcha, TrustedHosts, and double-hop | `powershell` `remoting` `winrm` `invoke-command` `pssession` `troubleshooting` |

---

*New here? See [CONTRIBUTING.md](./CONTRIBUTING.md) for how this KB is organized and how to add to it. Start a new article from the [article template](./_templates/article-template.md).*
