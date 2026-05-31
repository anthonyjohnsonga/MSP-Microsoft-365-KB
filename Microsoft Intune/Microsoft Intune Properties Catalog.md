# Microsoft Intune Properties Catalog
## Device Inventory, Resource Explorer, and Graph API Access

---

## Overview

The Properties Catalog is a custom inventory collection feature built into Microsoft Intune. It solves a common MSP challenge: Intune surfaces a lot of device information by default, but there are many specific data points from managed Windows devices that are not included in standard reports. The Properties Catalog fills that gap by letting you define exactly what additional hardware data you want collected -- and from which devices.

At its core, you are telling Intune: "When you check in with these devices, also collect these specific pieces of information."

This is an Intune core feature. No Intune Suite or add-on licensing is required to collect and view data.

---

## How It Works

The feature operates in two distinct parts:

**Part 1 -- Create the Properties Catalog Policy**

This defines what data you want collected and which devices to collect it from. This is the configuration step -- the instruction sheet. On its own, it does not display any data.

**Part 2 -- View the Collected Results**

Once the policy deploys and devices check in, the collected data becomes available in the Intune portal and via Microsoft Graph. Data collection can take up to 24 hours on initial deployment and refreshes on a 24-hour cycle thereafter.

---

## The WMI Connection

The Properties Catalog collects data through Windows Management Instrumentation (WMI) -- the backbone of Windows device data. WMI exposes thousands of hardware and software data points on any Windows machine, including:

- Hardware specs (BIOS version, TPM details, CPU info)
- Battery health and charge cycle counts
- Disk size and free space
- Network adapter configurations
- OS-level configuration values

Normally querying WMI would require running scripts manually or relying on a third-party RMM tool. The Properties Catalog enables this natively through Intune without any scripting.

---

## Device Requirements

Devices must meet the following criteria for the Properties Catalog to apply:

- Corporate owned
- Intune managed (includes co-managed devices)
- Microsoft Entra Hybrid joined or Microsoft Entra joined
- Running Windows 10 21H2 or Windows 11 21H2 minimum

---

## Creating a Properties Catalog Policy

1. In the Intune admin center, go to Devices and then Configuration.
2. Click + Create and select New Policy.
3. In the platform dropdown, select Windows 10 and later, then select Properties catalog as the profile type, and click Create.
4. Fill in a Name and Description, then click Next.
5. Click + Add Properties.
6. In the flyout, browse and select the WMI properties you want to retrieve. Selecting a top-level category automatically selects all sub-entries, or you can select individual properties. Selected items appear on the right side for review.
7. When finished, click Select and then click Next.
8. Assign Scope tags if required, then click Next.
9. Search for and select your target device group. Confirm it is set to Included and click Next.
10. Review the summary and click Create.

Note: If the Properties catalog profile type is not visible in your tenant, the feature has not yet been enabled for your tenant. It will appear once Microsoft's rollout reaches your tenant.

---

## Viewing the Collected Data

### Per-Device View (Current Method)

1. Sign into the Microsoft Intune admin center.
2. Go to Devices > By platform > Windows Devices.
3. Select a specific device.
4. Under the Monitor section, select Device Inventory or Resource Explorer (the label varies by tenant version).
5. Select a category to view the collected hardware properties.

Only properties selected in your Properties Catalog profile will be visible. Properties that were not included in the policy will not appear.

### Co-Managed Devices

For environments using co-management with tenant attach, two tabs are available:

- Device Inventory tab -- shows data collected by Intune
- Resource Explorer tab -- shows data collected by Configuration Manager

Microsoft recommends using the Intune-based Device Inventory going forward.

---

## Current Limitation for MSPs

At present, the data is per-device only. You must navigate to each device individually to view its collected properties. There is no native fleet-wide reporting view in the standard Intune portal without the Intune Suite add-on.

For fleet-wide querying across multiple devices, Microsoft Intune Advanced Analytics (available as part of the Intune Suite) supports multi-device queries using KQL, including the ability to use Copilot in Intune to build those queries.

However, there is a practical workaround using Microsoft Graph -- covered in the next section.

---

## Microsoft Graph API Access

The Properties Catalog inventory data is exposed via Microsoft Graph, and this does not require the Intune Suite. Any tenant with a standard Intune license can query this data programmatically.

### Per-Device Graph Endpoint

```
GET https://graph.microsoft.com/beta/deviceManagement/managedDevices('{DEVICE_ID}')/deviceInventories('{CATEGORY}')?$expand=instances($expand=Microsoft.Graph.deviceInventorySimpleItem/properties)
```

Replace `{DEVICE_ID}` with the Intune managed device ID, and `{CATEGORY}` with the category name you want to retrieve. Examples of category names include:

- `Cpu`
- `BiosInfo`
- `Battery`
- `Tpm`
- `LogicalDisk`
- `VideoController`
- `WindowsQfe`

Note: These endpoints are currently on the **beta** version of the Graph API, meaning they are subject to change. Avoid building production-critical automation against beta endpoints without a plan to accommodate breaking changes.

### Fleet-Wide Export via Export Jobs

For retrieving data across all devices without looping individually, the export jobs endpoint provides an alternative:

```
POST https://graph.microsoft.com/beta/deviceManagement/reports/exportJobs
```

Inventory-specific report names such as `InventoryPolicyDeviceAggregatesV3` are available through this endpoint and return results as a downloadable CSV.

### Discovering Graph Endpoints with Graph X-Ray

Graph X-Ray is a tool by Merill Fernando that captures the underlying Graph API calls made by the Intune portal as you navigate it. It is one of the most practical ways to discover undocumented or partially documented endpoints. Performing an action in the Intune portal while Graph X-Ray is active will reveal the exact API call being made, including parameters.

---

## Practical MSP Use Cases

### BIOS Version Audit

Before a firmware update rollout, verify every device in a client's fleet is on the expected BIOS version. Select BiosInfo properties in the catalog, assign the policy to the client's device group, then query via Graph or pull an export job CSV to compare versions across all devices.

### TPM Compliance Check

Quickly identify devices that do not have TPM 2.0 -- relevant for Windows 11 eligibility or security policy enforcement.

### Battery Health Monitoring

Track battery charge cycle counts and design capacity versus current capacity to proactively flag devices nearing end of useful battery life before users report problems.

### Hardware Refresh Planning

Collect disk size, available space, and memory details to build data-driven justification for device replacement cycles.

### Encryption Gap Identification

Identify devices that may be lacking disk encryption by reviewing logical disk properties as part of a compliance review.

---

## Building a Fleet-Wide Inventory Script (Concept)

With Microsoft Graph and a standard Intune license, you can build a PowerShell script or Power Automate flow that:

1. Authenticates to Microsoft Graph using an app registration with `DeviceManagementManagedDevices.Read.All` permission.
2. Retrieves the list of all managed devices in the client tenant.
3. Loops through each device and calls the deviceInventories endpoint for the desired category.
4. Aggregates the results into a report (CSV, Excel, or a database).

This gives you fleet-wide inventory reporting without the Intune Suite, at the cost of writing and maintaining the script yourself.

---

## Troubleshooting

### Error 2147749902

This error on the Properties Catalog profile deployment is commonly seen shortly after the policy is first assigned. It typically indicates the Device Inventory Agent has not yet been installed on the device. The agent is silently deployed via Intune's MDM stack, similar to how the Endpoint Privilege Management agent is installed.

In most cases the error self-resolves once the agent installs and data begins flowing. Agent logs are located at:

```
C:\Program Files\Microsoft Device Inventory Agent\Logs
```

Diagnostic logs can also be collected remotely using the Collect Diagnostics device action in the Intune portal.

### Data Not Appearing

- Confirm the policy is assigned to the correct group and the device is a member.
- Allow up to 24 hours for the initial data collection after the device checks in.
- Confirm the device meets the corporate-owned and join-type requirements listed above.
- Verify the properties you want to see were actually selected in the Properties Catalog profile -- only explicitly selected properties are collected.

---

## Summary

| Topic | Detail |
|---|---|
| License required | Intune P1 (core feature, no Suite needed) |
| Platforms supported | Windows (macOS, iOS, Android planned) |
| Data collection interval | Every 24 hours |
| Initial data delay | Up to 24 hours after first check-in |
| Per-device view location | Devices > Windows > [Device] > Monitor > Device Inventory / Resource Explorer |
| Graph API version | Beta |
| Fleet-wide reporting (native) | Requires Intune Suite (Advanced Analytics) |
| Fleet-wide reporting (DIY) | Possible via Graph API with standard license |
| Agent log location | C:\Program Files\Microsoft Device Inventory Agent\Logs |
