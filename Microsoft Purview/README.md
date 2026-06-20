# Microsoft Purview

This folder contains reference guides for Microsoft Purview compliance and data protection — data loss prevention (DLP), information protection, and related monitoring controls in a Microsoft 365 managed environment.

---

### [Microsoft Purview DLP — SharePoint/OneDrive External Sharing Alert](./Microsoft%20Purview%20DLP%20External%20Sharing%20Alert%20Policy%20Creation.md)

A step-by-step guide for building a monitor-only DLP policy that alerts administrators whenever a user shares SharePoint or OneDrive content with someone outside the organization, regardless of the permission path taken. Walks the full Purview portal wizard — policy creation, location scoping to SharePoint/OneDrive only, and a single rule combining the "shared with people outside my organization" condition with a Restrict access/Block action, user notifications, and high-severity admin incident alerts. Runs in simulation mode so nothing is actually blocked for end users. Includes a known-errors table (the `must contain one or more of these conditions` and `Missing parameter: NotifyUser` failures and their fixes) plus a post-deployment verification workflow. Included with Business Premium and E3/E5 — no add-on required.
