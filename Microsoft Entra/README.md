# Microsoft Entra

This folder contains reference guides for managing identity, access, and security policies in Microsoft Entra ID (formerly Azure Active Directory).

---

### [Set Authorization Policy for Guest User Access](./Set%20Authorization%20Policy%20for%20Guest%20User%20Access.md)

A reference guide covering how to configure the tenant-wide guest user access authorization policy in Microsoft Entra ID. The guide explains the three available guest permission levels (User/Member, Guest User, and Restricted Guest User) and their corresponding GUIDs, outlines why organizations adjust these settings to balance security and external collaboration, and provides step-by-step instructions for applying the policy both through the Microsoft Entra Admin Center GUI and via a PATCH request to the Microsoft Graph API. Required admin roles for each configuration option are also documented.

---

### [Conditional Access Groups](./Conditional%20Access%20Groups.md)

A reference guide for setting up the four core security groups used in a Conditional Access framework. Covers the dynamic membership queries for the Staff group (users with at least one enabled service plan) and Guest group (guest user type filter), plus the Assigned membership setup for the Break Glass and Admins groups. These groups are used as inclusion/exclusion targets in Conditional Access policies across the tenant.

---

### [Microsoft SSPR Deployment Guide](./Microsoft%20SSPR%20Deployment%20Guide.md)

A deployment guide for Self-Service Password Reset (SSPR) covering both cloud-only Entra ID tenants and hybrid tenants synced via Microsoft Entra Cloud Sync. Current as of June 2026 (post legacy MFA/SSPR policy deprecation). Walks through licensing prerequisites, checking the legacy-to-unified authentication methods migration state, enabling SSPR and required auth methods, and — for hybrid clients — enabling Cloud Sync password writeback (agent permissions, Entra-side activation, on-prem GPO, and the writeback gaps that cause on-prem/cloud password drift). Closes with securing the registration process via Conditional Access and a full testing checklist.
