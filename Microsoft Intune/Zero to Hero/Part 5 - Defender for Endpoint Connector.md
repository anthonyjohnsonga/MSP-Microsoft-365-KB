# Part 5 - Defender for Endpoint Connector

*Part 5 of the [Intune Zero to Hero](./README.md) series.*

---

## Summary

The Defender–Intune connector is the service-to-service connection that lets Microsoft Defender (Defender for Business, in this series' Business Premium baseline) and Microsoft Intune share device and security data. Once connected, Windows devices enrolled in Intune can be automatically onboarded to Defender for endpoint protection, and Intune can consume Defender's device risk signal when evaluating compliance policies.

This part follows the **setup wizard flow**, which triggers the first time the Microsoft Defender portal (**Assets → Devices**) is opened for a tenant that hasn't been provisioned yet — the flow commonly seen with Defender for Business or Microsoft 365 Business Premium tenants. Larger tenants on full Defender for Endpoint Plan 1/2 connect the two services through a slightly different path; see Notes.

---

## Prerequisites

- **Global Administrator** or **Security Administrator** role (Microsoft Entra ID) to sign in to the Defender portal.
- **Endpoint Security Manager** role in Intune (or a custom role with Read/Modify rights on *Mobile Threat Defense* settings) to configure the connector on the Intune side.
- Devices already enrolled in Intune, if you intend to onboard them via the "all devices enrolled" option in the wizard — see [Part 3](./Part%203%20-%20Intune%20Enrollment%20Configuration.md).

---

## Setup

The wizard-driven flow provisions Defender for Business, onboards Windows devices, and hands security-settings management back to Intune.

### 1. Sign in to the Microsoft Defender portal

Sign in to the [Microsoft Defender portal](https://security.microsoft.com) as a Global Administrator or Security Administrator.

### 2. Trigger provisioning

Navigate to **Assets → Devices**. If Defender for Business hasn't been provisioned yet for the tenant, this action begins provisioning automatically and presents the setup wizard.

### 3. Complete or dismiss the setup wizard

Work through the wizard, or dismiss it if you'd rather configure settings manually afterward. The wizard walks through assigning security-team permissions, setting up email notifications, onboarding Windows devices, and configuring baseline security policies.

### 4. Onboard Windows devices

In the **Add Windows devices** step, select **All devices (recommended)**. This enables automatic onboarding so that any Windows device enrolled in Intune — now or in the future — is onboarded to Defender for Business without needing to be onboarded manually.

### 5. Choose where to manage security settings

Under **Apply security settings**, select **Continue using Intune**. Because this tenant already manages devices through Intune (per the earlier parts of this series), this keeps Intune as the primary console for policy management rather than switching to the simplified configuration experience inside the Defender portal.

### 6. Enable the compliance policy evaluation toggle in Intune

Go to the [Intune admin center](https://intune.microsoft.com/) → **Endpoint security** → **Setup** section → **Microsoft Defender for Endpoint**.

Under **Compliance policy evaluation**, turn on:

> **Connect Windows devices version 10.0.15063 and above to Microsoft Defender for Endpoint**

Select **Save**.

---

## Verify the Connector Status

Go to **Endpoint security → Overview** in the Intune admin center. Under the **Defender for Endpoint Connector status** tile, wait for the green check mark confirming the connection is active.

> **Note:** Connection status can take up to 15 minutes to update after saving. If it doesn't appear after a reasonable wait, confirm your account has the correct permissions in both Intune and the Defender portal, and that the toggle in Step 6 was saved successfully.

---

## After the Connector Is Active

Once the connector shows as connected, a few things become available worth setting up next:

- **Onboarding status** — Endpoint security → Overview also shows a "Windows devices onboarded to Microsoft Defender for Endpoint" count, so you can track onboarding progress across the tenant.
- **Compliance policies** — you can now create Windows compliance policies that use **Require the device to be at or under the Device Threat Level** as a rule, driven by Defender's risk signal.
- **Conditional Access** — the device risk level from Defender can be layered into Conditional Access policies to block access from devices Defender considers risky.

---

## Notes

- **Which Defender product this applies to:** the wizard-driven flow here (Assets → Devices provisioning, "Add Windows devices," "Apply security settings") is specific to **Microsoft Defender for Business** (standalone or via Microsoft 365 Business Premium) — the flow common in SMB/MSP-managed tenants and the baseline for this series.
- **Full Defender for Endpoint Plan 1/2 (e.g., Microsoft 365 E5):** larger tenants connect the two services manually instead of through the wizard: **Defender portal → System → Settings → Endpoints → General → Advanced features → Microsoft Intune connection (toggle On) → Save preferences**. Both paths result in the same underlying service-to-service connection and the same verification step in Intune (Endpoint security → Overview), but the setup experience and available wizard steps differ. Confirm which Defender plan a client tenant is on before following this guide verbatim. See [Configure Microsoft Defender for Endpoint in Intune](https://learn.microsoft.com/intune/device-security/microsoft-defender/configure-integration).
- **Compliance-side follow-up:** enabling the connector only establishes the data pipe. The device threat level is not enforced until a compliance policy actually uses the **Require the device to be at or under the Device Threat Level** rule and that policy is assigned.

---

← **Previous:** [Part 4 - Windows Diagnostic Data](./Part%204%20-%20Windows%20Diagnostic%20Data.md)

*[Intune Zero to Hero](./README.md) series · [Microsoft Intune](../README.md) · [Root index](../../README.md)*
