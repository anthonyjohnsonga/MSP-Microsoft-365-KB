# SC-900 Microsoft Entra Identity and Device Study Sheet

**Applies to:** Exam SC-900: Microsoft Security, Compliance, and Identity Fundamentals.

**Scope:** Focused review of Entra user identities, user restoration, device identity, device writeback, and group-based licensing. This is not a complete exam guide.

**Last Updated:** October 4, 2026

**Companion:** [SC-900 Microsoft Defender and Sentinel Study Sheet](./SC-900%20Microsoft%20Defender%20and%20Sentinel%20Study%20Sheet.md).

## Overview

Separate three questions: **Where is the user managed? How does the device trust the organization? How does the user receive a license?** These describe different properties and should not be treated as interchangeable categories.

Reading this sheet requires no tenant access or product license. Use the official SC-900 skills outline in Sources for the full exam scope; the operational examples here provide context rather than a prediction of exam questions.

## 1. User Identities and Source of Authority

| Concept | Meaning | Study cue |
|---|---|---|
| Cloud-only user | Account managed directly in the Entra tenant | Cloud directory is the management source |
| Directory-synchronized user | Account synchronized from on-premises AD through an appropriate synchronization service | Check the account's source of authority before editing it |
| External/B2B user | Person collaborating with a resource tenant using a supported external identity | Access to another organization's resources |
| Member or Guest | The account's UserType relationship to the resource tenant | Relationship, not proof of authentication source |

**Cloud/synchronized** and **Member/Guest** describe different dimensions. B2B accounts can have Member or Guest UserType; an internal account can also be classified as Guest. An external identity can use another Entra tenant, a Microsoft account, or another supported identity provider. Guest does not mean "outside Azure."

For synchronized accounts, many attributes remain managed in on-premises AD. Do not assume every displayed property can be changed in the cloud, or that removing a cloud account automatically removes its home-directory identity.

**Memory cue:** Source of authority tells you where to manage an attribute; UserType tells you how the tenant classifies the account.

## 2. Restore a Deleted User

Deleted users normally remain restorable for **30 days**. Permanent deletion cannot be reversed by Microsoft Support. Account restoration does not replace separate recovery checks for mailbox, OneDrive, or other workload data.

Use **User Administrator** for ordinary user restoration, subject to role scope and restrictions. Privileged administrator accounts require a role authorized to manage that target; do not assume an ordinary User Administrator can restore every administrator. The draft's legacy Partner Tier-1/Tier-2 list is not a suitable general permissions checklist.

### Lab Procedure

1. In the Microsoft Entra admin center, open **Entra ID > Users > Deleted users**.
2. Select the intended synthetic lab account, then **Restore user**.
3. Verify the account and required access. Review restored licenses: restoration can restore previous assignments even when purchased capacity is exhausted.

**Synchronized-user caveat:** Resolve the source account and synchronization state as well. An account still present in on-premises AD can be restored by a later synchronization cycle.

## 3. Compare Device Identity States

| State | Directory relationship | Typical scenario | Sign-in and management |
|---|---|---|---|
| Microsoft Entra registered | Device has an Entra identity without requiring an organizational account for local device sign-in | BYOD and mobile access | Local/platform sign-in; management enrollment is separate |
| Microsoft Entra joined | Device joins Entra rather than on-premises AD | Organization-owned, cloud-first devices, including organizations with hybrid resources | Organizational sign-in; Intune or another supported management approach |
| Microsoft Entra hybrid joined | Device joins on-premises AD and registers with Entra | Existing AD-based device infrastructure | AD sign-in; Group Policy, Configuration Manager, and supported Intune/co-management scenarios |

**Registration is not MDM enrollment.** A device identity alone does not prove that Intune manages the device or that it is compliant. Conditional Access evaluates the configured controls and available device signals.

### Platform Scope

- **Registered:** Includes supported Windows, macOS, iOS, Android, and Linux scenarios. Registration methods and available capabilities differ by platform.
- **Joined:** Windows 10/11 except Home editions; current documentation also lists supported Azure VM scenarios and macOS 13 or newer. Check the specific platform's deployment requirements rather than applying Windows instructions universally.
- **Hybrid joined:** Windows 10/11 except Home editions and Windows Server 2016/2019/2022 as listed in the current hybrid-join documentation. The old Windows 7/8.1 and Server 2008/2012 list should not be used as a current deployment recommendation.

An identity service's compatibility list is not an operating-system lifecycle guarantee. Check both the device identity documentation and the OS support lifecycle before deployment.

Entra-joined devices can access on-premises resources when authentication and connectivity prerequisites are met. Hybrid join is not automatically required simply because the organization has AD. Self-service password reset and Windows Hello recovery also have separate prerequisites.

**Memory cues:** Registered = device identity for access; joined = Entra device trust; hybrid joined = AD join plus Entra registration.

## 4. Device Writeback and Windows Hello for Business

Device writeback uses Microsoft Entra Connect Sync to create device objects in the on-premises **RegisteredDevices** container. It is distinct from hybrid device registration: the direction and purpose are different.

Documented uses include device-based access decisions for **AD FS 2012 R2 or later** applications and Windows Hello for Business hybrid certificate trust. Writeback requires **Entra ID P1 or P2** and has forest/topology restrictions; it is not a generic requirement for all cloud Conditional Access.

| Windows Hello hybrid trust model | Device writeback lesson |
|---|---|
| Cloud Kerberos trust | Does not require device writeback for Windows Hello authentication |
| Key trust | Device writeback is not a blanket requirement of this trust model |
| Certificate trust with AD FS | Device writeback is part of the documented deployment requirements |

Cloud Kerberos trust, key trust, and certificate trust have different infrastructure requirements. Do not enable writeback based solely on the words "hybrid" or "federated." Identify the actual deployment model first.

**Memory cue:** Writeback copies device identity information toward AD; it does not join a computer to AD or enroll it in Intune.

## 5. Group-Based Licensing

Group licensing assigns product licenses through group membership. Graph PowerShell is supported alongside the **Microsoft 365 admin center**; the portal is not the only management interface.

Assignments can enable or disable individual service plans. A user can receive direct and group assignments together; the same product license assigned through multiple sources is consumed once. Removing one assignment may leave another active. Nested group membership does not grant inherited licenses through the parent group's assignment.

### Lab Prerequisites and Procedure

Use an eligible group, available product licenses, appropriate licensing entitlement, and a **License Administrator** or another documented authorized role. Set user usage locations appropriately; dynamic membership has separate Entra licensing requirements.

1. Open **Microsoft 365 admin center > Billing > Licenses > Assign licenses**.
2. Select the fictional lab group **Marketing** and the subscription.
3. Review **Turn apps and services on or off**, then select **Assign licenses**.
4. Verify member assignments and resolve processing errors. Processing is asynchronous; do not promise a fixed completion time.

### Licensing Knowledge Checks

- Why might a user still have a license after leaving one licensed group? Check direct assignments and other group memberships.
- Why might only some members receive licenses? Check capacity, usage location, service-plan conflicts, and processing status.
- Why might a nested group's users be missed? Nested membership is not processed through the parent's licensing assignment.

## 6. Lab Safety, Verification, and Rollback

**MSP note:** Confirm the customer tenant and delegated role before any change. Keep customer account details and screenshots private. Use synthetic lab identities and groups for these exercises.

| Exercise | Verify | Recovery consideration |
|---|---|---|
| User restoration | Correct account restored, licensing reviewed, required workload access checked | Do not use permanent deletion as a rollback step; handle any mistaken restoration through the approved account lifecycle process |
| Group licensing | Correct users and service plans assigned; no unresolved errors | Record original assignments, then restore them if needed; inspect other assignment sources before removing access |
| Device identity review | Correct join type, management state, and compliance state identified independently | Read-only review needs no rollback; join, enrollment, or writeback changes need a separate deployment plan |

- [ ] Explain source of authority versus Member/Guest UserType.
- [ ] Distinguish registered, joined, hybrid joined, managed, and compliant.
- [ ] Explain the 30-day restoration window and permanent deletion limit.
- [ ] Identify the Windows Hello trust model before discussing writeback.
- [ ] Explain direct, group, and overlapping license assignments.
- [ ] Review the full official SC-900 outline alongside the companion sheet.

## Sources

- [Microsoft Learn: SC-900 study guide](https://learn.microsoft.com/en-us/credentials/certifications/resources/study-guides/sc-900)
- [Microsoft Learn: Create, invite, and delete Entra users](https://learn.microsoft.com/en-us/entra/fundamentals/how-to-create-delete-users)
- [Microsoft Learn: B2B user properties](https://learn.microsoft.com/en-us/entra/external-id/user-properties)
- [Microsoft Learn: Restore or remove a recently deleted user](https://learn.microsoft.com/en-us/entra/fundamentals/users-restore)
- [Microsoft Learn: Who can perform sensitive actions](https://learn.microsoft.com/en-us/entra/identity/role-based-access-control/privileged-roles-permissions#who-can-perform-sensitive-actions)
- [Microsoft Learn: Entra registered devices](https://learn.microsoft.com/en-us/entra/identity/devices/concept-device-registration)
- [Microsoft Learn: Entra joined devices](https://learn.microsoft.com/en-us/entra/identity/devices/concept-directory-join)
- [Microsoft Learn: Entra hybrid joined devices](https://learn.microsoft.com/en-us/entra/identity/devices/concept-hybrid-join)
- [Microsoft Learn: Device writeback](https://learn.microsoft.com/en-us/entra/identity/hybrid/connect/how-to-connect-device-writeback)
- [Microsoft Learn: Plan Windows Hello for Business](https://learn.microsoft.com/en-us/windows/security/identity-protection/hello-for-business/deploy/)
- [Microsoft Learn: Assign or unassign group licenses](https://learn.microsoft.com/en-us/microsoft-365/admin/manage/manage-group-licenses?view=o365-worldwide)
- [Microsoft Learn: Group licensing Graph PowerShell examples](https://learn.microsoft.com/en-us/entra/identity/users/licensing-powershell-graph-examples)
