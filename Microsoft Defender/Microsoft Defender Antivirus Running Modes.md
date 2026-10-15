# Microsoft Defender Antivirus Running Modes

**Applies to:** Windows 11; Microsoft Defender Antivirus; Defender for Endpoint / Defender for Business  
**Scope:** Interpret AMRunningMode and Windows 11 protection capabilities.  
**Last Updated:** October 14, 2026

`AMRunningMode` is a property returned by `Get-MpComputerStatus`. It reports which mode Microsoft Defender Antivirus is running in, which in practice tells you **whether Defender is the primary AV** on the device.

```powershell
Get-MpComputerStatus | Select-Object AMRunningMode, AMServiceEnabled, AntivirusEnabled, RealTimeProtectionEnabled
```

> `AMRunningMode` does **not** tell you whether the device is onboarded to MDE. An onboarded device with Defender as its only AV reports `Normal`. See [MDE Onboarding via Intune](./Microsoft%20Defender%20for%20Endpoint%20Onboarding%20via%20Intune.md) for how to verify onboarding.

## AMRunningMode values

| Value | Meaning | When you'll see it | Requires MDE to reach this mode | Who remediates |
|---|---|---|---|---|
| **Normal** | Active mode. Defender is the primary AV. | Defender is the only/primary AV. Default on Windows 11. | No | Defender AV |
| **Passive** / **Passive mode** | Defender is installed and scanning but isn't the primary AV. | Automatic when a third-party AV registers with Windows Security Center and the device is onboarded. Also when Smart App Control is On or in Evaluation, even if not onboarded. | Yes (Smart App Control is the exception) | The third-party AV |
| **EDR Block Mode** | EDR in block mode is enabled. | EDR in block mode is turned on in the Defender portal (**Settings > Endpoints > General > Advanced features**). | Yes (MDE Plan 2) | EDR in block mode (post-breach) |
| **SxS Passive Mode** | Limited periodic scanning alongside another AV. | Third-party AV is primary, device isn't onboarded, and limited periodic scanning is enabled. | No | The third-party AV |

### Notes on the values

- **Passive spelling varies.** Microsoft's own docs show both `Passive` and `Passive mode`. Match with `-like '*Passive*'` in scripts.
- **EDR Block Mode:** the current Microsoft FAQ associates this output with passive Defender and EDR remediation. Active Defender reports `Normal`. Confirm the provider in **Windows Security > Virus & threat protection > Manage providers**. The `ForceDefenderPassiveMode` setting is documented for Windows Server; do not infer Windows 11 protection from an absent value.

### States without their own AMRunningMode value

| State | When it happens |
|---|---|
| **Disabled** | Third-party AV is primary, device **not** onboarded to MDE, Smart App Control Off. |
| **Hybrid mode** | Defender is primary, device **not** onboarded to MDE, Smart App Control On. |

Microsoft's docs don't specify what `AMRunningMode` reports in these states.

## Protection capabilities by mode

| Capability | Active (Normal) | Passive / EDR Block Mode (passive) | Disabled |
|---|---|---|---|
| Real-time protection | Yes | No AV blocking. Enabled for DLP functions only if Endpoint DLP is on. | No |
| Cloud-delivered protection | Yes | No | No |
| Network protection | Yes | No | No |
| Attack surface reduction rules | Yes | No | No |
| Controlled folder access | Yes | No | No |
| PUA protection | Yes | No | No |
| File scanning and detection reporting | Yes | Yes | No |
| Threat remediation | Yes | Only through EDR in block mode | No |
| Security intelligence updates | Yes (Defender schedulers apply) | Yes (Windows Update cadence only; Defender update schedulers are ignored) | No |
| Scheduled scans | Yes | Schedule ignored, but see note below | No |
| Web content filtering | Yes | Microsoft Edge only | No |
| Device control | Yes | Yes | No |
| Endpoint DLP | Yes | Yes | No |

**Scans in passive mode:** configured schedules are ignored, with policy-controlled exceptions:

- a catch-up quick scan at the default 30-day interval if "Turn on catch-up quick scan" is enabled,
- a quick scan after each security intelligence update ("Turn on scan after security intelligence update"),
- any existing Windows Task Scheduler scan tasks.

Review effective settings before changing scan policy; do not disable protection solely because Defender is passive.

> **Baseline impact:** ASR rules, network protection, cloud protection, CFA, and PUA protection do **not** enforce when Defender is passive. A security baseline that relies on ASR is not protecting a device whose primary AV is a third party.

**EDR requirements:** Microsoft documents MDE Plan 2 for EDR in block mode. Cloud-delivered protection must remain configured as enabled for this feature, even though passive mode does not provide normal cloud-backed antivirus enforcement.

## Microsoft guidance

Don't turn off real-time protection, cloud-delivered protection, or limited periodic scanning on devices in passive mode or using EDR in block mode. Don't disable or modify the `wscsvc`, `SecurityHealthService`, `Sense`, `WinDefend`, or `MsMpEng` services.

## Sources

- Microsoft Learn: [Antivirus compatibility and protection capabilities](https://learn.microsoft.com/en-us/defender-endpoint/microsoft-defender-antivirus-compatibility)
- Microsoft Learn: [Defender Antivirus in passive mode](https://learn.microsoft.com/en-us/defender-endpoint/microsoft-defender-passive-mode)
- Microsoft Learn: [EDR in block mode](https://learn.microsoft.com/en-us/defender-endpoint/edr-in-block-mode)
- Microsoft Learn: [EDR in block mode FAQ](https://learn.microsoft.com/en-us/defender-endpoint/edr-block-mode-faqs)
- Jeffrey Appel (Microsoft MVP): [Configure Defender AV / Next-generation protection](https://jeffreyappel.nl/microsoft-defender-for-endpoint-series-configure-av-next-generation-protection-part4/)

Sources reviewed October 14, 2026. Microsoft Learn governs current support and licensing; MVP guidance provides practical deployment context and can show older portal labels.
