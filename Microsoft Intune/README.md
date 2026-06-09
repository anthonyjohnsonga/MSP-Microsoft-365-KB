# Microsoft Intune

This folder contains reference guides for managing devices, policies, and inventory using Microsoft Intune in an MSP environment.

---

### [Microsoft Intune Properties Catalog](./Microsoft%20Intune%20Properties%20Catalog.md)

A reference guide covering the Properties Catalog feature in Microsoft Intune — a native WMI-based device inventory collection tool that requires no Intune Suite add-on. Covers how to create a Properties Catalog policy, view collected data per device via Resource Explorer, and access inventory data fleet-wide using the Microsoft Graph API (beta). Includes practical MSP use cases (BIOS audits, TPM checks, battery health, hardware refresh planning), a fleet-wide script concept using Graph, and troubleshooting guidance for Error 2147749902 and missing data scenarios.

---

### [Microsoft Windows 11 Hotpatch Notes](./Microsoft%20Windows%2011%20Hotpatch%20Notes.md)

Reference notes covering Windows 11 Hotpatch — a feature that applies quality updates in-memory without requiring a reboot. Explains the baseline vs hotpatch update schedule (4 reboot months, 8 rebootless months per year), device prerequisites (Windows 11 24H2, VBS, HVCI), and the two Intune policies required to enable it: a Settings Catalog policy for Virtualization Based Security and a Windows Quality Update policy via Windows Update for Business.

---

### [Microsoft Intune Google Chrome Disable Password Manager](./Microsoft%20Intune%20Google%20Chrome%20Disable%20Password%20Manager.md)

Step-by-step guide for deploying a Settings Catalog policy that disables Google Chrome's built-in password manager via Intune. Covers policy details, configuration steps, and notes on behavior — including that existing saved passwords are not deleted, Chrome Sync is unaffected, and the policy maps to the `PasswordManagerEnabled` Chrome GPO setting.
