# Part 2 - Microsoft Entra Device Settings

*Part 2 of the [Intune Zero to Hero](./README.md) series.*

---

## Summary

This part configures the tenant-wide **Device settings** in the Microsoft Entra admin center. These settings govern who can join or register Windows devices with Microsoft Entra ID, whether multifactor authentication is required at join time, how many devices a user can own, who becomes a local administrator on joined devices, and how local admin passwords and BitLocker keys are handled. Getting these right early establishes the security posture that Intune enrollment and policy (later parts) build on. The values below reflect a security-forward configuration for a cloud-managed Windows fleet.

---

## Prerequisites

- **Cloud Device Administrator** (or higher) to enable Windows LAPS.
- **Privileged Role Administrator** (or higher) to change the BitLocker key recovery restriction.

---

## Navigation

1. Sign in to the [Microsoft Entra admin center](https://entra.microsoft.com/).
2. In the left navigation, select **Devices**.
3. Under **Manage**, select **Device settings**.
4. Change the settings below as needed, then select **Save**.

---

## Join and Registration Settings

### Users may join devices to Microsoft Entra

**Set to: All**

Controls who can perform a Microsoft Entra *join* — registering a Windows device as an organization-owned identity in the tenant. Setting it to **All** lets any licensed user join a device; you can instead scope it to **Selected** groups, or block it entirely with **None**. If this is set to None, new joins fail and Intune enrollment returns "This user is not authorized to enroll." For a cloud-native fleet where every user receives a company device, **All** is the practical choice.

### Users may register their devices with Microsoft Entra

**Set to: All (automatic)**

Device *registration* (workplace join) adds a lighter-weight device identity, typically for personal/BYOD devices, without a full join. When **Users may join devices** is set to **All**, this option is automatically set to All and greyed out, because a join is a superset of registration. Registration is what enables scenarios like Intune MDM enrollment and Conditional Access evaluation on the device. You generally don't set this directly — it follows the join setting.

### Require Multifactor Authentication to register or join devices with Microsoft Entra

**Set to: Yes**

Determines whether a user must pass MFA at the moment they join or register a device; the default is **No**. Microsoft's current recommendation is to leave this toggle at **No** and enforce MFA through a Conditional Access policy using the **Register or join devices** user action, which is more flexible and auditable. Note this toggle applies to Entra joined (with some exceptions) and Entra registered devices, but **not** to hybrid-joined devices or Autopilot self-deploying mode. If you are not yet using Conditional Access for device registration, setting this to **Yes** is a reasonable interim control. _(See the flag in Notes.)_

### Maximum number of devices per user

**Set to: 10**

Caps how many Microsoft Entra joined or registered devices a single user can own. The default is **50**; you can raise it up to **100**, set it to **Unlimited**, or lower it. When a user reaches the cap they cannot add another device until an existing one is removed, and enrollment fails until they do. A value of **10** keeps per-user device sprawl in check for a typical business user while leaving room for legitimate multi-device scenarios. (This limit doesn't apply to hybrid-joined devices or certain bulk/GPO-enrolled Windows devices.)

---

## Local administrator settings

### Global administrator role is added as local administrator on the device during Microsoft Entra join (Preview)

**Set to: Yes**

At Microsoft Entra join, Entra ID updates the device's local **Administrators** group, and the Global Administrator and Microsoft Entra Joined Device Local Administrator roles are the principals that receive local admin rights across joined devices. This toggle controls whether the **Global Administrator** role is placed in the local administrators group at join time. Enabling it ensures your top-tier admins can always manage the device locally for troubleshooting and recovery. This affects local device administrator membership only and is applied during the join operation.

### Registering user is added as local administrator on the device during Microsoft Entra join (Preview)

**Set to: Yes**

Controls whether the user who performs the Entra join is added to the local **Administrators** group on the device they join. By default, Entra ID adds the joining user as a local administrator. This affects local device admin membership only — it does **not** assign any Microsoft Entra directory role. In Microsoft Graph it maps to the `azureADJoin.localAdmins.registeringUsers` property of the device registration policy. Note that leaving this on makes standard users local admins of their own machines, which some security baselines advise against — keep it **Yes** only if your support model depends on it.

### Enable Microsoft Entra Local Administrator Password Solution (LAPS)

**Set to: Yes**

Windows LAPS securely manages and rotates the built-in local administrator password on each Windows device and backs it up to Microsoft Entra ID for authorized retrieval, mitigating pass-the-hash and lateral-movement attacks. This tenant-level toggle **must** be set to **Yes** before managed devices are permitted to post LAPS passwords to Entra ID. On its own it does nothing — you still need a client-side LAPS policy (deployed via **Intune > Endpoint security > Account protection**) to actually set the account, rotate the password, and back it up. Treat this step as the prerequisite; the Intune LAPS policy is configured in a later part.

---

## Other settings

### Restrict users from recovering the BitLocker key(s) for their owned devices

**Set to: Yes**

By default, users can self-service retrieve the BitLocker recovery key(s) for devices they own (through the My Account portal, Company Portal, or Entra ID). Setting this to **Yes** blocks that self-service access, so non-admin users must contact the helpdesk to obtain a recovery key. This closes a path where a compromised user account could pull the device's encryption key without any privilege escalation, which is why the Zero Trust guidance recommends it. You must be at least a **Privileged Role Administrator** to change this setting. _(See the flag in Notes.)_

---

## Notes

- **MFA at join:** Microsoft recommends enforcing MFA for device registration via a Conditional Access policy (the "Register or join devices" user action) rather than the **Require MFA** toggle. If you adopt that CA policy, set the toggle back to **No** to avoid double enforcement. [Part 2a](./Part%202a%20-%20CA%20Device%20Registration.md) walks through building that policy.
- **BitLocker restriction trade-off:** Microsoft's baseline setup tutorial leaves this at **No**; **Yes** is the more secure choice but shifts recovery-key retrieval to the helpdesk. Make sure your helpdesk process is ready before enabling.
- **LAPS is two parts:** the tenant toggle here plus a client-side Intune Account protection policy. Neither works without the other.
- **Local admin exposure:** adding the registering user as a local admin is convenient but grants standard users admin rights on their own devices — revisit this against your security baseline.

---

← **Previous:** [Part 1 - Group-Based Licensing](./Part%201%20-%20Licensing.md) · **Next:** [Part 2a - Conditional Access for Device Registration](./Part%202a%20-%20CA%20Device%20Registration.md) →

*[Intune Zero to Hero](./README.md) series · [Microsoft Intune](../README.md) · [Root index](../../README.md)*
