# Microsoft Windows

Reference materials for Windows client servicing, security, recovery, and deployment in MSP-managed environments.

---

### [Windows 11 26H2 Fact Checked (PDF)](./Windows%2011%2026H2%20Fact%20Checked.pdf)

**Applies to:** Windows 11, version 26H2  
**Scope:** One-page release and deployment reference for MSP technicians  
**Last Updated:** October 4, 2026

A visual summary of the September 2026 feature update, enablement-package delivery, support lifecycle, commercial features enabled by default, security and recovery improvements, user experience changes, driver trust changes, and WMIC removal. The File History card reflects the fix included in September 22, 2026 and later updates.

Before deployment, verify device eligibility, licensing and policy requirements for the features you plan to use, current safeguard holds, and release-health notices. Validate in a pilot ring for each customer tenant and confirm backups and recovery options before broad rollout.

---

### [Windows AppSwitched Registry Investigation Guide](./Windows%20AppSwitched%20Registry%20Investigation%20Guide.md)

**Applies to:** Windows 10 version 1903 and later; Windows 11<br>
**Scope:** Inspect per-user taskbar counters and correlate account activity during endpoint investigations<br>
**Last Updated:** October 2026

Account and hive identification, current-user and offline inspection, checked hive loading and cleanup, interpretation limits, verification, and troubleshooting. Includes MSP session-context and evidence-preservation guidance.

### [Windows Hello PIN Reset Guide](./Windows%20Hello%20PIN%20Reset%20Guide.md)

**Applies to:** Windows 11; Windows Hello and Windows Hello for Business<br>
**Scope:** Reset PIN enrollment and recover with manual NGC-folder removal when needed<br>
**Last Updated:** October 2026

Built-in PIN reset, affected-user container deletion, a field-tested NGC recovery fallback, credential and passkey impact, reprovisioning, and verification. Includes shared-device precautions and recovery limitations.

---

### [Windows Taskbar Flashing and Foreground Behavior Guide](./Windows%20Taskbar%20Flashing%20and%20Foreground%20Behavior%20Guide.md)

**Applies to:** Windows 11; Windows 10 under an applicable support arrangement<br>
**Scope:** Adjust per-user taskbar attention flashing and foreground lock behavior<br>
**Last Updated:** October 2026

Windows taskbar settings and a targeted registry workaround using `ForegroundFlashCount` and `ForegroundLockTimeout`. Includes symptom identification, original-value backup, focus-impact testing, rollback, and MSP user-context guidance.

---

### [Install Windows Updates with PowerShell](./Install%20Windows%20Updates%20with%20PowerShell.md)

**Applies to:** Windows 11; Windows 10 under an applicable support arrangement; Windows PowerShell 5.1<br>
**Scope:** Install approved updates locally with PSWindowsUpdate<br>
**Last Updated:** October 2026

Module preparation, session-scoped execution policy, update-source selection, review before installation, explicit restart handling, verification, recovery, and managed-update caveats.

---

### Windows Wireless Profiles Series

**Applies to:** Windows 11; Windows 10 under an applicable support arrangement<br>
**Scope:** Identify saved wireless profiles, then inspect an authorized profile's saved shared key<br>
**Last Updated:** October 2026

1. [Part 1 - List Saved Profiles](./Windows%20Wireless%20Profiles%20-%20Part%201%20-%20List%20Saved%20Profiles.md) — List profiles, identify the correct interface and profile name, and review authentication settings.
2. [Part 2 - View a Saved Wi-Fi Password](./Windows%20Wireless%20Profiles%20-%20Part%202%20-%20View%20a%20Saved%20Wi-Fi%20Password.md) — Inspect one saved shared key with elevation, credential handling, and enterprise authentication limitations.

---

### [Repair a Workstation Domain Trust Relationship](./Repair%20a%20Workstation%20Domain%20Trust%20Relationship.md)

**Applies to:** AD domain-joined Windows workstations; Windows PowerShell 5.1<br>
**Scope:** Diagnose and repair a workstation secure channel without first removing and rejoining the domain<br>
**Last Updated:** October 2026

Local administrator access, delegated domain credentials, DNS/DC connectivity checks, test-before-repair flow, alternative machine-password reset, restart, and verification. Excludes domain controllers and Entra-only devices.

---

## Sources

- [What's new in Windows 11, version 26H2](https://learn.microsoft.com/en-us/windows/whats-new/whats-new-windows-11-version-26h2)
- [Windows 11, version 26H2 update history](https://support.microsoft.com/en-au/servicing/os/windows-11/2026/09/windows-11-version-26h2-update-history)
- [Windows 11, version 26H2 known issues and notifications](https://learn.microsoft.com/en-us/windows/release-health/status-windows-11-26h2)
- [Windows 11 release information](https://learn.microsoft.com/en-us/windows/release-health/windows11-release-information)
