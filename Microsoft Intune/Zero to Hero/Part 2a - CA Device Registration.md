# Part 2a - Conditional Access for Device Registration

*Part 2a of the [Intune Zero to Hero](./README.md) series.*

---

## Summary

This part is a continuation of [Part 2 - Microsoft Entra Device Settings](./Part%202%20-%20Microsoft%20Entra%20Device%20Settings.md). It implements the recommendation flagged in Part 2's notes: enforce MFA at device registration through a **Conditional Access policy** targeting the **Register or join devices** user action, instead of the tenant-wide **Require Multifactor Authentication** toggle. The CA approach is Microsoft's current recommendation because it is more flexible (group scoping, exclusions, report-only mode) and fully auditable through sign-in logs.

Once this policy is enabled, the Part 2 toggle should be set back to **No** so MFA is not enforced twice.

---

## Prerequisites

- **Microsoft Entra ID P1** or higher for Conditional Access (included in Business Premium, per [Part 1](./Part%201%20-%20Licensing.md)).
- **Conditional Access Administrator** (or higher) to create and enable the policy.
- A **break-glass (emergency access) group** to exclude from the policy — e.g., `SG - CA - Break glass - Users`.
- Target users should already be **MFA-capable** (registered for at least one MFA method); otherwise they will be interrupted to register a method the first time they join or register a device.

---

## Policy Configuration

1. Sign in to the [Microsoft Entra admin center](https://entra.microsoft.com/).
2. In the left navigation, select **Protection > Conditional Access > Policies**.
3. Select **New policy** and name it so its purpose is obvious at a glance, e.g. **`CA - Require MFA - Device Registration`**.
4. Configure the assignments and access controls:

| Blade | Setting |
|---|---|
| **Users > Include** | `SG - CA - Staff - Users` |
| **Users > Exclude** | `SG - CA - Break glass - Users` |
| **Target resources** | **User actions** → **Register or join devices** |
| **Grant** | Grant access → **Require authentication strength** → **Multifactor authentication** |
| **Enable policy** | **Report-only** (switch to **On** after validation — see step 6) |

5. Select **Create**.
6. Validate before enforcing: leave the policy in **Report-only** for a few days, then review **Sign-in logs** (filter on the report-only result) or use the **What If** tool to confirm it applies to the users and action you expect. When satisfied, edit the policy and set **Enable policy** to **On**.
7. **Return to Part 2's Device settings** (Entra admin center > **Devices > Device settings**) and set **Require Multifactor Authentication to register or join devices with Microsoft Entra** back to **No**, so enforcement comes from this policy alone.

---

## Notes

- **Do not skip report-only.** A misconfigured registration policy set straight to **On** can block all new device joins — including Autopilot — tenant-wide.
- **Autopilot:** user-driven Autopilot joins authenticate as the user, so this policy applies and the user is prompted for MFA during OOBE. Self-deploying and pre-provisioning modes have no user sign-in at join and are not subject to this user-action policy.
- **Limited conditions for this user action:** when targeting **Register or join devices**, some Conditional Access conditions and grant controls are unavailable. Keep this policy simple — its only job is requiring MFA at registration.
- **Avoid double enforcement:** if the Part 2 toggle is left at **Yes** alongside this policy, users can be challenged twice. The toggle should be **No** once this policy is **On**.
- **Break-glass exclusion:** the emergency access accounts must stay excluded here, as in every CA policy, so a broken policy or MFA outage cannot lock administrators out.

---

← **Previous:** [Part 2 - Microsoft Entra Device Settings](./Part%202%20-%20Microsoft%20Entra%20Device%20Settings.md)

*[Intune Zero to Hero](./README.md) series · [Microsoft Intune](../README.md) · [Root index](../../README.md)*
