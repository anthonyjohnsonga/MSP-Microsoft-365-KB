# Microsoft Defender Antivirus Passive Mode Troubleshooting

**Applies to:** Windows 11; Microsoft Defender Antivirus; Defender for Endpoint / Defender for Business  
**Scope:** Diagnose Windows 11 passive mode and third-party antivirus coexistence.  
**Last Updated:** October 14, 2026

## Requirements for passive mode

- Windows 11 with Defender Antivirus installed.
- A non-Microsoft AV installed and used as the primary AV (with MDE added to its exclusion list).
- Onboarded to Defender for Endpoint.
- **Windows Security Center service enabled.**

On Windows 11, Defender switches to passive automatically once these are met. There's nothing to configure on the device.

## What happens with a third-party AV

| Onboarded to MDE | Smart App Control | Defender state |
|---|---|---|
| Yes | Any | **Passive** |
| No | On or Evaluation | **Passive**. Microsoft notes this is not the same as MDE passive mode. |
| No | Off | **Disabled** |

If the third-party AV expires, is uninstalled, or stops providing real-time protection, Defender re-enables automatically.

## Troubleshooting

| Symptom | Likely cause | What to check |
|---|---|---|
| Device with a third-party AV stays `Normal` | Windows Security Center service is disabled, so Defender can't detect the other AV. Two AVs enforcing at once is **unsupported**. | `Get-Service wscsvc`; Windows Security > Virus & threat protection > Manage providers |
| Device shows passive but the old AV was removed | Leftover Security Center registration from the old AV | Manage providers list in Windows Security |
| Device shows passive but isn't onboarded to MDE | Smart App Control is On or in Evaluation | Smart App Control state in Windows Security > App & browser control |
| Device reports `EDR Block Mode` and you need to know if it's active | `AMRunningMode` alone can't tell you | Current Microsoft FAQ: active Defender reports `Normal`; confirm the Security Center provider |
| `EDR Block Mode` reported but portal shows unsupported/not updated | `AMRunningMode` alone isn't proof of health | Confirm `Sense` is running and the device shows recent activity in the Defender portal |
| Intune EDR policy shows Success but device isn't in the Defender portal | Policy applied but sensor isn't reporting | `Get-Service Sense`, `OnboardingState`, connector status on both sides |
| Defender came back on after a third-party AV expired | Expected. Defender re-enables automatically when the other AV stops providing real-time protection. | Confirm intended primary AV |
| ASR rules not enforcing on a device | Defender is passive. ASR, network protection, cloud protection, CFA, and PUA don't enforce in passive mode. | `AMRunningMode`; which AV is primary |

**MSP note:** confirm the intended antivirus provider and feature entitlement per customer tenant. Microsoft documents Plan 2 for EDR in block mode; passive mode alone does not provide antivirus remediation. Use vendor-supported cleanup for stale antivirus registration. Do not apply server registry instructions to force Windows 11 mode changes.

## Sources

- Microsoft Learn: [Antivirus compatibility and protection capabilities](https://learn.microsoft.com/en-us/defender-endpoint/microsoft-defender-antivirus-compatibility)
- Microsoft Learn: [Defender Antivirus in passive mode](https://learn.microsoft.com/en-us/defender-endpoint/microsoft-defender-passive-mode)
- Microsoft Learn: [EDR in block mode](https://learn.microsoft.com/en-us/defender-endpoint/edr-in-block-mode)
- Microsoft Learn: [EDR in block mode FAQ](https://learn.microsoft.com/en-us/defender-endpoint/edr-block-mode-faqs)
- Jeffrey Appel (Microsoft MVP): [Configure Defender AV / Next-generation protection](https://jeffreyappel.nl/microsoft-defender-for-endpoint-series-configure-av-next-generation-protection-part4/)

Sources reviewed October 14, 2026. Microsoft Learn governs current support and licensing; MVP guidance provides practical deployment context and can show older portal labels.
