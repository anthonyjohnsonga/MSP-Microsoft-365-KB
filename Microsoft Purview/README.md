# Microsoft Purview

This folder contains reference guides for Microsoft Purview compliance and data protection — data loss prevention (DLP), information protection, and related monitoring controls in a Microsoft 365 managed environment.

---

### [Microsoft Purview DLP — SharePoint/OneDrive External Sharing Alert](./Microsoft%20Purview%20DLP%20External%20Sharing%20Alert%20Policy%20Creation.md)

A step-by-step guide for building a monitor-only DLP policy that alerts administrators whenever a user shares SharePoint or OneDrive content with someone outside the organization, regardless of the permission path taken. Walks the full Purview portal wizard — policy creation, location scoping to SharePoint/OneDrive only, and a single rule combining the "shared with people outside my organization" condition with a Restrict access/Block action, user notifications, and high-severity admin incident alerts. Runs in simulation mode so nothing is actually blocked for end users. Includes a known-errors table (the `must contain one or more of these conditions` and `Missing parameter: NotifyUser` failures and their fixes) plus a post-deployment verification workflow. Included with Business Premium and E3/E5 — no add-on required.

---

### [Microsoft Copilot Prompt Investigation Guide](./Microsoft%20Copilot%20Prompt%20Investigation%20Guide.md)

Locate stored Copilot prompts with eDiscovery, inspect current DSPM AI activity, and review Communication Compliance and Insider Risk Management policy matches. Includes minimum licensing paths for Business Premium, Purview Suite and combined Defender/Purview add-ons, separate Copilot and usage-billing requirements, workflow-specific permissions, browser prerequisites, screenshots, pilot verification, troubleshooting, and cleanup.

---

### [Shadow AI Discovery Guide](./Shadow%20AI%20Discovery%20Guide.md)

Compare Defender for Cloud Apps, Entra Internet Access, and Purview AI activity discovery. Covers Business Premium's limited discovery entitlement, minimum add-on licensing, Defender for Business integration, traffic and content capture limits, pilot verification, enforcement prerequisites, troubleshooting, and rollback.

---

## Related guides in other folders

- [Microsoft Exchange Online Email Encryption Setup Guide](../Microsoft%20Exchange%20Online/Microsoft%20Exchange%20Online%20Email%20Encryption%20Setup%20Guide.md) — Purview Message Encryption is enabled and troubleshot from Exchange Online PowerShell, so that guide lives in the Exchange Online folder.
