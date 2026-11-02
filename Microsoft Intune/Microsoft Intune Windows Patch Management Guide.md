# Microsoft Intune Windows Patch Management Guide

**Applies to:** Microsoft Intune Plan 1; supported Windows 11 business editions; additional Windows Autopatch entitlement for service-orchestrated policies

**Scope:** Windows client update planning, pilot deployment, verification, troubleshooting, and recovery in customer tenants

**Last Updated:** November 1, 2026

## Overview

Start in **Intune admin center > Devices > By platform > Windows > Manage updates > Windows updates**. Use **Update rings** for client behavior, **Feature updates** for the target Windows release, **Quality updates** for supported orchestration/expedite scenarios, and **Driver updates** for driver approvals. Microsoft Learn also uses the shorter navigation **Devices > Windows updates**. [Ring management][rings]

Intune distributes configuration; Windows Update supplies update content. Feature, quality, and driver policies use Windows Autopatch orchestration. Autopatch groups add coordinated grouping and rollout management. A ring alone does not approve individual patches. [Management overview][overview]

**Validation:** Documentation reviewed against Microsoft Learn and firsthand articles by Microsoft MVPs Peter van der Woude and Rudy Ooms. No tenant deployment or device installation was performed for this article. The example rollout below is an MSP planning example, not a Microsoft baseline.

## 1. Confirm Prerequisites and Ownership

| Requirement | Technician check |
|---|---|
| Licensing | Update rings require Intune Plan 1. Feature-update management additionally requires a Windows Autopatch entitlement. Eligible subscriptions include Microsoft 365 Business Premium, Windows Enterprise E3/E5, Education A3/A5, and Enterprise E3/E5 VDA. Check the entitlement table for each customer's purchased plan. [Rings][rings], [feature prerequisites][features], [Autopatch prerequisites][licensing] |
| Device scope | Use supported Windows 11 Pro, Enterprise, or Education editions appropriate to the policy. Intune enrollment and Entra join or hybrid join are required for service-orchestrated policies; Entra registration alone supports only client policies/rings. [Overview][overview] |
| Windows 10 and LTSC | Windows 10 22H2 ended ordinary support October 14, 2025. Verify current ESU entitlement and activation for remaining devices. LTSC has separate lifecycle rules; do not treat it as a normal feature-update target. [Lifecycle][lifecycle], [ESU][esu], [features][features] |
| Access | For feature-policy administration, use **Policy and Profile manager** or a scoped custom role with Device configurations permissions plus device visibility. Validate the selected policy's RBAC requirements and scope tags. Local diagnostic collection may require elevation. [Feature prerequisites][features] |
| Diagnostics | Enable required device diagnostic data and permit Intune to use it for reporting. Check that `wlidsvc` is enabled and running. [Feature prerequisites][features] |
| Network | Verify access to Intune, Windows Update, and Windows Autopatch endpoints through the customer's actual proxy/firewall configuration. [Feature prerequisites][features] |
| Existing management | Inventory GPO, WSUS, Configuration Manager, Settings Catalog, RMM patching, and existing Autopatch assignments before assigning new policies. Resolve competing update settings at their source. [Troubleshooting][troubleshoot] |

**MSP operating practice:** Record the customer tenant, policy owner, licenses, device groups, maintenance expectations, emergency approval contact, and recovery plan in the private change record. Scope tags organize administrative visibility; group assignments determine deployment. Review each customer's memberships independently. Keep customer identifiers and diagnostic exports out of this public repository.

For Autopatch group onboarding, also check its corporate-ownership, recent device communication, and co-management workload requirements. Do not layer a custom ring over service-maintained rings without reviewing ownership. [Autopatch prerequisites][licensing], [rings][rings]

## 2. Choose a Pilot and Configure Update Rings

1. Build separate device groups for representative test hardware, a business pilot, and broad production. Include VPN, printing, docking, accessibility, and critical application users in the pilot plan.
2. Under **Windows updates > Update rings > Create profile**, name the ring, set update behavior, apply scope tags, assign the intended device group, and review before creating it.
3. Avoid overlapping ring assignments. Inventory existing feature controls before changing deferrals; follow section 3 for migration.

Example settings to discuss with the customer:

| Setting | Test | Pilot | Broad |
|---|---|---|---|
| Quality update deferral | 0 days | 2 days | 5 days |
| Quality update deadline | 2 days | 3 days | 5 days |
| Grace period | 1 day | 2 days | 2 days |
| Notifications | Default Windows notifications | Same | Same |
| Auto reboot before deadline | Yes | Yes | Yes |
| Active hours | Match working hours | Match working hours | Match working hours |

These are example choices, not a promise that every device patches a fixed number of days after release. Validate allowed settings against the [ring settings reference][settings]. Use **Windows drivers: Allow** when deploying driver policies; section 5 covers the approval gate.

On current Windows 11 deadline policies, the deadline starts at update discovery; the grace period starts when a restart becomes pending. Enforcement uses the later applicable deadline. Active hours do not prevent a forced restart once that effective deadline is reached. Explain this to users before deployment. [Deadline behavior][deadlines]

Promote only after recording pilot installation/restart results and application checks. Agree on incident thresholds and an owner who can stop rollout; do not make promotion depend only on a green policy-assignment status.

## 3. Control the Windows Feature Version

1. Open **Windows updates > Feature updates > Create profile**. Select a supported target release, required or optional availability, rollout timing, and the pilot device group.
2. When replacing ring deferrals, assign the feature policy first. Wait until targeted devices show **OfferReady** in the **Windows feature updates (Organizational)** report before setting the ring's **Feature update deferral period (days)** to **0**. Do not use a fixed wait as proof of readiness.
3. Ensure feature updates are not paused. For co-management migration, establish the target and verify **OfferReady** before moving the Windows Update policies workload to Intune.
4. Check the target edition's lifecycle and compatibility before broad rollout. Retain safeguard holds while investigating known issues.

Feature policies do not downgrade a newer device. Overlapping policies can offer the newest applicable target; avoid accidental overlap. Optional offers require user action. [Feature-policy configuration][feature-config]

Feature policies do not apply during Autopilot OOBE; plan the post-provisioning scan and verification. [Feature prerequisites and behavior][features]

## 4. Manage Monthly Quality Updates and Emergencies

Monthly quality updates can continue through normal Windows Update behavior with rings; a separate quality policy is not mandatory. Use quality policies when the customer needs supported cloud orchestration, policy reporting, or hotpatch controls. Hotpatch is conditional on eligibility, and does not eliminate every restart. Check current defaults and requirements before changing it. [Quality management][quality], [management overview][overview]

For an approved emergency:

1. Open **Windows updates > Quality updates > Create > Expedite policy**.
2. Select an eligible update offered by the portal, set its restart enforcement, and assign the emergency device group.
3. Review installation and restart results before expanding scope. Expedite bypasses normal deferrals, but still depends on connectivity, applicability, and update scanning. It does not establish the cadence for future months.

For expedite support, Microsoft distinguishes older Windows versions from Windows 11 24H2 and later: do not install the legacy Update Health Tools on 24H2+ for this purpose. Follow the current prerequisite text rather than older remediation scripts. [Expedite policy][expedite]

**Microsoft 365 Apps:** Manage Click-to-Run updates separately through cloud update or supported Intune Settings Catalog policies. **Microsoft product updates: Allow** in a Windows ring is not a Microsoft 365 Apps channel/deadline strategy. Microsoft recommends cloud update; review its supported channels and precedence before combining management methods. [Apps update delivery][apps]

## 5. Approve Drivers and Firmware

1. Confirm the ring allows Windows drivers and that Settings Catalog does not exclude them.
2. Open **Windows updates > Driver updates > Create profile**. Start with manual approval for the pilot, or explicitly accept automatic approval of recommended drivers.
3. Assign one driver policy per device. Review the available inventory and approve selected updates with an availability date; then verify representative hardware before broader approval.
4. For automatic approval, configure **Make updates available after (days)**. This delay starts when the driver is added to the policy, not its OEM publication date. Other, nonrecommended drivers still need manual approval. [Driver configuration][driver-config]

The quality-update deferral does not delay drivers approved through driver policies; driver approval timing controls availability. Quality deadline/grace settings and ring user-experience settings still apply. Assignment filters are not supported. [Driver FAQ][driver-faq]

**Boundary:** Do not promise control of every driver installation. The FAQ describes exceptions for critical drivers during Autopilot and extension-class drivers. OEM tooling and recovery paths must be considered separately. [Driver FAQ][driver-faq]

Peter van der Woude's walkthrough corroborates the approval flow and explains why inventory/reporting is asynchronous. Its 2023 portal labels and prerequisite screenshots are historical; use current Learn requirements above. [MVP walkthrough][peter]

## 6. Verify Deployment and Investigate Failures

Use **Reports > Windows Updates > Reports > Windows Update Distribution Report** to inspect installed quality-update levels and drill into devices. It uses OS-version information from device check-in and is available even without quality policies. Compare its timestamps with local evidence. [Distribution report][distribution]

| Symptom | Check and next action |
|---|---|
| Ring succeeded but patch is missing | Ring status proves configuration delivery. Check Windows Update installation state, applicable update, restart requirement, and last check-in. [Troubleshooting][troubleshoot] |
| Device still uses WSUS or has conflicting settings | Inspect **Settings > Windows Update > Advanced options > Configured update policies**, then `gpresult` and the managing GPO/RMM/Configuration Manager policy. `MDMWinsOverGP` is not a general fix for Update CSP conflicts. [Troubleshooting][troubleshoot] |
| Feature update not offered | Check target applicability, safeguard hold, pause, residual deferral, and service enrollment. [Feature configuration][feature-config] |
| Driver remains pending | Check approval date, driver allowance, and overlapping approvals. A pause in one policy does not override approval in another. [Driver FAQ][driver-faq] |
| Resume selected but device stays paused | Inspect effective pause state on the device. Rudy Ooms documents historical stale pause values; investigate before adapting any registry remediation to current builds. [MVP investigation][rudy] |

For local servicing evidence, run this in an elevated Windows PowerShell session on an affected lab/pilot device:

```powershell
# Produces a local diagnostic snapshot; does not install updates.
Get-WindowsUpdateLog
```

The generated log is static: regenerate it after reproducing the failure. Review `%windir%\Logs\CBS\CBS.log` for installation failures and `C:\ProgramData\USOShared\Logs` for update orchestration evidence. Store logs privately and sanitize before sharing. [Windows Update logs][logs]

Verification checklist:

- [ ] Correct tenant, licenses, device ownership, and assignment groups recorded.
- [ ] Effective policy matches the intended ring and feature target.
- [ ] Installed OS build/update verified locally and reconciled with reporting.
- [ ] Required restart completed; business applications and hardware passed pilot checks.
- [ ] Failed, stale, offline, and inapplicable devices have assigned follow-up owners.
- [ ] Pause/resume and recovery decisions documented in the change record.

## 7. Pause, Recover, and Hand Over

Use the ring's **Pause** action for the affected update type while investigating; its maximum period is 35 days. Delivery is asynchronous, so devices may install before receiving the pause. Resume deliberately and verify client state. [Ring actions][rings]

**Uninstall** requests can cause immediate removal and a restart without user deferral. Feature rollback requires retained recovery files within the configured 2–60-day window; enablement-package updates do not support this ring uninstall method. Uninstall also pauses that update type, and it can reinstall when the pause ends. Deleting a ring does not restore earlier device settings. [Ring actions][rings]

For a faulty driver, pause further approval/deployment and use a tested OEM recovery procedure for affected hardware. Pausing does not remove an installed driver. [Driver configuration][driver-config]

During MSP handover, document the replacement policy owner and verify the new configuration on pilot devices before retiring the old management path. Removing a feature-policy assignment alone does not necessarily remove service enrollment; use Microsoft's documented transition path. [Feature management][features]

## 8. Corrections to the Supplied Infographic

The [original May 24, 2025 infographic](./images/Windows%20Patch%20Management%20Original%20Infographic.jpg), credited in the image to CloudEngineerHub, is retained as historical source material. It contains outdated or imprecise guidance and is not a deployment checklist.

| Original claim or implication | Reviewed conclusion |
|---|---|
| Cloud management requires no WSUS/SCCM | Correct for a cloud update source; existing co-management and GPO configuration still need review. [Overview][overview] |
| “Microsoft Update for Business” is a fourth update type | Incorrect categorization. Current documentation distinguishes Windows Update client policies and Windows Autopatch orchestration from feature, quality, and driver content. [Overview][overview] |
| A quality policy is a mandatory monthly-patching step | Incorrect; normal monthly servicing can use rings without one. [Quality management][quality] |
| Driver policies are “Preview” | Outdated label in this image; current configuration documentation does not label this policy preview. [Driver configuration][driver-config] |
| Windows 10/11 support is unqualified | Incomplete; edition lifecycle and Windows 10 ESU matter. [Lifecycle][lifecycle] |
| Maintenance hours prevent disruption | Incomplete; enforced restart deadlines can override active hours. [Deadlines][deadlines] |
| Reports show real-time compliance | Incorrect guarantee. Policy delivery and installed-update reporting are distinct; data arrives asynchronously. Endpoint Analytics is not a substitute for installation evidence. [Distribution report][distribution], [troubleshooting][troubleshoot] |
| Microsoft 365 Apps updates use a generic Apps > Update policy path | Replace with documented cloud update or Settings Catalog management. [Apps delivery][apps] |
| Entra join/hybrid join is required for every ring | Too broad; registered devices can use client policies/rings, but not the service-orchestrated policy types. [Overview][overview] |
| Autopatch means no operational ownership | Overstated; licensing, enrollment, application testing, monitoring, and incident response still require an owner. [Autopatch prerequisites][licensing] |

## Sources

Microsoft Learn is authoritative for supported configuration. MVP articles provide firsthand operational corroboration, not a guarantee that historical behavior applies to every current build. Links reviewed November 1, 2026.

- [Windows update management overview][overview]
- [Manage update rings][rings] and [ring settings][settings]
- [Windows Autopatch prerequisites and entitlements][licensing]
- [Manage feature updates][features] and [configure feature policies/migration][feature-config]
- [Manage quality updates][quality] and [expedite policies][expedite]
- [Configure driver policies][driver-config] and [driver FAQ][driver-faq]
- [Enforce update deadlines][deadlines]
- [Windows update distribution report][distribution]
- [Troubleshoot update rings][troubleshoot] and [Windows Update logs][logs]
- [Windows 10 lifecycle][lifecycle] and [commercial ESU activation][esu]
- [Choose Microsoft 365 Apps update delivery][apps]
- Microsoft MVP Peter van der Woude: [Getting started with Windows driver update management][peter] (July 17, 2023); [author credentials](https://petervanderwoude.nl/about/).
- Microsoft MVP Rudy Ooms: [Pause Update Rings: No Way Home][rudy] (January 28, 2022; updated November 20, 2024); [author's MVP account](https://call4cloud.nl/rudy-ooms-and-a-series-of-fortunate-events/).

[overview]: https://learn.microsoft.com/en-us/intune/device-updates/windows/
[rings]: https://learn.microsoft.com/en-us/intune/device-updates/windows/manage-update-rings
[settings]: https://learn.microsoft.com/en-us/intune/device-updates/windows/ref-update-ring-settings
[licensing]: https://learn.microsoft.com/en-us/windows/deployment/windows-autopatch/prepare/windows-autopatch-prerequisites
[features]: https://learn.microsoft.com/en-us/intune/device-updates/windows/manage-feature-updates
[feature-config]: https://learn.microsoft.com/en-us/intune/device-updates/windows/configure-feature-update-policy
[quality]: https://learn.microsoft.com/en-us/intune/device-updates/windows/manage-quality-updates
[expedite]: https://learn.microsoft.com/en-us/intune/device-updates/windows/configure-expedite-policy
[driver-config]: https://learn.microsoft.com/en-us/intune/device-updates/windows/configure-driver-update-policy
[driver-faq]: https://learn.microsoft.com/en-us/intune/device-updates/windows/driver-updates-faq
[deadlines]: https://learn.microsoft.com/en-us/windows/deployment/update/wufb-compliancedeadlines
[distribution]: https://learn.microsoft.com/en-us/intune/device-updates/windows/monitor-quality-updates
[troubleshoot]: https://learn.microsoft.com/en-us/troubleshoot/mem/intune/device-protection/troubleshoot-update-rings
[logs]: https://learn.microsoft.com/en-us/windows/deployment/update/windows-update-logs
[lifecycle]: https://learn.microsoft.com/en-us/lifecycle/announcements/windows-10-end-of-support
[esu]: https://learn.microsoft.com/en-us/windows/whats-new/enable-extended-security-updates
[apps]: https://learn.microsoft.com/en-us/microsoft-365-apps/updates/choose-how-to-deliver-updates
[peter]: https://petervanderwoude.nl/post/getting-started-with-windows-driver-update-management/
[rudy]: https://call4cloud.nl/windows-updates-paused-35-days-not-resuming/
