# MD-102 Apple Management — Pre-Exam Quick Check

**Applies to:** Exam MD-102: Endpoint Administrator; skills measured as of July 24, 2026<br>
**Scope:** Rapid review of Apple enrollment, macOS Company Portal deployment, and Apple operating-system update management in Intune<br>
**Last Updated:** September 2026

---

This guide is separate from the general **Protect Devices Quick Check** and focuses on Apple enrollment, management, applications, compliance, and updates in Microsoft Intune.

> **Guide status:** In progress. Current sections cover user affinity, Company Portal deployment on macOS, and Apple operating-system update eligibility.

---

## 1. User Affinity

### What is user affinity?

**User affinity is the association between an enrolled Apple device and a specific user.**

It answers this question:

> **Does this device belong to one identifiable employee, or is it a userless/shared device?**

### With versus without user affinity

| Enrollment choice | Meaning | Best fit |
|---|---|---|
| **Enroll with user affinity** | Intune associates the device with a specific user | Personally assigned iPhone or iPad used by one employee |
| **Enroll without user affinity** | Intune enrolls and manages the device without associating it with one user | Kiosk, point-of-sale, shared utility, or other userless device |
| **Enroll with Microsoft Entra ID shared mode** | Intune prepares the device for multiple workers to sign in and out of supported applications | Shared frontline device using supported Microsoft apps |

### Enroll with user affinity

Choose **Enroll with user affinity** when:

- The device is assigned to one employee.
- The employee needs user-targeted apps and policies.
- The employee uses Company Portal services, such as installing available apps.
- The device needs to register with Microsoft Entra ID for compliance and Conditional Access.

For Automated Device Enrollment (ADE), Microsoft recommends **Setup Assistant with modern authentication** for devices enrolled with user affinity. **Setup Assistant (legacy)** is deprecated.

### Enroll without user affinity

Choose **Enroll without user affinity** when:

- The device isn't assigned to one specific person.
- The device is used as a kiosk, point-of-sale terminal, shared utility device, or task device.
- Management should be primarily device-based instead of user-based.
- Users don't need the normal Company Portal experience for installing available applications.

Target these devices with **device groups** and use device-based assignments whenever possible.

### Shared iPad exam rule

Apple **Shared iPad** uses:

- **Enroll without user affinity**
- **Supervised = Yes**
- **Shared iPad = Yes**

Users can then sign in to their individual Shared iPad sessions with Managed Apple IDs, or the organization can allow temporary guest sessions.

> **Important distinction:** Shared iPad has multiple Apple user sessions, but its Intune enrollment profile is configured **without user affinity**.

### Microsoft Entra shared device mode

Use **Enroll with Microsoft Entra ID shared mode** when multiple frontline employees need to sign in and out of supported organizational apps on the same device.

This differs from a standard userless kiosk because the applications understand which employee is currently signed in and can clear that employee's application session during sign-out.

### What user affinity is not

- It does **not** determine whether the device is personally or corporately owned.
- It is **not** the same as supervision.
- It does **not** mean the employee owns the device.
- It identifies whether Intune associates the enrollment with a particular user.

### User affinity versus supervision

| Concept | Question it answers |
|---|---|
| **User affinity** | Is this device associated with a specific user? |
| **Supervision** | Does the organization have enhanced management control over the Apple device? |

A corporate device can be both **supervised** and enrolled **with user affinity**.

### Memory cue

**Affinity = attachment to a user**

- **One employee** → With user affinity
- **No permanent employee** → Without user affinity
- **Multiple workers signing in and out** → Entra shared device mode or Shared iPad, depending on the scenario

### Common exam traps

- A corporate-owned iPhone assigned to one employee normally uses **user affinity**.
- A kiosk or point-of-sale iPad normally uses **no user affinity**.
- User affinity and supervision are independent choices.
- Apple Shared iPad is configured **without user affinity**, even though users sign in to separate sessions.
- For current ADE scenarios with user affinity, prefer **Setup Assistant with modern authentication**, not Setup Assistant (legacy).

### Quick check

1. A company-owned iPhone is permanently assigned to one salesperson. Which option should you choose?<br>
   **Enroll with user affinity.**

2. An iPad runs one point-of-sale application and isn't assigned to an employee. Which option should you choose?<br>
   **Enroll without user affinity.**

3. Several frontline employees share an iPhone and sign in and out of supported Microsoft applications. Which option should you choose?<br>
   **Enroll with Microsoft Entra ID shared mode.**

4. Does user affinity mean that the user personally owns the device?<br>
   **No. It only associates the enrolled device with a user.**

5. Does a supervised device automatically have user affinity?<br>
   **No. Supervision and user affinity are separate concepts.**

6. Which user-affinity configuration is required for Apple Shared iPad?<br>
   **Enroll without user affinity, enable supervision, and enable Shared iPad.**

---

## 2. Company Portal Deployment on macOS

### VPP distinction

The macOS Company Portal application isn't distributed through Apple Business Manager **Apps and Books/VPP** in the same way as the iOS/iPadOS Company Portal app.

> **Exam memory cue:** **iOS/iPadOS Company Portal can use VPP; macOS Company Portal uses its installer package.**

### macOS installation options

| Method | How it works | Best fit |
|---|---|---|
| **Shell script** | Downloads the current Microsoft Company Portal installer package and installs it silently | Automated deployment when you want the script to retrieve the latest installer |
| **macOS app (PKG)** | Upload the Microsoft-signed Company Portal `.pkg` to Intune and assign it as Required | Intune-managed application deployment and installation reporting |
| **Manual user installation** | User downloads the `.pkg` from Microsoft's **Enroll My Mac** link and runs the installer | User-driven enrollment, especially for a personally owned Mac |

### Shell script option

A macOS shell script can:

1. Check whether Company Portal is already installed.
2. Download the current installer package from Microsoft.
3. Install the package silently.
4. Exit successfully when the application is present.

Deploy the script through Intune's **macOS Platform scripts** area. Portal navigation can change, so focus on the policy type for the exam.

The script should be:

- Assigned to an appropriate macOS user or device group.
- Configured to run as the signed-in user or as root according to the script's design; software installation ordinarily requires root privileges.
- Idempotent so that it doesn't unnecessarily reinstall Company Portal every time it runs.
- Designed with logging and exit codes so installation failures can be diagnosed.

### macOS app (PKG) option

Company Portal can also be deployed as a **macOS app (PKG)**:

1. Download the Microsoft Company Portal installer `.pkg`.
2. In Intune, go to **Apps > All Apps > Create > macOS app (PKG)**.
3. Upload the `.pkg` file.
4. In the detection rules, retain the Company Portal bundle ID `com.microsoft.CompanyPortalMac` and remove unrelated included libraries.
5. Assign the application as **Required** to the intended group.

This approach provides normal Intune application assignment and installation reporting. When you want to deploy a newer package through Intune, update the application's `.pkg` content.

### Updating Company Portal

After installation, **Microsoft AutoUpdate (MAU)** handles Company Portal updates on macOS in the same way that it updates other Microsoft applications.

### Common exam traps

- Don't select an **Apps and Books/VPP** deployment for the macOS Company Portal.
- A **shell script is an option**, but it isn't the only option; deploying Company Portal as a macOS app (PKG) is also valid.
- macOS uses a Microsoft installer **`.pkg`**, whereas iOS/iPadOS commonly uses the App Store/VPP application.
- Microsoft AutoUpdate handles later Company Portal application updates on macOS.

### Quick check

1. Is the macOS Company Portal deployed as an Apple VPP app?<br>
   **No. Use the macOS installer package.**

2. Which automated option can download and silently install the latest Company Portal package?<br>
   **A macOS shell script.**

3. What is the alternative to using a shell script?<br>
   **Upload the signed `.pkg` as a macOS app (PKG) and assign it as Required.**

4. What normally updates Company Portal after it is installed?<br>
   **Microsoft AutoUpdate.**

---

## 3. Apple OS Update Eligibility

### Which enrollments support Intune-enforced updates?

Current Intune Apple update policies use Apple's **Declarative Device Management (DDM)** framework.

| Enrollment method | Typical ownership | Can Intune enforce OS updates? |
|---|---|---:|
| **Automated Device Enrollment (ADE)** | Corporate or school owned | **Yes** |
| **Apple Device Enrollment** — full MDM enrollment | Personal or corporate | **Yes** |
| **Apple User Enrollment** | Personal/BYOD | **No** |
| **Account-driven User Enrollment** | Personal/BYOD | **No** |
| **Unenrolled/MAM-only device** | Personal/BYOD | **No** |

For current DDM update policies, the minimum supported versions are **iOS/iPadOS 17** and **macOS 14**.

### Device Enrollment versus User Enrollment

**Device Enrollment** gives Intune device-level MDM control. It can therefore receive and enforce Apple OS update policies.

**User Enrollment** is a privacy-focused enrollment intended primarily for personally owned devices. It lets Intune manage organizational applications, accounts, and work data without granting full control of the device. The user remains responsible for installing OS updates.

> **Important wording:** **Device Enrollment** and **User Enrollment** are different Apple enrollment methods. A personally owned device can use either method, depending on how much management control the organization requires.

### User affinity does not decide update support

User affinity identifies whether Intune associates the device with a particular employee. It doesn't determine whether Intune can enforce OS updates.

- ADE **with user affinity** can receive update policies.
- ADE **without user affinity** can receive update policies.
- A userless kiosk or Shared iPad enrolled through ADE can receive update policies.
- Apple User Enrollment doesn't support enforced OS updates, even though it is associated with a user.

### DDM versus legacy update policies

Apple's older MDM-based software-update workloads are deprecated. For current scenarios, use **DDM software-update policies**, which can:

- Enforce the latest eligible OS version after a specified delay.
- Target a specific OS version or build.
- Set an enforcement date and time.
- Allow the device to evaluate and enforce the update locally.

### Memory cue

**Device Enrollment or ADE = Intune can enforce updates**<br>
**User Enrollment = the user controls OS updates**

### Common exam traps

- Don't confuse **User Enrollment** with **user affinity**.
- User Enrollment is normally BYOD, but not every personal device must use User Enrollment.
- A personally owned device using full **Device Enrollment** can receive update policies.
- ADE update eligibility isn't changed by choosing with or without user affinity.
- Focus on **DDM** for current Apple update questions; legacy MDM update policies are deprecated.

### Quick check

1. A corporate iPad is enrolled through ADE with user affinity. Can Intune enforce OS updates?<br>
   **Yes. ADE supports DDM update policies.**

2. A user enrolls a personal iPhone using Apple User Enrollment. Can Intune enforce an iOS update?<br>
   **No. The user controls OS updates.**

3. Does enrolling through ADE without user affinity prevent Intune from managing updates?<br>
   **No. User affinity doesn't determine update eligibility.**

4. Which two enrollment methods support current Intune Apple update policies?<br>
   **Device Enrollment and Automated Device Enrollment.**

---

## Ten-Second Recall

**User affinity = device linked to one user**<br>
**Assigned employee device = with affinity**<br>
**Kiosk/POS/userless device = without affinity**<br>
**Frontline app sign-in/out = Entra shared device mode**<br>
**Shared iPad = without affinity + supervised + Shared iPad enabled**<br>
**Affinity is not ownership or supervision**<br>
**macOS Company Portal = installer `.pkg`, not VPP**<br>
**Automated deployment = shell script or required macOS app (PKG)**<br>
**Company Portal updates = Microsoft AutoUpdate**<br>
**Device Enrollment or ADE = Intune can enforce Apple OS updates**<br>
**User Enrollment = personal/BYOD with limited management; user controls OS updates**<br>
**User affinity does not determine update eligibility**

---

## Sources

Reviewed against current Microsoft Learn documentation on **September 20, 2026**:

- [Set up Automated Device Enrollment for iOS/iPadOS](https://learn.microsoft.com/en-us/intune/device-enrollment/apple/setup-automated-ios)
- [Authentication methods for Apple Automated Device Enrollment](https://learn.microsoft.com/en-us/intune/device-enrollment/apple/ref-automated-authentication-methods)
- [Add the Company Portal for macOS app](https://learn.microsoft.com/en-us/intune/app-management/deployment/add-company-portal-macos)
- [Add an unmanaged macOS PKG app to Intune](https://learn.microsoft.com/en-us/intune/app-management/deployment/add-unmanaged-pkg-macos)
- [Install and enroll with Company Portal for macOS](https://learn.microsoft.com/en-us/intune/user-help/enrollment/enroll-company-portal-macos)
- [Configure update policies for Apple devices](https://learn.microsoft.com/en-us/intune/device-updates/apple/)
