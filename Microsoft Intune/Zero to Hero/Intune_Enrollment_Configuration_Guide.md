# Part 3 - Intune Enrollment Configuration

*Part 3 of the [Intune Zero to Hero](./README.md) series.*

---

## Summary

This part configures the Windows enrollment prerequisites in the Intune admin center and Microsoft Entra ID: enrollment restrictions (how many and which devices may enroll), automatic enrollment (the MDM/MAM user scopes that let a Microsoft Entra join flow straight into Intune enrollment), the tenant-wide Windows Hello for Business enrollment default, and the DNS CNAME records that let Windows devices auto-discover the enrollment endpoints. With [Part 2](./Part%202%20-%20Microsoft%20Entra%20Device%20Settings.md)'s Entra device settings already in place, completing this part means a licensed user can join a Windows device and have it land in Intune automatically.

---

## Prerequisites

- **Intune Administrator** (or higher) to configure enrollment settings.
- **Microsoft Entra ID P1** or higher for automatic enrollment (included in Business Premium, per [Part 1](./Part%201%20-%20Licensing.md)).
- Access to the **public DNS zone** for the tenant's custom domain(s), in case CNAME records need to be added.

---

## Enrollment Restrictions

**Path:** [Intune admin center](https://intune.microsoft.com/) → **Devices > Windows > Enrollment**

### Device limit restriction

**Set to: 5 devices per user**

Device limit restrictions control the maximum number of devices a single user is allowed to enroll into Intune. This prevents unmanaged device sprawl, helps enforce license compliance, and reduces the attack surface by limiting how many endpoints a compromised or careless user account can bring into the tenant. Multiple device limit restrictions can be created and assigned different priorities to apply different limits to different user groups, with a default **All Users** restriction applied last if no other policy matches. _(This is separate from the Entra device cap set in Part 2 — see Notes.)_

### Device platform restriction

**No change from default.**

Enrollment restrictions determine which device platforms (Windows, iOS/iPadOS, Android, macOS) are permitted to enroll into Intune, and can enforce minimum/maximum OS version requirements for enrolling devices. Like device limit restrictions, these are evaluated in priority order against assigned groups, with the **All Users** restriction as the fallback. Review the defaults here, but no change is required for this series' Windows-focused rollout.

---

## Automatic Enrollment (MDM and MAM User Scope)

**Path:** [Microsoft Entra admin center](https://entra.microsoft.com/) → **Settings > Mobility** → **Microsoft Intune**

Automatic enrollment settings can be configured from either the Intune admin center or the Microsoft Entra admin center, since both surfaces write to the same underlying MDM/MAM user scope configuration.

### MDM user scope

**Set to: All**

MDM user scope controls which users are permitted to enroll their devices into Intune for full device management. Set it to **All**, or to **Some** if enrollment should be limited to a subset of users. If set to **Some**, assign a security group containing **only user objects** — device-based groups are not supported for this scope assignment.

### MAM user scope

**Set to: None**

MAM user scope enables Mobile Application Management without device enrollment, typically for BYOD scenarios. Set it to **None** unless the tenant is intentionally running MAM-without-enrollment. For corporate-owned devices, MDM enrollment takes precedence over MAM/WIP when both scopes are enabled for the same users.

> **Terminology note:** The setting is officially named **MAM user scope** (Mobile Application Management), not "WIP." Microsoft's own documentation is inconsistent about the blade name itself — it appears as both **Mobility (MDM and MAM)** and **Mobility (MDM and WIP)** across different Learn articles — but the setting label inside the blade is MAM user scope. Windows Information Protection (WIP) is a related but separate, legacy app-protection technology.

---

## Windows Hello for Business (Tenant-Wide Enrollment Setting)

**Path:** [Intune admin center](https://intune.microsoft.com/) → **Devices > Enrollment > Windows Hello for Business**

**Set to: Not configured**

This is the tenant-wide, enrollment-time default that controls whether Windows Hello for Business provisioning runs automatically during device enrollment (e.g., during Autopilot/OOBE). Setting it to **Not configured** defers WHfB provisioning to a dedicated WHfB enrollment-time policy or Configuration Profile, rather than forcing the built-in tenant default on every enrolling device.

---

## CNAME Validation

Validate that the required CNAME records for Intune/Entra ID auto-discovery have been added to public DNS for the tenant's custom domain. These records allow Windows devices to automatically discover the correct MDM enrollment and Entra ID registration endpoints when a user enters their work email during setup, instead of requiring manual entry of the enrollment server URL (`enrollment.manage.microsoft.com`).

**Required records:**

| Type | Host name | Points to | TTL |
|---|---|---|---|
| CNAME | `EnterpriseEnrollment.<domain>` | `EnterpriseEnrollment-s.manage.microsoft.com` | 1 hour |
| CNAME | `EnterpriseRegistration.<domain>` | `EnterpriseRegistration.windows.net` | 1 hour |

If the tenant uses multiple UPN suffixes, an additional `EnterpriseEnrollment` CNAME is required for each additional domain.

**Steps:**

1. In the Intune admin center, go to **Devices > Windows > Enrollment > CNAME Validation**, enter the custom domain, and run the test to confirm the CNAME records resolve correctly.
2. If the test passes, no further action is needed.
3. If the test fails, add the missing CNAME records to public DNS. Allow up to 72 hours for propagation, then re-run the test.

---

## Notes

- **Two different device limits:** the Entra **Maximum number of devices per user** (Part 2, set to **10**) and the Intune **device limit restriction** (this part, set to **5**) are separate settings evaluated at different layers. The Entra limit counts devices *joined or registered* in Entra ID; the Intune limit counts devices *enrolled* in Intune. Which one applies depends on the enrollment method: for user-driven enrollment both apply (whichever is reached first blocks the device), for **Windows Autopilot only the Entra limit applies** (the Intune restriction is bypassed), and for bulk enrollment, GPO-based automatic enrollment, and co-management neither the Intune limit nor, in most of those cases, the Entra limit applies. See [Understand Intune and Microsoft Entra device limit restrictions](https://learn.microsoft.com/intune/device-enrollment/limits-intune-entra).
- **Windows Hello for Business is deferred, not disabled:** **Not configured** simply means the tenant-wide default is not forced at enrollment. The actual WHfB configuration is delivered by policy in a later part.
- **CNAME records are a convenience, not a hard requirement:** enrollment still works without them, but users must type the enrollment server URL manually — a support burden worth avoiding.
- **DNS propagation:** newly added CNAME records can take up to 72 hours to propagate; a failed validation immediately after adding records is expected.

---

← **Previous:** [Part 2a - Conditional Access for Device Registration](./Part%202a%20-%20CA%20Device%20Registration.md)

*[Intune Zero to Hero](./README.md) series · [Microsoft Intune](../README.md) · [Root index](../../README.md)*
