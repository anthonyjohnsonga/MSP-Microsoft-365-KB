# SC-900 Microsoft Defender and Sentinel Study Sheet

**Applies to:** Exam SC-900: Microsoft Security, Compliance, and Identity Fundamentals.

**Scope:** Focused review of Defender products, Defender XDR, Microsoft Sentinel, and common Sentinel tools; not a complete SC-900 exam guide.

**Last Updated:** October 4, 2026

Use this sheet for product-selection practice, then check the official SC-900 skills outline for the full exam scope. Additional topics include Defender for Cloud and Defender Vulnerability Management, alongside identity, compliance, and security fundamentals.

**Study prerequisites:** No tenant, product license, or administrator role is needed to read this guide. Hands-on exercises require the appropriate product plans, Azure resources, and delegated permissions. Capabilities vary by license and platform; automated investigation and response are not included identically in every plan.

**MSP note:** Practice in an isolated lab with synthetic data. Verify the customer tenant and delegated role before investigating live incidents. This study sheet makes no configuration changes and needs no rollback; any lab automation that disables accounts or isolates devices needs its own approval and recovery plan.

## Overview

### How to Think About These Quickly

For the SC-900 exam, the easiest way to separate these is by asking:

**What is being protected, or what security role is being performed?**

- **Device** → Microsoft Defender for Endpoint
- **Identity/account** → Microsoft Defender for Identity
- **Email and collaboration** → Microsoft Defender for Office 365
- **Cloud apps / SaaS usage** → Microsoft Defender for Cloud Apps
- **Correlating signals across Defender products** → Microsoft Defender XDR
- **SIEM / SOAR across the environment** → Microsoft Sentinel

---

## 1. Microsoft Defender for Endpoint

### Prime Goal

Protect **endpoints/devices** from threats such as malware, ransomware, suspicious activity, and post-breach behavior.

### What It Protects

- Laptops
- Desktops
- Servers
- Mobile devices
- Other managed endpoints

### What It Is Mainly About

Think: **device security**.

This product focuses on what is happening **on the endpoint itself**:
- Malware protection
- Ransomware protection
- Endpoint detection and response (EDR)
- Threat investigation
- Automated remediation
- Attack surface reduction

### Key Terms to Remember

- Endpoint protection
- EDR
- Device risk
- Attack surface reduction
- Automated investigation and response

### Memory Trick

**Endpoint = the device itself.**

### Example Scenario

A laptop shows suspicious PowerShell activity and possible ransomware behavior.

**Best answer:** Microsoft Defender for Endpoint

---

## 2. Microsoft Defender for Identity

### Prime Goal

Protect **identities** by detecting and helping respond to **identity-based attacks**.

### What It Protects

- User accounts
- Credentials
- Service accounts
- Identity systems
- Hybrid identity environments

### What It Is Mainly About

Think: **account compromise and identity attacks**. Defender for Identity analyzes supported identity signals across on-premises, cloud, and hybrid environments. Do not confuse it with Microsoft Entra ID Protection, which focuses on user and sign-in risk.

This product focuses on:
- Credential theft
- Privilege escalation
- Suspicious authentication activity
- Lateral movement
- Identity compromise in hybrid environments

### Key Terms to Remember

- Identity-based attacks
- Privilege escalation
- Lateral movement
- Suspicious authentication
- Hybrid identity

### Memory Trick

**Identity = who the attacker is trying to become.**

### Example Scenario

An attacker is using stolen credentials and moving laterally through the environment.

**Best answer:** Microsoft Defender for Identity

---

## 3. Microsoft Defender for Office 365

### Prime Goal

Protect **email and collaboration tools** from phishing, malicious links, malicious attachments, and business email compromise.

### What It Protects

- Exchange Online email
- Email attachments
- URLs and links
- SharePoint Online
- OneDrive
- Microsoft Teams

### What It Is Mainly About

Think: **email and collaboration security**.

This product focuses on:
- Anti-phishing protection
- Safe Links
- Safe Attachments
- Protection for Teams, SharePoint, and OneDrive
- Business email compromise defenses

### Key Terms to Remember

- Safe Links
- Safe Attachments
- Anti-phishing
- Business email compromise (BEC)
- Email protection
- Collaboration protection

### Memory Trick

**Office 365 = inbox, attachments, links, Teams files.**

### Example Scenario

A user receives a phishing email with a malicious link and attachment.

**Best answer:** Microsoft Defender for Office 365

---

## 4. Microsoft Defender for Cloud Apps

### Prime Goal

Provide visibility and control over **cloud apps and SaaS usage**, while helping protect data in cloud apps.

### What It Protects

- SaaS applications
- Cloud app sessions
- Data stored in cloud apps
- App usage across the organization

### What It Is Mainly About

Think: **cloud app governance**.

This product focuses on:
- Shadow IT discovery
- Monitoring cloud app usage
- App governance
- Session controls
- Data protection in cloud applications
- SaaS risk visibility

### Key Terms to Remember

- CASB
- Shadow IT
- App governance
- Session control
- Cloud app visibility
- SaaS security

### Memory Trick

**Cloud Apps = what users are doing in cloud services.**

### Example Scenario

Security wants to discover which unsanctioned cloud apps employees are using.

**Best answer:** Microsoft Defender for Cloud Apps

---

## 5. Microsoft Defender XDR

### Prime Goal

Correlate signals across Microsoft security products so security teams can see **one attack story across multiple domains** and respond faster.

### What It Brings Together

Microsoft Defender XDR works across signals from:
- Microsoft Defender for Endpoint
- Microsoft Defender for Identity
- Microsoft Defender for Office 365
- Microsoft Defender for Cloud Apps

### What It Is Mainly About

Think: **cross-domain correlation**.

This product focuses on:
- Unified incidents
- Correlated alerts
- Cross-domain attack visibility
- Advanced hunting
- Investigation across Microsoft security workloads
- Connecting the full attack chain

### Key Terms to Remember

- XDR
- Unified incident
- Correlated signals
- Cross-domain detection
- Advanced hunting
- Integrated investigation

### Memory Trick

**XDR = the big picture across Defender tools.**

### Example Scenario

A phishing email leads to credential theft, suspicious endpoint activity, and risky cloud app behavior. Security wants one incident view tying it all together.

**Best answer:** Microsoft Defender XDR

---

## 6. Microsoft Sentinel

### Prime Goal

Act as the **SIEM and SOAR** solution for collecting, analyzing, investigating, and responding to security data across the environment.

### What It Works With

Microsoft Sentinel can ingest data from many sources, including:
- Microsoft 365
- Azure
- Endpoints
- Identity systems
- Firewalls
- Servers
- Network appliances
- Third-party tools
- Other cloud platforms

### What It Is Mainly About

Think: **SOC operations, analytics, and automation**.

This product focuses on:
- Centralized log ingestion
- Security analytics
- Incident creation
- Threat hunting
- Workbooks and dashboards
- Playbooks
- Automated response
- Data connectors

### Key Terms to Remember

- SIEM
- SOAR
- Log aggregation
- Analytics rules
- Incidents
- Threat hunting
- Playbooks
- Data connectors

### Memory Trick

**Sentinel = the command center.**

### Example Scenario

A company wants to ingest logs from Microsoft 365, firewalls, servers, and third-party tools into one platform for detections and automated response.

**Best answer:** Microsoft Sentinel

---

## Fast Comparison Section

| Product | Primary focus | Scenario cue |
|---|---|---|
| Defender for Endpoint | Endpoint protection, detection, and response | Suspicious activity on a laptop or server |
| Defender for Identity | Identity-based threat detection and investigation | Stolen credentials, privilege abuse, or lateral movement |
| Defender for Office 365 | Email and collaboration threat protection | Malicious email links or attachments |
| Defender for Cloud Apps | SaaS visibility, governance, and data protection | Shadow IT or risky cloud app sessions |
| Defender XDR | Correlated detection and response across workloads | One incident spanning email, identity, endpoints, and apps |
| Microsoft Sentinel | SIEM and SOAR across diverse data sources | Microsoft and third-party logs, analytics, and orchestration |

---
## Common SC-900 Confusion Points

**Scope reminder:** Defender for Cloud Apps concerns SaaS usage and data; Defender for Cloud concerns cloud security posture and workload protection. Defender XDR and Sentinel integrate in the Defender portal, so portal location alone does not distinguish them. These scenario cues simplify overlapping capabilities; use the requested outcome to choose the best answer.

### Defender for Endpoint vs Defender for Identity

- **Endpoint** = the attack is focused on the **device**
- **Identity** = the attack is focused on the **account or credentials**

Example:
- Malware on a workstation → **Defender for Endpoint**
- Stolen credentials and lateral movement → **Defender for Identity**

### Defender for Office 365 vs Defender for Cloud Apps

- **Office 365** = protects Microsoft 365 collaboration workloads like email, Teams, SharePoint, and OneDrive
- **Cloud Apps** = protects and governs broader cloud app/SaaS usage, including Shadow IT and app governance

### Defender XDR vs Microsoft Sentinel

- **Defender XDR** = correlates Microsoft Defender security signals into one attack story
- **Microsoft Sentinel** = SIEM/SOAR platform for collecting and analyzing logs across many Microsoft and non-Microsoft sources

##### Easy Way to Remember
- **Defender XDR** = “What attack is happening across Microsoft security tools?”
- **Microsoft Sentinel** = “What is happening across the whole environment, and how does the SOC manage it?”

---

## Microsoft Sentinel Tools: Workbooks, Analytics Rules, Playbooks, and Hunting Queries

### How to Think About These Quickly

For SC-900, separate these by asking:

**Am I trying to visualize data, detect threats, automate actions, or investigate manually?**

- **See the data in dashboards and charts** → Workbooks
- **Detect suspicious activity automatically** → Analytics rules
- **Automate response actions** → Playbooks (Azure Logic Apps)
- **Manually search for hidden threats** → Hunting queries

---

## 7. Workbooks

### Prime Goal

Visualize and monitor data with interactive dashboards, charts, tables, and reports.

### What It Is Mainly About

Think: **visibility and dashboards**.

Workbooks help analysts and admins:
- View trends
- Monitor security data
- Build visual reports
- Review data from connected sources in an interactive format

### Key Terms to Remember

- Visualization
- Dashboard
- Charts
- Tables
- Interactive reports
- Monitoring data

### Memory Trick

**Workbooks = show me the data.**

### Example Scenario

The SOC wants a dashboard showing sign-in trends, incident counts, and threat visuals.

**Best answer:** Workbooks

---

## 8. Analytics Rules

### Prime Goal

Detect threats automatically by evaluating data and generating alerts or incidents when suspicious conditions are met.

### What It Is Mainly About

Think: **detection logic**.

Analytics rules are used to:
- Look for suspicious patterns
- Create alerts
- Create incidents
- Identify threats based on templates or defined criteria

### Key Terms to Remember

- Detection
- Alert generation
- Incident creation
- Scheduled rule
- Rule templates
- Threat detection

### Memory Trick

**Analytics rules = tell me when something bad happens.**

### Example Scenario

A security team wants an alert when suspicious sign-in behavior appears in the logs.

**Best answer:** Analytics rules

---

## 9. Playbooks (Azure Logic Apps)

### Prime Goal

Automate and orchestrate response actions using Azure Logic Apps workflows. Playbooks can run manually or be triggered through automation rules.

### What It Is Mainly About

Think: **response automation**.

Playbooks help with actions such as:
- Notifying teams
- Creating tickets
- Disabling accounts
- Isolating devices
- Enriching incidents with extra data
- Orchestrating response workflows

### Key Terms to Remember

- Automation
- Orchestration
- Response
- Azure Logic Apps
- Incident actions
- Triggered workflow

### Memory Trick

**Playbooks = do something about it automatically.**

### Example Scenario

When a high-severity incident is created, the SOC wants a workflow to notify Teams, open a ticket, and disable the user account.

**Best answer:** Playbooks (Azure Logic Apps)

---

## 10. Hunting Queries

### Prime Goal

Proactively investigate data to look for suspicious activity that may not already be detected by rules.

### What It Is Mainly About

Think: **proactive investigation**, commonly using Kusto Query Language (KQL). Hunting queries can also support repeatable workflows; manual use is a study cue, not an absolute restriction.

Hunting queries are used when analysts want to:
- Search for hidden threats
- Investigate anomalies
- Test hypotheses
- Explore data beyond existing alerts

### Key Terms to Remember

- Threat hunting
- Proactive investigation
- Manual query
- Hypothesis-driven search
- Suspicious behavior analysis

### Memory Trick

**Hunting queries = go look for trouble.**

### Example Scenario

An analyst suspects malicious behavior is present even though no alert fired, so they manually query logs to investigate.

**Best answer:** Hunting queries

---

## Fast Comparison: Sentinel Tools

| Tool | Purpose | Scenario cue |
|---|---|---|
| Workbooks | Visualization | Interactive charts, tables, and dashboards |
| Analytics rules | Detection | Match suspicious activity and generate alerts; incident behavior depends on configuration |
| Playbooks | Response orchestration | Run Azure Logic Apps workflows manually or through automation |
| Hunting queries | Proactive investigation | Search data and test a threat hypothesis |
| Automation rules | Incident and alert workflow management | Assign, tag, or close incidents and trigger playbooks |

---
## Common Sentinel Confusion Points

### Workbooks vs Analytics Rules

- **Workbooks** = show the data visually
- **Analytics rules** = detect suspicious activity automatically

### Analytics Rules vs Playbooks

- **Analytics rules** = detect and alert
- **Playbooks** = take action after detection

### Analytics Rules vs Hunting Queries

- **Analytics rules** = automated detection
- **Hunting queries** = manual investigation by an analyst

---

## One-Line Cram Sheet

- **Defender for Endpoint** = protect the **device**
- **Defender for Identity** = protect the **identity**
- **Defender for Office 365** = protect **email and collaboration**
- **Defender for Cloud Apps** = protect **cloud app usage and SaaS data**
- **Defender XDR** = connect Defender signals into **one attack story**
- **Microsoft Sentinel** = **SIEM/SOAR** for the whole environment
- **Workbooks** = visualize the data
- **Analytics rules** = detect the threat
- **Playbooks** = automate the response
- **Hunting queries** = manually investigate for threats

---

## Quick Review Questions

### 1

A company wants to stop users from clicking malicious URLs in email.

**Answer:** Microsoft Defender for Office 365

### 2

A security team wants to detect suspicious lateral movement tied to compromised credentials.

**Answer:** Microsoft Defender for Identity

### 3

A laptop shows suspicious post-breach behavior and needs automated investigation.

**Answer:** Microsoft Defender for Endpoint

### 4

A company wants visibility into unsanctioned third-party cloud apps employees are using.

**Answer:** Microsoft Defender for Cloud Apps

### 5

A phishing attack leads to identity compromise and suspicious endpoint activity, and the security team wants one correlated incident view.

**Answer:** Microsoft Defender XDR

### 6

A SOC wants one platform to ingest logs from Microsoft 365, servers, firewalls, and third-party tools and then automate responses.

**Answer:** Microsoft Sentinel

### 7

A security manager wants a dashboard showing incidents by severity and sign-in trends.

**Answer:** Workbooks

### 8

A SOC wants Microsoft Sentinel to generate an alert when suspicious activity matches a defined pattern.

**Answer:** Analytics rules

### 9

A company wants an incident to automatically trigger a workflow that sends notifications and opens a ticket.

**Answer:** Playbooks (Azure Logic Apps)

### 10

An analyst suspects malicious behavior is present even though no alert fired, so they manually query the logs.

**Answer:** Hunting queries

---

## Final Study Shortcut

When you see these on the SC-900 exam, map them like this:

- **Device** → Defender for Endpoint
- **User/account** → Defender for Identity
- **Email/attachments/links/Teams files** → Defender for Office 365
- **SaaS/cloud apps/Shadow IT** → Defender for Cloud Apps
- **Correlated Microsoft security signals** → Defender XDR
- **SIEM, SOAR, log collection, analytics, playbooks** → Microsoft Sentinel
- **Dashboards and visual reports** → Workbooks
- **Automatic detections and incidents** → Analytics rules
- **Automated workflows and response** → Playbooks
- **Manual threat investigation** → Hunting queries

---

## Knowledge Check Checklist

- [ ] Match each of the six products to its primary security purpose without using the answer key.
- [ ] Explain why Defender for Cloud Apps differs from Defender for Cloud.
- [ ] Distinguish Defender for Identity from Entra ID Protection.
- [ ] Distinguish an analytics rule, an automation rule, and a playbook.
- [ ] Explain how XDR and SIEM/SOAR complement each other.
- [ ] Review the official SC-900 outline for topics outside this sheet before scheduling the exam.

## Sources

- [Microsoft Learn: SC-900 study guide and skills measured](https://learn.microsoft.com/en-us/credentials/certifications/resources/study-guides/sc-900)
- [Microsoft Learn: Defender for Endpoint overview](https://learn.microsoft.com/en-us/defender-endpoint/microsoft-defender-endpoint)
- [Microsoft Learn: Defender for Identity overview](https://learn.microsoft.com/en-us/defender-for-identity/what-is)
- [Microsoft Learn: Defender for Office 365 overview](https://learn.microsoft.com/en-us/defender-office-365/mdo-about)
- [Microsoft Learn: Defender for Cloud Apps overview](https://learn.microsoft.com/en-us/defender-cloud-apps/what-is-defender-for-cloud-apps)
- [Microsoft Learn: Defender XDR overview](https://learn.microsoft.com/en-us/defender-xdr/microsoft-365-defender)
- [Microsoft Learn: Microsoft Sentinel overview](https://learn.microsoft.com/en-us/azure/sentinel/overview)
- [Microsoft Learn: Configure Sentinel content](https://learn.microsoft.com/en-us/azure/sentinel/configure-content)
- [Microsoft Learn: Sentinel automation rules and playbooks](https://learn.microsoft.com/en-us/azure/sentinel/automation/automation)
- [Microsoft Learn: Create and manage Sentinel playbooks](https://learn.microsoft.com/en-us/azure/sentinel/automation/create-playbooks)
