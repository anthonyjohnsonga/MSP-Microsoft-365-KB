# MSP Microsoft 365 Knowledge Base

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
| **Defender** | [Display Name Spoofing Guide](./Microsoft%20Defender/Microsoft%20365%20Display%20Name%20Spoofing%20Guide.md) | Layered defense against external senders impersonating staff: DNS auth, anti-spoofing policies, external-sender tagging, user training | `defender` `email-security` `anti-phishing` `spoofing` |
| **Defender** | [SmartScreen & Network Protection](./Microsoft%20Defender/Microsoft%20Defender%20Smartscreen%20Network%20Protection.md) | SmartScreen vs Network Protection coverage, browser gaps, and the 3 Intune policies (EDR onboarding, ASR, web content filtering) | `defender` `mde` `network-protection` `smartscreen` `intune` |
| **Entra** | [Conditional Access Groups](./Microsoft%20Entra/Conditional%20Access%20Groups.md) | The four core CA security groups (Staff, Guest, Break Glass, Admins) with dynamic/assigned membership rules | `entra` `conditional-access` `groups` `identity` |
| **Entra** | [SSPR Deployment Guide](./Microsoft%20Entra/Microsoft%20SSPR%20Deployment%20Guide.md) | Self-Service Password Reset for cloud-only and hybrid (Entra Cloud Sync) tenants, incl. writeback, registration hardening, and testing | `entra` `sspr` `identity` `hybrid` `cloud-sync` |
| **Entra** | [Guest User Access Authorization Policy](./Microsoft%20Entra/Set%20Authorization%20Policy%20for%20Guest%20User%20Access.md) | Set the tenant-wide guest access level (User / Guest / Restricted) via portal or Graph PATCH, with GUIDs and required roles | `entra` `guest-access` `external-identities` `graph` |
| **Exchange Online** | [Mailbox Archiving](./Microsoft%20Exchange%20Online/Exchange_Online_Mailbox_Archiving.md) | Online vs auto-expanding archive, enabling by license tier, MRM retention tags, holds, Graph, and troubleshooting | `exchange` `archiving` `retention` `compliance` |
| **Exchange Online** | [Exchange Online Guide](./Microsoft%20Exchange%20Online/Microsoft_Exchange_Online_Guide.md) | Comprehensive helpdesk reference: user/shared/resource mailboxes, groups, mail flow, NDR codes, permissions, PowerShell | `exchange` `mailboxes` `mail-flow` `powershell` `helpdesk` |
| **Graph Scripts** | [MicrosoftGraph.ps1](./Microsoft%20Graph%20API%20Scripts/MicrosoftGraph.ps1) | Installs `Microsoft.Graph.Authentication` and connects with a broad set of admin scopes | `graph` `powershell` `authentication` |
| **Graph Scripts** | [mg-assign-role.ps1](./Microsoft%20Graph%20API%20Scripts/mg-assign-role.ps1) | Assigns an Entra ID role to a user via the Graph beta endpoint | `graph` `powershell` `entra` `roles` |
| **Graph Scripts** | [mg-create-user.ps1](./Microsoft%20Graph%20API%20Scripts/mg-create-user.ps1) | Creates a new Entra ID user via the Graph beta endpoint | `graph` `powershell` `entra` `user-provisioning` |
| **Intune** | [Disable Chrome Password Manager](./Microsoft%20Intune/Microsoft%20Intune%20Google%20Chrome%20Disable%20Password%20Manager.md) | Settings Catalog policy to disable Chrome's built-in password manager (`PasswordManagerEnabled`) | `intune` `chrome` `settings-catalog` `policy` |
| **Intune** | [Properties Catalog](./Microsoft%20Intune/Microsoft%20Intune%20Properties%20Catalog.md) | WMI-based device inventory via Properties Catalog: Resource Explorer, Graph beta, MSP use cases, error 2147749902 | `intune` `inventory` `device-management` `graph` |
| **Intune** | [Windows 11 Hotpatch Notes](./Microsoft%20Intune/Microsoft%20Windows%2011%20Hotpatch%20Notes.md) | Rebootless quality updates for Win11 24H2+: baseline/hotpatch schedule, VBS/HVCI prerequisites, the two Intune policies | `intune` `windows-11` `hotpatch` `updates` |
| **OneDrive** | [Sync Troubleshooting](./Microsoft%20OneDrive/Microsoft%20Onedrive%20Sync%20Troubleshooting.md) | Resolve sync failures, missing icons, and SharePoint sync/shortcut issues: Quick Fix, Full Fix, and file-recovery workflow | `onedrive` `sharepoint` `sync` `troubleshooting` |
| **OneDrive** | [Over-Quota Report Guide](./Microsoft%20OneDrive/Microsoft%20Onedrive%20Overquota%20Report%20Guide.md) | PnP `Get-ODBOverQuotaUsers.ps1` quick guide: scopes, usage, CSV columns, quota tiers, and MSP/GDAP gotchas | `onedrive` `storage-quota` `powershell` `graph` `reporting` |
| **Teams** | [External File Sharing (CsTeamsFilesPolicy)](./Microsoft%20Teams/Teams%20-%20External%20File%20Sharing%20via%20CsTeamsFilesPolicy.md) | Enable file attachments in external chats via `CsTeamsFilesPolicy` (PowerShell only) plus SharePoint external sharing | `teams` `external-sharing` `powershell` `policy` |
| **PowerShell 7** | [Installing PowerShell 7](./PowerShell%207/Installing_PowerShell_7.md) | Install PS7 on Windows/macOS, verify the install, add the ExchangeOnlineManagement module, and troubleshoot | `powershell` `installation` `setup` |

---

*New here? See [CONTRIBUTING.md](./CONTRIBUTING.md) for how this KB is organized and how to add to it. Start a new article from the [article template](./_templates/article-template.md).*
