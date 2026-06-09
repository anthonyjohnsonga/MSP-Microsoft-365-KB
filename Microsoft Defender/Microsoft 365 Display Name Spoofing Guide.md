# M365 Display Name Spoofing Defense Guide
**Platform:** Microsoft 365 Business Premium  
**Threat:** External senders using internal employee display names to impersonate staff  
**Last Updated:** June 2026

---

## Overview

Display name spoofing is a phishing technique where an attacker sends email from an external domain but sets the display name to match a trusted internal employee — such as the CEO, a manager, or a finance contact. Because the email technically passes SPF/DKIM/DMARC for the attacker's own domain, standard email authentication does not block it.

**Example attack:**

| Field | Legitimate Email | Spoofed Email |
|-------|-----------------|---------------|
| Display Name | John Smith | John Smith |
| Sender Address | john.smith@contoso.com | billing@randomdomain.net |
| DMARC Result | Pass | Pass (for randomdomain.net) |

The goal of this guide is to layer defenses that reduce delivery of these messages, flag them visually for users, and train users to recognize them.

---

## Layer 1 — Email Authentication (Foundation)

Before configuring any anti-spoofing policies, verify the tenant has proper email authentication in place. Without this, other defenses are weakened.

### Required DNS Records

| Record | Minimum Requirement | Recommended |
|--------|-------------------|-------------|
| **SPF** | `v=spf1 include:spf.protection.outlook.com -all` | Hard fail (`-all`) |
| **DKIM** | Enabled and signing in EXO | Both selectors active |
| **DMARC** | `p=none` (monitoring) | `p=quarantine` or `p=reject` |

### How to Enable DKIM

1. Navigate to **Microsoft 365 Defender → Email & Collaboration → Policies & Rules → Threat Policies → Email Authentication Settings**
2. Select your domain
3. Toggle **Sign messages for this domain with DKIM signatures** to **Enabled**
4. Add the two CNAME records to your public DNS

### DMARC Progression

Start at `p=none` to monitor without impacting mail flow, then advance:

```
p=none      → monitoring only, no action taken
p=quarantine → failed messages go to junk/quarantine
p=reject    → failed messages are dropped outright
```

> **Note:** DMARC `p=reject` does not stop display name spoofing directly. It closes the door on direct domain spoofing (someone sending as @contoso.com from an unauthorized server), which forces attackers into display name-only tactics. Both problems need to be addressed.

> **User Impact:** Advancing DMARC to `p=quarantine` or `p=reject` can cause legitimate email to be rejected if SPF and DKIM are not fully configured first. Validate both are working before changing the DMARC policy. Use a DMARC reporting tool (e.g., Valimail, Dmarcian) to review aggregate reports before advancing.

---

## Layer 2 — External Sender Callouts (Quick Win)

This setting adds a visible banner to any email arriving from outside the organization. It is the single highest-value, lowest-effort control for display name spoofing because it works regardless of what display name the attacker uses.

### Enable External Sender Callouts

1. Navigate to **Exchange Admin Center → Settings → Mail Flow**
2. Enable **Show first contact safety tip**
3. Enable **Show (?) for unauthenticated senders**

The `(?)` icon appears in Outlook on the sender's profile picture when SPF or DKIM do not pass. For display name spoofing, the external callout banner is the more visible indicator.

> **User Impact:** Users will see a yellow banner on all external emails — including legitimate vendor mail, newsletters, and partner communications. Set expectations with users during rollout so this is not seen as alarming. The banner reads something like: *"You don't often get email from sender@domain.com. Learn why this is important."* Train users to treat this as a verification prompt, not an alarm.

---

## Layer 3 — Anti-Phishing Policy — User Impersonation Protection

Microsoft Defender for Office 365 Plan 1 (included in Business Premium) provides user impersonation detection. When configured, it compares the sender's display name and email address against a list of protected users and can flag or quarantine messages that appear to impersonate them.

### Configure User Impersonation Protection

1. Navigate to **Microsoft 365 Defender → Email & Collaboration → Policies & Rules → Threat Policies → Anti-phishing**
2. Edit the default policy or create a new one
3. Under **Phishing threshold & protection**, expand **User impersonation**

**Settings to configure:**

| Setting | Recommended Value |
|--------|-----------------|
| Enable users to protect | On |
| Users to protect | Add CEO, CFO, owner, finance contacts, IT admin, any exec commonly impersonated |
| If message is detected as impersonated user | **Quarantine the message** |
| Show user impersonation safety tip | On |
| Enable mailbox intelligence | On |
| Enable intelligence for impersonation protection | On |

> **User Impact:** If the action is set to quarantine, legitimate mail from external senders with matching display names (e.g., a vendor contact who shares a name with an employee) will be quarantined silently. Consider setting the action to **Move to Junk** initially, then tightening to **Quarantine** after reviewing false positives over the first two weeks. When a message triggers the impersonation safety tip, users will see a yellow callout above the email body — train users to verify the sender's actual email address before taking any action.

### Domain Impersonation Protection

While not the primary control for display name spoofing, also enable:

| Setting | Recommended Value |
|--------|-----------------|
| Enable domains to protect | On |
| Include owned domains | On |
| Add trusted partner domains | Add high-value vendor/partner domains |
| Action | Quarantine |

---

## Layer 4 — Mail Flow Rules (Most Targeted Control)

Transport rules in Exchange Admin Center give you the most precise control for display name spoofing. They evaluate the `From` display name directly and can act on messages before they reach any inbox.

### Rule: Flag High-Risk Display Name Impersonation

This rule intercepts external email where the display name matches an internal executive or key employee.

**Where to create:** Exchange Admin Center → Mail Flow → Rules → **+ Add a rule → Create a new rule**

#### Rule Configuration

**Name:** `Block - Executive Display Name Impersonation`

| Field | Value |
|-------|-------|
| Apply this rule if | *The sender is located outside the organization* **AND** *The From address includes any of these words*: `[list of names]` |
| Do the following | *Prepend the subject with*: `[WARNING - POSSIBLE IMPERSONATION]` AND *Set the spam confidence level (SCL) to*: `9` (routes to quarantine) |
| Except if | *The sender address matches*: actual employee email addresses |
| Priority | Set high (low number) |
| Mode | Enforce |

**Display names to include (examples — customize per client):**

```
CEO First Last
CFO First Last
Owner First Last
Accounts Payable
Payroll
IT Support
Help Desk
```

> **User Impact:** Legitimate external senders who share a name with an employee will have their email quarantined or flagged. This is most likely to affect companies with common executive names. Add exceptions for known external contacts whose display names match internal employees, and monitor the quarantine queue weekly after enabling. As a staged rollout approach, start with subject-line prepending only before enabling the SCL-9 action — this lets users see and report suspicious mail while you tune the rule before messages go silently to quarantine.

### Rule: Warn on All External Mail with Internal Domain in Display Name

A broader rule to catch cases where the attacker includes the company domain name in the display name (e.g., "John Smith - Contoso"):

| Field | Value |
|-------|-------|
| Apply this rule if | *The sender is located outside the organization* **AND** *The From address includes*: `[companydomain.com]` |
| Do the following | *Prepend subject with*: `[EXTERNAL - NOT FROM CONTOSO]` |
| Except if | *The sender address is*: `*@companydomain.com` |

---

## Layer 5 — User Awareness Training

Technical controls reduce but cannot eliminate display name spoofing. User behavior is the last line of defense.

### Key Training Points

- **Display names are not verified.** Any external sender can set any display name. The only verified identity is the actual email address in the `From` field.
- **How to check the real sender address in Outlook:** Click or tap the sender name — Outlook will expand the full email address. If it does not match the expected domain, treat it as suspicious.
- **High-risk requests always warrant out-of-band verification.** Any email requesting:
  - Wire transfers or ACH changes
  - Payroll direct deposit changes
  - Credential resets or MFA bypass
  - Urgent purchases or gift cards

  ...should be verified by calling the sender directly using a known phone number — not one provided in the email itself.

- **The external sender banner is a verification prompt.** When users see the yellow banner, it means the sender is external. It does not mean the email is malicious — but it does mean they should verify before acting.

### Recommended Simulated Phishing

Use **Microsoft Attack Simulator** (included in Business Premium via Defender for Office 365 P1) to run display name impersonation simulations:

1. Navigate to **Microsoft 365 Defender → Email & Collaboration → Attack Simulation Training**
2. Create a simulation using the **Credential Harvest** or **Spear Phishing Attachment** technique
3. Set the display name to an internal executive
4. Use an external sender domain
5. Target finance, HR, and executive assistant roles first

Review click rates and follow up with targeted training for users who interact with the simulation.

> **User Impact:** Notify leadership before running simulations. Some organizations require HR or legal sign-off. Frame the program as education, not punishment — users who click receive training, not disciplinary action.

---

## Implementation Checklist

| # | Task | Priority | User Impact |
|---|------|----------|-------------|
| 1 | Verify SPF hard fail is configured | High | None |
| 2 | Enable and validate DKIM signing | High | None |
| 3 | Set DMARC to `p=quarantine` (after validating SPF/DKIM) | High | Low — monitor for false positives |
| 4 | Enable external sender callouts in EAC | High | Low — users see banner on external mail |
| 5 | Populate user impersonation list in anti-phishing policy | High | Medium — quarantine action may affect legit mail |
| 6 | Enable mailbox intelligence | High | None |
| 7 | Create transport rule for executive display name impersonation | High | Medium — tune exceptions during first two weeks |
| 8 | Enable impersonation safety tips | Medium | Low — visual tip on flagged messages |
| 9 | Run Attack Simulator display name phishing test | Medium | Medium — communicate to users beforehand |
| 10 | Deliver user awareness training on display name spoofing | Medium | None — educational |

---

## Monitoring and Ongoing Maintenance

- **Quarantine review:** Check **Microsoft 365 Defender → Review → Quarantine** weekly for the first month after enabling these controls. Release and whitelist false positives as needed.
- **Spoof intelligence report:** Review monthly at **Defender → Email & Collaboration → Policies & Rules → Threat Policies → Spoof Intelligence**
- **DMARC aggregate reports:** Review using a third-party tool or the DMARC record `rua=` tag to catch misconfigured sending sources.
- **Update the transport rule display name list** whenever there are staffing changes to executive or finance roles.
- **Attack Simulator cadence:** Run at least one display name impersonation simulation per quarter.

---

*Guide covers Microsoft 365 Business Premium — Defender for Office 365 Plan 1 and Exchange Online Protection. Controls requiring Defender Plan 2 (Advanced Hunting, AIR) are not included.*
