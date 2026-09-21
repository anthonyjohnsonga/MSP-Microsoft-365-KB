# MD-102 Protect Devices — Pre-Exam Quick Check

**Applies to:** Exam MD-102: Endpoint Administrator; skills measured as of July 24, 2026<br>
**Scope:** Rapid review of device protection, compliance, Android Enterprise, Defender for Endpoint risk, and app protection concepts<br>
**Last Updated:** September 2026

---

Use this as a **5–10 minute final review**. Read each prompt, answer it mentally, and then confirm the rule.

---

## 1. Security Controls: Name the Right Tool

| If the requirement says… | Choose… | Memory cue |
|---|---|---|
| Evaluate the reputation of a website, download, or app | **Microsoft Defender SmartScreen** | **Reputation** |
| Block dangerous process behavior | **Attack surface reduction (ASR) rules** | **Behavior** |
| Allow only trusted applications to run | **App Control for Business** | **Allowlist apps** |
| Isolate untrusted websites or documents *(legacy questions)* | **Microsoft Defender Application Guard** | **Isolated container** |
| Apply a broad Microsoft-recommended security configuration | **Security baseline** | **Broad bundle** |
| Configure one security workload precisely | **Endpoint security policy** | **Focused policy** |

### Baseline conflict rule

Do not configure the same setting differently in a security baseline and an endpoint security policy.

> **Neither policy automatically wins. Conflicting values can produce a policy conflict.**

### Application Guard currency note

Microsoft Defender Application Guard is **deprecated** and is **unavailable starting with Windows 11, version 24H2**. It is also absent from the current MD-102 skills outline. Know its historical purpose in case older study material mentions it, but prioritize **App Control for Business, ASR rules, security baselines, endpoint security policies, and Defender for Endpoint** for the current exam.

### What replaced Application Guard?

There is **no single one-for-one replacement**. Microsoft now uses layered controls based on what needs protection:

| Previous Application Guard scenario | Current approach |
|---|---|
| Protect users from malicious websites and downloads | **Microsoft Edge for Business + Microsoft Defender SmartScreen + Network Protection** |
| Prevent users from running unapproved browsers or applications | **App Control for Business or AppLocker**, together with managed Edge policies |
| Protect against untrusted Word, Excel, and PowerPoint files | **Protected View + Defender for Endpoint ASR rules + App Control for Business** |
| Manually open or test something in a disposable isolated Windows environment | **Windows Sandbox** *(manual isolation, not a transparent Application Guard replacement)* |

Microsoft specifically recommends transitioning **Application Guard for Office** to **ASR rules, Protected View, and App Control for Business**.

> **Exam distinction:** App Control for Business did not directly replace Application Guard. **App Control decides which applications may run; Application Guard isolated untrusted content inside a Hyper-V container.**

---

## 2. Compliance and Conditional Access

Remember the division of responsibility:

| Component | Job |
|---|---|
| **Compliance policy** | Evaluates the device and determines whether it is compliant |
| **Conditional Access** | Uses the compliance result to allow or block access to resources |

### Rules to remember

- The default **Mark device noncompliant** action occurs **immediately**.
- Delaying that action creates a **remediation grace period**.
- Compliance policies are **platform-specific**.
- A device becoming noncompliant does **not**, by itself, block Microsoft 365 access.
- To enforce access, use Conditional Access with **Require device to be marked as compliant**.

### Exam flow

**Compliance policy evaluates → Intune records status → Conditional Access enforces access**

### Common trap

If the question asks you to **evaluate** device settings, choose a compliance policy. If it asks you to **block Microsoft 365 access**, Conditional Access must be part of the solution.

---

## 3. Android Enterprise Enrollment Modes

| Scenario | Correct enrollment mode |
|---|---|
| Employee-owned device with separated work data | **Personally owned work profile** |
| Corporate-owned device allowing work and personal use | **Corporate-owned work profile** |
| Corporate-owned, single-user, work-only device | **Fully managed** |
| Userless kiosk or task device | **Dedicated** |
| Shared kiosk where employees sign in and out of supported apps | **Dedicated with Microsoft Entra shared device mode** |

### Fast memory pattern

- **Personal phone + work container** → Personally owned work profile
- **Company phone + personal use allowed** → Corporate-owned work profile
- **Company phone + work only** → Fully managed
- **No assigned user** → Dedicated
- **Multiple workers sign in/out** → Dedicated + Entra shared device mode

### Dedicated-device and kiosk app rule

Apps that must be installed on userless dedicated devices should be assigned as **Required** to a device group. In multi-app kiosk mode, every app in the Managed Home Screen policy must be **Required** and assigned to the devices; otherwise, the kiosk can lock out the user.

### Android system-update behavior

| Setting | Behavior |
|---|---|
| **Automatic** | Installs updates without user interaction; applying the policy immediately installs pending updates |
| **Postponed** | Delays installation for **30 days**; afterward, Android prompts the user to install |
| **Maintenance window** | Attempts installation during specified daily hours for **30 days**; afterward, Android prompts the user |
| **Freeze periods** | Blocks system and security updates during specified calendar dates |

Managed Google Play app updates are separate from Android system updates. In the default app-update mode, updates wait until the device is on Wi-Fi, charging, idle, and the app isn't running in the foreground. Intune can instead set app updates to **High Priority** or **Postponed**; the app-update postponement is **90 days**, not 30.

### 30-day distinction

- **Postponed:** delay the system update for 30 days, then prompt the user.
- **Maintenance window:** try during the window for 30 days; after that, prompt the user.
- **Managed Google Play app postponed mode:** a different setting with a 90-day waiting period.

---

## 4. Defender for Endpoint Machine Risk

Memorize the complete enforcement chain:

**Defender for Endpoint → Machine-risk level → Intune compliance → Conditional Access → Microsoft 365 access**

Every link matters:

1. Defender for Endpoint calculates the device's machine-risk level.
2. Intune evaluates that risk against the compliance-policy threshold.
3. The device is marked compliant or noncompliant.
4. Conditional Access uses that result to permit or block access.

### Machine-risk threshold

The setting is **Require the device to be at or under the machine risk score**.

| Selected threshold | Risk levels that remain compliant |
|---|---|
| **Clear** | Clear only |
| **Low** | Clear and Low |
| **Medium** | Clear, Low, and Medium |
| **High** | Clear, Low, Medium, and High |

> To make **only High-risk devices noncompliant**, select **Medium**.

### Threshold memory cue

The selected value is the **highest risk still allowed**, not the first risk level blocked.

### Machine risk versus user risk

| Risk type | What may be compromised? | Policy path |
|---|---|---|
| **Defender machine risk** | The device | Defender for Endpoint → Intune compliance → Conditional Access |
| **Microsoft Entra user risk** | The identity | Entra ID Protection risk detection → Conditional Access user-risk condition |

These are separate signals and require separate policy paths.

---

## 5. Enrolled Versus Unenrolled Devices

| Device situation | Best control path |
|---|---|
| Enrolled and managed device | **Defender risk → compliance policy → Conditional Access** |
| Unenrolled personal device using managed apps | **App protection policy with conditional launch** |

### Why the answer changes

- An **enrolled device** can be evaluated for device-wide compliance.
- On an **unenrolled personal device**, app protection controls organizational data inside the managed app without managing the whole device.

### Conditional-launch actions

Available actions depend on the specific conditional-launch setting; **Warn**, **Block access**, and **Wipe data** aren't offered for every condition.

| Action | Result |
|---|---|
| **Warn** | Informs the user but allows continuation |
| **Block access** | Temporarily denies organizational app access while preserving the data |
| **Wipe data** | Removes the organizational account and managed-app data while leaving personal data intact |

### Block versus wipe

- Need access restored after remediation? → **Block access**
- Need organizational data removed from the app? → **Wipe data**

---

## 6. Last-Minute Exam Traps

Before choosing an answer, check for these wording traps:

- **Reputation** points to SmartScreen; **process behavior** points to ASR.
- **Allow only trusted apps** points to App Control for Business. Application Guard isolated untrusted content historically, but it is deprecated and isn't a current MD-102 objective.
- Application Guard has **no single direct successor**. For untrusted Office files, think **Protected View + ASR + App Control**; for web threats, think **Edge + SmartScreen + Network Protection**.
- A compliance policy **evaluates**; Conditional Access **enforces resource access**.
- A security baseline and endpoint security policy do not have an automatic winner when they conflict.
- A Defender risk threshold is the **highest risk allowed**.
- Selecting **High** does not block High risk; it permits all listed risk levels.
- Device machine risk and Entra user risk are different signals.
- Device compliance is suited to enrolled devices; app protection conditional launch is suited to unenrolled personal devices.
- **Block access** preserves managed data; **Wipe data** removes it.
- On Android, **Postponed** and **Maintenance window** both involve 30 days, but their behavior is different.
- Don't confuse the **30-day Android system-update** behavior with the **90-day Managed Google Play app-update** postponement.

---

## 7. Rapid Closed-Book Check

Answer these before viewing the key.

1. Which control evaluates the reputation of a downloaded application?
2. Which control permits only approved applications to run?
3. Which legacy control isolated untrusted content, what is its current status, and what replaced it?
4. What happens if the same setting is configured differently in a security baseline and endpoint security policy?
5. Which policy evaluates whether a device meets requirements?
6. What additional control is needed to block Microsoft 365 access when the device is noncompliant?
7. Which Android mode fits a corporate device that permits personal use?
8. Which Android mode fits a userless kiosk?
9. How must apps be assigned to a dedicated Android device?
10. What does the Android **Postponed** system-update setting do?
11. What happens after a maintenance window has attempted installation for 30 days?
12. Which machine-risk threshold makes only High-risk devices noncompliant?
13. Does selecting a High machine-risk threshold block High-risk devices?
14. What is the enforcement path from Defender for Endpoint risk to Microsoft 365 access?
15. Which risk signal refers to a possibly compromised identity?
16. What protects organizational data in managed apps on an unenrolled personal device?
17. Which conditional-launch action temporarily prevents access but preserves organizational data?
18. Which conditional-launch action removes organizational app data but not personal data?

<details>
<summary><strong>Answer key</strong></summary>

1. Microsoft Defender SmartScreen
2. App Control for Business
3. Microsoft Defender Application Guard; it is deprecated, unavailable starting with Windows 11 24H2, and has no single replacement. Use layered controls: Edge + SmartScreen + Network Protection for web threats, and Protected View + ASR rules + App Control for untrusted Office files
4. A policy conflict can occur; neither policy automatically takes precedence
5. An Intune compliance policy
6. Conditional Access requiring a compliant device
7. Corporate-owned work profile
8. Dedicated
9. Required
10. It delays installation for 30 days and then prompts the user to install
11. Android prompts the user
12. Medium
13. No. High permits Clear, Low, Medium, and High
14. Defender for Endpoint → machine risk → Intune compliance → Conditional Access → Microsoft 365 access
15. Microsoft Entra user risk
16. An app protection policy with conditional launch
17. Block access
18. Wipe data

</details>

---

## 8. Ten-Second Final Recall

**Reputation = SmartScreen**<br>
**Behavior = ASR**<br>
**Trusted apps only = App Control**<br>
**Legacy isolation = Application Guard (deprecated; not a current objective)**<br>
**Web replacement = Edge + SmartScreen + Network Protection**<br>
**Office-file replacement = Protected View + ASR + App Control**<br>
**Evaluate device = Compliance**<br>
**Enforce access = Conditional Access**<br>
**Only High risk fails = Medium threshold**<br>
**Unenrolled personal device = App protection**<br>
**Preserve data = Block**<br>
**Remove work data = Wipe**

---

## Sources

Reviewed against current Microsoft Learn documentation on **September 20, 2026**:

- [Current MD-102 study guide](https://learn.microsoft.com/en-us/credentials/certifications/resources/study-guides/md-102)
- [Android Enterprise device restrictions and system updates](https://learn.microsoft.com/en-us/intune/device-configuration/templates/ref-device-restrictions-android-enterprise)
- [Managed Google Play app deployment and updates](https://learn.microsoft.com/en-us/intune/app-management/deployment/add-managed-google-play)
- [Windows compliance and Defender machine-risk thresholds](https://learn.microsoft.com/en-us/intune/device-security/compliance/ref-windows-settings)
- [Android app-protection conditional-launch settings](https://learn.microsoft.com/en-us/intune/app-management/protection/ref-settings-android)
- [Actions for noncompliant devices](https://learn.microsoft.com/en-us/intune/device-security/compliance/configure-noncompliance-actions)
- [Application Guard lifecycle status](https://learn.microsoft.com/en-us/windows/security/application-security/application-isolation/microsoft-defender-application-guard/md-app-guard-overview)
- [Application Guard for Office transition guidance](https://learn.microsoft.com/en-us/defender-office-365/app-guard-for-office-install)
- [Microsoft Edge security for business](https://learn.microsoft.com/en-us/deployedge/ms-edge-security-for-business)
