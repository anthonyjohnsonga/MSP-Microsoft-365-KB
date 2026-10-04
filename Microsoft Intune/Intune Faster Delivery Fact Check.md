# Intune Faster Delivery Fact Check

**Applies to:** Microsoft Intune-managed Windows devices; service releases 2607-2609  
**Scope:** Claim-by-claim review of the preserved Intune Faster Delivery PDF against Microsoft documentation and firsthand MVP research  
**Last Updated:** October 4, 2026

## 1. Review Outcome

Read this review alongside [Intune Faster Delivery (PDF)](./Intune%20Faster%20Delivery.pdf) and the [troubleshooting companion](./Intune%20Delivery%20Troubleshooting%20Companion.md). The PDF remains unchanged, including its styling and October 1 review date.

The direction of travel is supported: more workloads respond to notifications or local changes. A notification starts work; it does not guarantee successful execution or immediate reporting. The PDF appropriately labels several claims as observations, but its historical Sync statement, universal eight-hour fallback, platform-script wording, and some timing promises need qualification.

This is a documentation and research review, not a tenant test. Source pages and client behavior can change after the review date. No minimum agent version or delivery-time SLA for these improvements should be inferred from a service-release number alone.

## 2. Detailed Claim Review

| PDF section / claim | Finding | Technician interpretation and evidence |
|---|---|---|
| 01: Earlier changes could queue behind WNS throttling | Supported as firsthand research | Rudy Ooms describes batching and notification throttling. It is evidence of observed implementation, not a Microsoft timing contract. [Fast-lane research](https://call4cloud.nl/the-truth-about-the-8-hour-intune-sync-and-why-its-a-myth/) |
| 01: Per-device fast lane gives each batch a delivery slot | Observed / evolving design | The research describes a per-device notification timer and planned changes. Do not present the mechanism as universally deployed or guaranteed across tenants. [Fast-lane research](https://call4cloud.nl/the-truth-about-the-8-hour-intune-sync-and-why-its-a-myth/) |
| 01: Without WNS, fallback is eight hours | Needs qualification | This matches the research's traditional OMA-DM example. The same article distinguishes another MMP-C maintenance cadence. Local sync, workload, enrollment age, and connectivity affect behavior; eight hours is not a universal fallback. [Fast-lane research](https://call4cloud.nl/the-truth-about-the-8-hour-intune-sync-and-why-its-a-myth/) |
| 02: Old remote actions queued about five minutes after initial enrollment; new actions bypass policy batching | Observed, not an SLA | Older client traces show queued alerts; newer research describes an immediate action lane. Offline devices and delivery failures still prevent action completion. [Queued-alert investigation](https://call4cloud.nl/pushlaunch-queued-schedule-created-for-queued-alerts/), [fast-lane research](https://call4cloud.nl/the-truth-about-the-8-hour-intune-sync-and-why-its-a-myth/) |
| 03: Before, Sync only woke MDM | Historically incomplete | This describes the older admin-center remote action. Company Portal already provided both check-ins. State which Sync interface and period are being compared. [IC3 investigation](https://patchmypc.com/blog/intune-on-demand-device-sync-now-uses-ic3-for-ime-workloads/) |
| 03: One Sync processes policies, apps and scripts; release 2607 | Confirmed, with execution caveat | Microsoft documents broader on-demand processing. Processing a workload does not override assignment, applicability, install scheduling, or script execution rules. [Release notes](https://learn.microsoft.com/en-us/intune/whats-new/), [Sync action](https://learn.microsoft.com/en-us/intune/device-management/actions/sync) |
| 03: WNS for MDM, IC3 for IME | Firsthand observation | Ooms captured the transport change in IME notification traces. Treat it as an implementation observation, rather than a prerequisite to force through registry edits. [IC3 investigation](https://patchmypc.com/blog/intune-on-demand-device-sync-now-uses-ic3-for-ime-workloads/) |
| 04: Device sync status shows progress | Confirmed; rollout note is dated | Microsoft documents the status tab. The 2609 release notes say the new device page is now the default and the old page is unavailable; the Sync article still mentions a preview toggle. Use the UI actually present in the customer tenant. [Sync action](https://learn.microsoft.com/en-us/intune/device-management/actions/sync), [release notes](https://learn.microsoft.com/en-us/intune/whats-new/) |
| 05: Win32 changes now initiate push; release 2609 | Confirmed; minutes and old hourly timer are not guarantees | Microsoft confirms push for admin/service changes, not a fixed completion time. The PDF's approximate timer should remain an observation and must not be confused with IME's documented general check-in interval. [Release notes](https://learn.microsoft.com/en-us/intune/whats-new/), [IME](https://learn.microsoft.com/en-us/intune/device-management/tools/management-extension-windows) |
| 06: Immediate assignment check after ESP or device preparation | Confirmed | The IME documentation explicitly covers both provisioning flows. Assignment discovery does not mean all remaining apps immediately install. [IME](https://learn.microsoft.com/en-us/intune/device-management/tools/management-extension-windows) |
| 07: Custom discovery runs eight-hourly or on Check compliance | Confirmed, with important distinction | Check compliance runs the downloaded script without retrieving an updated script at that moment. Microsoft also says push cannot trigger this workload on demand. [Custom compliance](https://learn.microsoft.com/en-us/intune/device-security/compliance/custom-settings) |
| 07: Hourly custom compliance in newer clients | Experimental client evidence | Ooms found scheduling plumbing in IME 1.103.101.0. That is not proof of an enabled hourly feature on every client. Continue using the documented behavior for support expectations. [Custom-compliance research](https://call4cloud.nl/intune-custom-compliance-could-move-beyond-the-8-hour-wait/) |
| 08: Client-driven compliance for listed security signals | Core behavior confirmed; throttling details unverified | Microsoft lists firewall, antivirus, BitLocker, Defender status, OS build, real-time protection, and Secure Boot. A precise throttle interval was not established in the reviewed Microsoft pages. Custom compliance retains its separate documented limitations. [Release notes](https://learn.microsoft.com/en-us/intune/whats-new/), [custom compliance](https://learn.microsoft.com/en-us/intune/device-security/compliance/custom-settings) |
| 09: Four-hour baseline, five-minute event upload, cooldowns | Supported as a lab capture | The inventory investigation shows a successful upload roughly five minutes after detecting an app change, plus cooldowns. That does not establish when the portal renders the record. [Inventory research](https://patchmypc.com/blog/intune-app-inventory-from-four-hours-to-about-five-minutes/) |
| 09: App inventory needs a Properties catalog policy | Confirmed | Enable ApplicationProperties and inspect the device's All Apps > App Inventory view. This is separate from legacy Discovered apps. [App inventory](https://learn.microsoft.com/en-us/intune/app-management/deployment/enhanced-app-inventory) |
| Under the hood: WNS wildcards and regional Trouter on TCP 443 | Confirmed endpoints; incomplete firewall checklist | The endpoints are documented, but the full Intune, identity, content, and applicable attestation requirements also matter. Use Microsoft's current endpoint tables for the tenant cloud and region. [Network endpoints](https://learn.microsoft.com/en-us/intune/fundamentals/endpoints) |
| Under the hood: Platform scripts run on timer or manual Sync | Misleading if interpreted as recurring execution | Retrieval/processing and execution differ. Successful platform scripts do not rerun solely because Sync is selected; script or policy changes and documented context/retry rules matter. Use Remediations for scheduled recurring work, subject to licensing. [Platform scripts](https://learn.microsoft.com/en-us/intune/device-management/tools/run-powershell-scripts-windows) |

## 3. Operational Recommendations

1. Retain the PDF as a dated visual reference and use this review for qualifications.
2. Measure notification arrival, workload processing, result upload, and portal reporting separately.
3. Validate changes on a pilot device in each customer tenant; record agent version and network path.
4. Troubleshoot with the [companion](./Intune%20Delivery%20Troubleshooting%20Companion.md) before changing assignments or agent state.

## Sources

- Microsoft Learn: [What's new in Intune](https://learn.microsoft.com/en-us/intune/whats-new/)
- Microsoft Learn: [Sync device action](https://learn.microsoft.com/en-us/intune/device-management/actions/sync)
- Microsoft Learn: [Intune Management Extension](https://learn.microsoft.com/en-us/intune/device-management/tools/management-extension-windows)
- Microsoft Learn: [Custom compliance](https://learn.microsoft.com/en-us/intune/device-security/compliance/custom-settings)
- Microsoft Learn: [App inventory](https://learn.microsoft.com/en-us/intune/app-management/deployment/enhanced-app-inventory)
- Microsoft Learn: [Network endpoints](https://learn.microsoft.com/en-us/intune/fundamentals/endpoints)
- Microsoft Learn: [Windows PowerShell platform scripts](https://learn.microsoft.com/en-us/intune/device-management/tools/run-powershell-scripts-windows)
- Rudy Ooms, Call4Cloud: [Policy notification and fast-lane research](https://call4cloud.nl/the-truth-about-the-8-hour-intune-sync-and-why-its-a-myth/)
- Rudy Ooms, Call4Cloud: [Queued remote-action alerts](https://call4cloud.nl/pushlaunch-queued-schedule-created-for-queued-alerts/)
- Rudy Ooms, Call4Cloud: [Custom compliance scheduling research](https://call4cloud.nl/intune-custom-compliance-could-move-beyond-the-8-hour-wait/)
- Rudy Ooms, Patch My PC: [IC3 Sync investigation](https://patchmypc.com/blog/intune-on-demand-device-sync-now-uses-ic3-for-ime-workloads/)
- Rudy Ooms, Patch My PC: [App inventory timing investigation](https://patchmypc.com/blog/intune-app-inventory-from-four-hours-to-about-five-minutes/)
