# Intune Zero to Hero

A start-to-finish guide for standing up and operating Microsoft Intune for Windows devices in an MSP environment. The guide is broken into sequential **parts** — read them in order for a complete zero-to-hero process, or use any single part as a standalone reference.

---

## Parts

> _Read top to bottom for the full process, or jump to any part as a standalone reference._

1. [Part 1 - Group-Based Licensing](./Part%201%20-%20Licensing.md) — Assign Business Premium (or any license) to an Entra security group so membership drives licensing; includes the group naming convention.
2. [Part 2 - Microsoft Entra Device Settings](./Part%202%20-%20Microsoft%20Entra%20Device%20Settings.md) — Tenant-wide Entra device settings: join/registration scope, MFA at join, device cap, local admin behavior, LAPS, and BitLocker key recovery — each setting explained.
3. [Part 2a - Conditional Access for Device Registration](./Part%202a%20-%20CA%20Device%20Registration.md) — Continuation of Part 2: enforce MFA at device join/registration with a Conditional Access policy (Register or join devices user action) instead of the tenant toggle.
4. [Part 3 - Intune Enrollment Configuration](./Intune_Enrollment_Configuration_Guide.md) — Windows enrollment setup in Intune: device limit and platform restrictions, automatic enrollment (MDM/MAM user scope), the tenant-wide Windows Hello for Business default, and CNAME validation.

---

*Part of the [Microsoft Intune](../README.md) knowledge base. Return to the [root index](../../README.md).*
