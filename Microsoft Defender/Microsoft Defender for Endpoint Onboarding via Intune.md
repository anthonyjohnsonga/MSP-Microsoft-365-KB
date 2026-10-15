# Microsoft Defender for Endpoint Onboarding via Intune

**Applies to:** Windows 11; Microsoft Defender Antivirus; Defender for Endpoint / Defender for Business  
**Scope:** Onboard Intune-managed Windows 11 devices and verify sensor reporting.  
**Last Updated:** October 14, 2026

## Prerequisites and licensing

Use a supported Windows 11 edition enrolled in Intune, an Intune entitlement, and an eligible Defender subscription. MDE Plan 1 supports onboarding but does not include the full EDR feature set of Plan 2; Defender for Business includes EDR. Use Security Administrator for Defender setup and Intune permissions to manage the connector and endpoint security policies. Run local diagnostics elevated.

**MSP note:** confirm the customer tenant in both portals and pilot assignments before broad deployment. Onboarding packages are tenant-specific; never publish their contents.

## Three separate layers

Defender AV, Intune policy, and MDE are independent. A device can have any combination of them.

| Layer | What it is | How it gets on the device |
|---|---|---|
| **Defender Antivirus** | The built-in AV engine (`MsMpEng.exe`) | Ships with Windows 11. Runs in active mode by default with no management. |
| **Intune antivirus policy** | Configuration *for* Defender AV: real-time protection, cloud protection, exclusions, ASR rules, etc. | Endpoint security > Antivirus / Attack surface reduction in Intune |
| **MDE (Defender for Endpoint)** | The EDR sensor (`Sense` service), the Defender portal, passive mode, EDR in block mode | Onboarding via an Intune EDR policy. Requires MDE P1/P2 or Defender for Business. |

Common misreadings:

- **No Intune Defender policy ≠ no Defender.** Defender AV still runs with default settings; it just isn't centrally managed.
- **Intune antivirus policy ≠ MDE.** AV policies configure the engine. An **EDR policy** is the method covered here; other supported onboarding methods also exist.
- **License ≠ onboarded.** Business Premium includes Defender for Business, but devices aren't in MDE until you deploy an EDR policy or turn on automatic onboarding.
- **Onboarded devices still show `Normal`.** If Defender is the only AV, an onboarded device reports `AMRunningMode = Normal`. That's the ideal state: active AV plus EDR.

## 1. Onboard Through Intune

On supported Windows 11 editions, Intune normally does not install the sensor. The `Sense` service and its binaries are built into Windows 11, activated through onboarding. Windows Home-to-Pro upgrades can require installation of the Sense capability first; see the CSP source. Intune delivers the **onboarding configuration** that activates it.

1. **Enable the connector on both sides.**
   - Defender portal: **Settings > Endpoints > General > Advanced features > Microsoft Intune connection**
   - Intune: **Tenant administration > Connectors and tokens > Microsoft Defender for Endpoint**
2. **Deploy an EDR policy.** **Endpoint security > Endpoint detection and response > Create Policy**, using platform **Windows** and profile **Endpoint detection and response**, with the configuration package type set to **Auto from connector**. The policy carries the tenant's onboarding blob.
3. **CSP delivery.** Intune writes the blob through the **WindowsAdvancedThreatProtection CSP** (`Onboarding` node). Configure sample sharing as required. The CSP documents telemetry reporting frequency, but that legacy setting is deprecated in the Intune profile; do not add it to a new policy.
4. **Sensor activation.** Windows starts the `Sense` service, sets `OnboardingState` to `1`, and the device registers in the Defender portal.

## 2. Verify Onboarding

An EDR policy showing **Success** in Intune means the onboarding configuration was delivered and applied. It doesn't prove the sensor is reporting. Verify all three:

| Check | Expected |
|---|---|
| `Get-Service Sense` | `Running` |
| `OnboardingState` registry value | `1` |
| Defender portal > Assets > Devices | Device listed as **Onboarded** with a recent last device update |

```powershell
Get-Service Sense
Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows Advanced Threat Protection\Status' -Name OnboardingState
```

### Combined status check

Run elevated Windows PowerShell for this read-only spot check. Intune Remediations also requires explicit compliance logic and exit codes; this example only outputs status. Missing values can indicate read errors or sensor problems.

```powershell
[pscustomobject]@{
    AMRunningMode            = (Get-MpComputerStatus).AMRunningMode
    SenseStatus              = (Get-Service Sense -ErrorAction SilentlyContinue).Status
    OnboardingState          = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows Advanced Threat Protection\Status' -ErrorAction SilentlyContinue).OnboardingState
    ForceDefenderPassiveMode = (Get-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Advanced Threat Protection' -ErrorAction SilentlyContinue).ForceDefenderPassiveMode
}
```

### Reading the result

| AMRunningMode | Sense | OnboardingState | Interpretation |
|---|---|---|---|
| Normal | Running | 1 | Ideal: Defender is primary AV and onboarded to MDE |
| Normal | Stopped / missing | 0 / missing | Defender active; investigate onboarding and sensor health (a stopped sensor alone does not prove offboarding) |
| *Passive* | Running | 1 | Third-party AV is primary; Defender passive, onboarded |
| *Passive* | Stopped / missing | 0 / missing | Likely Smart App Control-driven passive mode on a device not onboarded |
| EDR Block Mode | Running | 1 | Passive Defender with EDR remediation; confirm the Security Center provider and portal health |
| SxS Passive Mode | Stopped / missing | 0 / missing | Third-party AV primary, not onboarded, limited periodic scanning on |

## Related Guide and Offboarding

For the Defender for Business wizard, see [Intune Zero to Hero Part 5 - Defender for Endpoint Connector](../Microsoft%20Intune/Zero%20to%20Hero/Part%205%20-%20Defender%20for%20Endpoint%20Connector.md).

Removing an onboarding assignment does not offboard a device. To reverse deployment, remove conflicting onboarding assignments and deploy the supported offboarding package. Confirm primary antivirus protection remains in place.
## Sources

- Microsoft Learn: [Deploy EDR policy with Intune](https://learn.microsoft.com/en-us/intune/device-configuration/endpoint-security/deploy-edr)
- Microsoft Learn: [Configure Defender for Endpoint with Intune](https://learn.microsoft.com/en-us/intune/device-security/microsoft-defender/configure-integration)
- Microsoft Learn: [WindowsAdvancedThreatProtection CSP](https://learn.microsoft.com/en-us/windows/client-management/mdm/windowsadvancedthreatprotection-csp)
- Microsoft Learn: [Onboard devices to Defender for Business](https://learn.microsoft.com/en-us/defender-business/mdb-onboard-devices)
- Jeffrey Appel (Microsoft MVP): [Onboard using Microsoft Intune](https://jeffreyappel.nl/microsoft-defender-for-endpoint-series-onboard-using-microsoft-intune-part3a/)

Sources reviewed October 14, 2026. Microsoft Learn governs current support and licensing; MVP guidance provides practical deployment context and can show older portal labels.
