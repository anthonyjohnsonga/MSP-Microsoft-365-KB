# Part 4 - Windows Diagnostic Data

*Part 4 of the [Intune Zero to Hero](./README.md) series.*

---

## Summary

Windows diagnostic data is telemetry that enrolled Windows devices send back to Microsoft describing update deployment progress, Delivery Optimization usage, and Windows Update client policy configuration. Several Intune reporting and alerting features depend on Intune having tenant-level access to this data, and by default that access is **off** and must be explicitly enabled. This part enables the toggle and reviews the adjacent **Windows license verification** attestation.

This is a **tenant-level configuration toggle**, separate from the diagnostic data level (Required/Enhanced/Optional) configured on the devices themselves. Enabling it in Intune tells Intune it's authorized to consume the diagnostic data devices are already sending to Microsoft; it does not, by itself, change what data a device collects or sends.

---

## Prerequisites

- **Intune Administrator** (or higher) to configure Windows data settings.
- For the dependent reports to populate, devices must be **Microsoft Entra joined** (or hybrid joined) and sending diagnostic data at the **Required** level or higher — see Notes.

---

## What It Unlocks

Turning this setting on enables several reporting and alerting features in Intune that would otherwise be unavailable:

- **Compatibility reports for Windows updates** — flags devices with driver or app compatibility issues before a feature update is deployed to them.
- **Reports for expedite policies** — shows deployment progress and status for expedited quality updates.
- **Driver update policies with failure alerts** — notifies admins when a driver update policy fails on enrolled devices.
- **Expedited quality update policies with failure alerts** — notifies admins when an expedited quality update fails.
- **Feature update policies with failure alerts** — notifies admins when a feature update deployment fails.

Turning the setting **off** disables these Intune features, but note that it does not necessarily disable diagnostic data processor configuration that was enabled through other methods (such as Group Policy or a separate MDM policy).

---

## Configuration

**Path:** [Intune admin center](https://intune.microsoft.com/) → **Tenant administration > Connectors and tokens > Windows data**

### Enable features that require Windows diagnostic data in processor configuration

**Set to: On**

1. Sign in to the [Intune admin center](https://intune.microsoft.com/).
2. Go to **Tenant administration > Connectors and tokens > Windows data**.
3. Toggle **Enable features that require Windows diagnostic data in processor configuration** to **On**.

### Windows license verification

While in this same **Windows data** blade, review the adjacent **Windows license verification** toggle. It's a separate attestation — confirming the tenant owns an eligible license such as Windows Enterprise E3/E5 or Microsoft 365 F3/E3/E5 — required by a couple of the same reporting features, including compatibility reports and Remediations. It confirms tenant entitlement only; it does not validate or assign licenses to individual devices. _(See the Business Premium flag in Notes.)_

---

## How the Collected Data Is Used

The diagnostic data itself doesn't just get switched on and disappear into a black box — depending on which service consumes it, it surfaces in a few different places:

- **Directly in Intune**, populating the compatibility and expedite-policy reports and driver/update failure alerts listed above, viewable under **Reports** and within the respective update policy blades.
- **In Windows Update for Business reports**, a related Azure-hosted service that ingests the same class of Windows client diagnostic data into an Azure Log Analytics workspace you own. This lets you build custom Kusto (KQL) queries and dashboards on top of tables like update deployment status, Delivery Optimization status, and per-device readiness assessments. Data typically takes 48–72 hours to first appear after a device is configured, and the dataset refreshes daily.
- **In the Microsoft 365 admin center's Software updates page**, which shows a high-level rollup of Windows update compliance across the org, also sourced from this diagnostic pipeline.

---

## Notes

- **License verification and Business Premium:** the eligible licenses for the license verification attestation are Windows Enterprise E3/E5 or Microsoft 365 F3/E3/E5, Windows Education A3/A5 or Microsoft 365 A3/A5, and Windows VDA E3/E5. **Microsoft 365 Business Premium is not on the list**, so in a Business Premium-only tenant (this series' baseline, per [Part 1](./Part%201%20-%20Licensing.md)) the features gated on the attestation — compatibility reports and Remediations — are unavailable. The diagnostic data toggle itself has no such license gate; the update failure alerts and expedite reports still work. See [Enable Windows diagnostic data and license verification](https://learn.microsoft.com/intune/privacy/enable-windows-diagnostic-data).
- **Minimum diagnostic data level:** devices must be sending diagnostic data at least at the **Required** level for Windows Update for Business reports to work; **Enhanced** (Windows 10) or **Optional** (Windows 11) is recommended for more complete data.
- **Device names in reports:** device names won't appear in reports by default — a separate policy (**Allow device name to be sent in Windows diagnostic data**) must be enabled, or devices show up as `#` instead of a name.
- **Related settings that are not the same thing:**
  - **Endpoint analytics data collection** (Reports > Endpoint analytics > Settings) — a related but distinct data collection policy that governs data used for Endpoint analytics scoring, not Windows Update reporting.
  - **Device diagnostics** (Tenant administration > Device diagnostics) — governs the ability to remotely collect a diagnostics package (logs) from an individual device on demand; unrelated to the tenant-wide Windows diagnostic data processor configuration covered in this part.

---

← **Previous:** [Part 3 - Intune Enrollment Configuration](./Part%203%20-%20Intune%20Enrollment%20Configuration.md)

*[Intune Zero to Hero](./README.md) series · [Microsoft Intune](../README.md) · [Root index](../../README.md)*
