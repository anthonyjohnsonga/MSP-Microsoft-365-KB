# Shadow AI Discovery Guide

**Applies to:** Microsoft 365 Business Premium; Microsoft Defender Suite for Business Premium; Microsoft Purview Suite for Business Premium; Microsoft Entra Internet Access  
**Scope:** Discover unapproved AI application use through Defender for Cloud Apps, Global Secure Access, and Microsoft Purview, then validate coverage before enforcement  
**Last Updated:** November 2026

## Overview

Start with **Microsoft Defender > Cloud apps > Cloud discovery > Discovered apps** to review AI application usage, **Entra > Global Secure Access > Applications > Insights and Analytics > Cloud Applications** for traffic routed through Entra Internet Access, or **Purview > Solutions > DSPM > Discover > Activity explorer > AI activities** for collected AI events.

Shadow AI is AI application use outside the customer's approved inventory or policy. A discovered AI application needs review before it is classified as unauthorized. These methods provide different evidence: network activity can identify an app without revealing the prompt, while Purview content visibility depends on supported capture and policy configuration.

## Minimum Licensing for Business Premium

Business Premium includes Entra ID P1 and Defender for Business. It does not include every capability in the products below. Choose the row for the actual collection or enforcement method rather than buying all suites by default.

| Capability | Business Premium alone | Minimum additional licensing path in a Business Premium tenant |
|---|---|---|
| Limited Cloud App Discovery with uploaded firewall/proxy logs, app catalog, and risk scores | Included through Entra ID P1 | No add-on for this limited discovery route; supply supported logs |
| Full Defender for Cloud Apps, including native endpoint discovery integration | Not included | Full **Defender for Cloud Apps** license. Suite options include **Defender Suite for Business Premium**, **Purview Suite for Business Premium**, or the combined **Defender and Purview Suites for Business Premium** |
| Endpoint source for full Defender for Cloud Apps discovery | Defender for Business is a supported endpoint option when full Defender for Cloud Apps is also licensed | An upgrade to Endpoint Plan 2 is not required solely for the documented discovery integration |
| Entra Internet Access discovery and web filtering for general internet/SaaS traffic | Not included | **Microsoft Entra Internet Access** standalone or **Microsoft Entra Suite**; Business Premium supplies the prerequisite Entra ID P1 |
| Advanced Purview workloads used for AI data protection and investigation, such as Endpoint DLP and Insider Risk Management | Not included | **Purview Suite for Business Premium** or the combined suite; confirm the chosen DSPM scenario's availability, collection prerequisites, and billing |

The [Cloud App Discovery comparison](https://learn.microsoft.com/en-us/defender-cloud-apps/editions-cloud-app-security-aad) distinguishes the P1 log-upload entitlement from full Defender for Cloud Apps. Microsoft's [endpoint integration prerequisites](https://learn.microsoft.com/en-us/defender-cloud-apps/mde-integration) explicitly support Defender for Business alongside full Defender for Cloud Apps. The [SMB suite comparison](https://www.microsoft.com/licensing/guidance/Security-Suites) lists full Defender for Cloud Apps in both Business Premium suite options.

**Practical purchase choices:** For endpoint-based app discovery, add full Defender for Cloud Apps through a suitable standalone or suite license. Choose Purview Suite when the customer also needs the Purview protection and investigation workflows. Choose Defender Suite when the customer needs its endpoint, identity, and email upgrades. The combined suite supplies both sets of upgrades. Entra Internet Access remains a separate purchase unless covered by Entra Suite; Entra ID P2 in Defender Suite does not supply it. See [Global Secure Access licensing](https://learn.microsoft.com/en-us/entra/global-secure-access/overview-what-is-global-secure-access#licensing-overview).

**Endpoint Plan 2 migration caveat:** If upgrading from Defender for Business to Endpoint Plan 2 through Defender Suite, Microsoft's Business Premium FAQ says mixed endpoint licensing defaults to the Defender for Business experience. License all users for the intended upgrade and follow Microsoft's tenant-switch process, including contacting Support where required. This restriction concerns the endpoint experience; it does not mean every Purview pilot requires Defender Suite for every user. [Business Premium security FAQ](https://learn.microsoft.com/en-us/microsoft-365/admin/security-and-compliance/m365bp-security-faq)

Business Premium suite add-ons require the corresponding base license and are intended for up to 300 users. Assign entitlements to users benefiting from the selected service. A single administrator's add-on is not a tenant-wide monitoring entitlement. Confirm current CSP pricing and terms when quoting rather than relying on a fixed price in this runbook. [Purview Business Premium plan](https://www.microsoft.com/en-us/security/small-medium-business/microsoft-purview-suite-business-premium)

**Additional charges:** Third-party AI collection and analysis can require Purview pay-as-you-go billing even when a suite is assigned. Review the selected browser, network, connector, and compliance workload before activation. Paid Microsoft 365 Copilot is a separate license for its own experience; it is not a prerequisite simply to discover that users visited a third-party AI site. [Purview billing models](https://learn.microsoft.com/en-us/purview/purview-billing-models)

## Prerequisites and Permissions

| Task | Required preparation |
|---|---|
| Review app usage | Confirm customer tenant, approved AI inventory, pilot users/devices, test time zone, and reporting window |
| Defender discovery | Supply supported firewall/proxy logs for limited discovery, or onboard supported devices and license full Defender for Cloud Apps for endpoint integration |
| Defender administration | Use a Cloud App Security Administrator or appropriately scoped Defender for Cloud Apps role; use read-only access for reviewers where possible |
| Global Secure Access | Global Secure Access Administrator for configuration; Global Secure Access Log Reader for analytics. Conditional Access changes require appropriate additional permissions |
| Purview AI investigation | Data Security AI Viewers for AI activity visibility and Data Security AI Content Viewers for prompt text; additional solution roles apply to configuration and insider risk signals |
| Pilot test | Use a harmless prompt such as `Explain SHADOW-AI-LAB-001 in one sentence.` Record the account, device, browser, app, timestamp, and expected collection method |

Use the official [Defender admin access guidance](https://learn.microsoft.com/en-us/defender-cloud-apps/manage-admins), [Global Secure Access analytics roles](https://learn.microsoft.com/en-us/entra/global-secure-access/overview-application-usage-analytics), and [DSPM permission matrix](https://learn.microsoft.com/en-us/purview/data-security-posture-management-permissions). Effective permissions can depend on the tenant's RBAC configuration and scope.

## 1. Discover AI Apps with Defender for Cloud Apps

1. Select a data source. With Business Premium alone, use supported firewall/proxy log upload under **Defender > Cloud apps > Cloud discovery**. Verify the source format, timestamps, and user/device information before interpreting results.
2. For native endpoint discovery, verify full Defender for Cloud Apps licensing and healthy Defender for Business or Endpoint Plan 2 onboarding on the pilot devices.
3. Enable **Defender > Settings > Endpoints > General > Advanced features > Microsoft Defender for Cloud Apps**, then save. Some portal layouts omit the **General** grouping.
4. Generate approved AI-site traffic on the pilot device. Microsoft documents up to two hours for initial endpoint discovery data after integration; allow for reporting and source-processing delays.
5. Open **Cloud apps > Cloud discovery > Discovered apps**. Filter the catalog category for **Generative AI** and any other AI categories exposed in the tenant. Search the app name directly if a category is absent.
6. Inspect the app's users, devices, traffic volume, last-seen time, risk score, and underlying risk factors. Check the selected data source and date range.
7. Compare results with the approved inventory and record the customer's decision. Usage volume alone does not establish what data was submitted.

The discovery entitlement does not make endpoint blocking automatic. Microsoft's [Cloud Discovery overview](https://learn.microsoft.com/en-us/defender-cloud-apps/set-up-cloud-discovery) describes supported collection routes.

### Optional Endpoint Enforcement

Before tagging an app **Unsanctioned**, review **Settings > Cloud apps > Cloud discovery > Microsoft Defender for Endpoint > Enforce app access**. Also check **Settings > Endpoints > Advanced features > Custom network indicators**, Defender Antivirus/cloud protection, Network Protection in **Block** mode, supported platforms, and the effective endpoint entitlement. Discovery integration support alone is not proof that every enforcement feature is licensed or available.

Use a scoped pilot profile where supported. Unsanctioned app domains can be synchronized into endpoint indicators; test the result on each intended browser/platform. A **Monitored** tag can support a warning workflow where configured, but the tag alone does not guarantee that a warning appears. Follow [Govern discovered apps](https://learn.microsoft.com/en-us/defender-cloud-apps/mde-govern) for enforcement prerequisites and scoping. Microsoft documents up to three hours for the block workflow to propagate.

This route covers participating endpoints. Record unmanaged devices and missing sensors as coverage gaps.

## 2. Discover AI Apps with Entra Internet Access

1. Assign **Entra Internet Access** or **Entra Suite** to pilot users and confirm their Entra ID P1 prerequisite.
2. Deploy a supported Global Secure Access client to the pilot devices and verify the user is connected. This procedure uses client-based forwarding; remote-network deployments require separate design and validation.
3. Open **Entra > Global Secure Access > Connect > Traffic forwarding**. Enable the **Internet Access** profile and assign the intended users/groups.
4. Review acquisition and bypass rules. Confirm that the test destination's traffic is actually forwarded rather than bypassed or handled by another proxy/VPN.
5. Browse to an approved AI site. Open **Global Secure Access > Applications > Insights and Analytics > Cloud Applications** and enable **Generative AI apps and tools**.
6. Inspect the app, users, transactions, traffic, and risk details. Compare the activity timestamp with the test record.

The Microsoft-services traffic profile included with Entra ID P1/P2 does not provide general internet AI discovery coverage. See the [Internet Access profile](https://learn.microsoft.com/en-us/entra/global-secure-access/how-to-manage-internet-access-profile) and [shadow IT discovery tutorial](https://learn.microsoft.com/en-us/entra/global-secure-access/tutorial-internet-access-application-discovery).

For enforcement, configure web filtering policies, group them in a security profile, and apply the intended Conditional Access scope. Review the baseline profile because it can apply to all acquired internet traffic. Domain-based discovery/filtering can use HTTPS connection metadata; TLS inspection is needed for controls that inspect encrypted content, not for every app-discovery result. Advanced AI/network controls have their own prerequisites and release status. [Entra Internet Access controls](https://learn.microsoft.com/en-us/entra/global-secure-access/concept-internet-access)

## 3. Inspect AI Data Activity with Microsoft Purview

1. Verify the selected Purview workload license, supported region, collection route, and usage billing. Use the current **Purview > Solutions > DSPM** experience; **DSPM for AI (classic)** is the older navigation.
2. Open **Setup tasks** and review the required configuration. Confirm auditing for supported Microsoft 365 AI activity.
3. For endpoint DLP, verify Purview device onboarding and policy delivery. Existing Defender onboarding can simplify deployment, but does not by itself prove that Purview collection is enabled.
4. Configure the required browser integration. Edge requires the applicable policy to activate Purview integration. For Chrome or Firefox endpoint controls, verify Microsoft's current extension and platform support for the exact action being deployed.
5. For content capture, configure the supported collection policy and select its content-capture setting. Browser/network/connector routes have different coverage; an extension installation or a website-visit policy alone does not capture every prompt.
6. Generate the approved test activity after policy activation. Allow about a day for initial DSPM setup data, then open **Discover > Activity explorer > AI activities** and filter by user, time, and app.
7. Distinguish **AI website visit**, **AI interaction**, sensitive-information detections, and DLP matches. Verify readable text only when the selected capture route supports it and the reviewer has content permissions.

For unmanaged AI apps in Edge, current DSPM considerations document text prompts only. Other compliance capture routes and supported apps can differ; do not promise complete responses or identical capture across browsers. Use [DSPM considerations](https://learn.microsoft.com/en-us/purview/data-security-posture-management-considerations) and [Purview support for other AI apps](https://learn.microsoft.com/en-us/purview/ai-other-apps) to define the actual coverage.

See the [Copilot Prompt Investigation Guide](./Microsoft%20Copilot%20Prompt%20Investigation%20Guide.md) for stored-content searches, Communication Compliance, and Insider Risk Management workflows.

## 4. Choose a Starting Point

| Customer situation | First practical step |
|---|---|
| Business Premium only, with usable firewall/proxy logs | Start with limited Cloud App Discovery and assess whether endpoint integration is needed |
| Already licensed for full Defender for Cloud Apps | Validate endpoint discovery before adding another collection product |
| Already licensed for Entra Internet Access or Entra Suite | Validate traffic forwarding and review cloud application analytics |
| Main concern is sensitive information entering AI tools | Pilot Purview content detection/DLP with documented browser and capture coverage |
| Needs all three workflows | Evaluate Business Premium plus Purview Suite and Entra Internet Access first; add Defender upgrades or the combined suite when their additional capabilities are required |

Compare overlapping evidence by user, device, app, and time. Different counts can reflect different collection sources and processing windows. No result from a single method proves that an app was never used.

## Verification / Testing Checklist

- [ ] Confirm the customer's base, add-on, and per-user entitlements for the selected workflow.
- [ ] Record pilot users/devices, browsers, app, and test time zone.
- [ ] Confirm the discovery source received new traffic from the pilot.
- [ ] Validate the AI app appears in the expected report and time range.
- [ ] Record unmanaged devices, bypassed traffic, unsupported apps, and browser capture limits.
- [ ] Verify content visibility separately from website visits or app usage.
- [ ] Test a permitted app and an approved pilot block/warning before broader enforcement.
- [ ] Check metered usage before expanding Purview collection.
- [ ] Save the customer decision, exceptions, owner, and review date in the service ticket.

## Troubleshooting

| Symptom | Check | Action |
|---|---|---|
| No endpoint Cloud Discovery data | Full Defender for Cloud Apps entitlement, sensor health, integration, reporting window | Verify a known supported test app and allow ingestion; the P1 discovery subset alone does not supply native endpoint integration |
| App tagged Unsanctioned remains accessible | Enforcement toggle, indicators, Network Protection mode, scope, propagation | Validate the endpoint enforcement prerequisites and test after propagation |
| Entra analytics has no AI traffic | Client connection, user assignment, acquisition/bypass rules, other proxies | Confirm the actual test connection was routed through Internet Access |
| AI category missing | Catalog classification, rollout, data source | Search the app directly and document the classification; do not assume there was no usage |
| Purview shows a visit without content | Capture route, supported app/browser, capture option, permissions | Validate a supported interaction and the content-viewer role |
| Different products report different totals | Source scope, timestamps, sessions, ingestion | Compare a single recorded pilot interaction before interpreting aggregate counts |

## Rollback and MSP Notes

1. Record original tags, forwarding assignments, browser configuration, integration toggles, and policy settings before the pilot.
2. Restore pilot app tags/scopes or web-filter rules if access must be restored. Allow propagation and confirm the app works on a pilot device.
3. Restore the original Internet Access assignments and acquisition rules when removing a pilot; check whether existing production controls depend on that traffic path.
4. Pause or disable pilot Purview collection where supported. Remove pilot-only settings and temporary reviewer access after checking production dependencies.
5. Review ongoing usage charges and evidence retention. Disabling collection does not erase previously collected records.

**MSP note:** Validate each customer's tenant, licenses, role scope, and data sources separately. Keep usage exports and investigation evidence in that customer's restricted storage. Partner access does not automatically provide all Defender, Entra, or Purview roles. Record platform limitations and approved exceptions as part of the service scope.

## Sources

- Microsoft Learn: [Cloud App Discovery capability comparison](https://learn.microsoft.com/en-us/defender-cloud-apps/editions-cloud-app-security-aad)
- Microsoft Learn: [Defender for Endpoint integration prerequisites](https://learn.microsoft.com/en-us/defender-cloud-apps/mde-integration)
- Microsoft Learn: [Cloud Discovery overview](https://learn.microsoft.com/en-us/defender-cloud-apps/set-up-cloud-discovery)
- Microsoft Learn: [Govern discovered apps](https://learn.microsoft.com/en-us/defender-cloud-apps/mde-govern)
- Microsoft Learn: [Defender for Cloud Apps admin access](https://learn.microsoft.com/en-us/defender-cloud-apps/manage-admins)
- Microsoft Licensing: [Security suite service comparison](https://www.microsoft.com/licensing/guidance/Security-Suites)
- Microsoft Learn: [Business Premium security FAQ](https://learn.microsoft.com/en-us/microsoft-365/admin/security-and-compliance/m365bp-security-faq)
- Microsoft Security: [Purview Suite for Business Premium](https://www.microsoft.com/en-us/security/small-medium-business/microsoft-purview-suite-business-premium)
- Microsoft Learn: [Global Secure Access and licensing](https://learn.microsoft.com/en-us/entra/global-secure-access/overview-what-is-global-secure-access)
- Microsoft Learn: [Internet Access traffic forwarding profile](https://learn.microsoft.com/en-us/entra/global-secure-access/how-to-manage-internet-access-profile)
- Microsoft Learn: [Discover applications and shadow IT](https://learn.microsoft.com/en-us/entra/global-secure-access/tutorial-internet-access-application-discovery)
- Microsoft Learn: [Application usage analytics](https://learn.microsoft.com/en-us/entra/global-secure-access/overview-application-usage-analytics)
- Microsoft Learn: [Entra Internet Access controls](https://learn.microsoft.com/en-us/entra/global-secure-access/concept-internet-access)
- Microsoft Learn: [Current DSPM experience](https://learn.microsoft.com/en-us/purview/data-security-posture-management-learn-about)
- Microsoft Learn: [DSPM considerations](https://learn.microsoft.com/en-us/purview/data-security-posture-management-considerations)
- Microsoft Learn: [DSPM permissions](https://learn.microsoft.com/en-us/purview/data-security-posture-management-permissions)
- Microsoft Learn: [Purview support for other AI apps](https://learn.microsoft.com/en-us/purview/ai-other-apps)
- Microsoft Learn: [Purview billing models](https://learn.microsoft.com/en-us/purview/purview-billing-models)
