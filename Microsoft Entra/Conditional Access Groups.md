---
created: 2026-03-23T13:05:00
updated: 2026-04-03T10:30
modified: 2026-04-03T10:30:18-04:00
tags:
  - Microsoft
  - Microsoft365
  - MicrosoftEntra
---

See [[Microsoft Conditional Access]] for reference

**CA - Staff (Security Group)**
Create a Microsoft Security group in Entra. 
Change the membership type to Dynamic User
Apply the follow query below
```
user.assignedPlans -any (assignedPlan.capabilityStatus -eq "Enabled")
```
Means:
- the user has at least one service plan
- and that plan is enabled
**CA - Guest (Security Group)**
Create a Microsoft Security group in Entra. 
Change the membership type to Dynamic User. 
Apply the follow query below
```
(user.userType -eq "Guest")
```
Filters only guest user type. 

**CA - Break Glass (Security Group)**
Create a Microsoft Security Group in Entra.
Leave the membership type set as Assigned
Add our 365 Admin account to this group

**CA - Admins (Security Group)**
This group is primary used for orgs that have the need for extra admin accounts. Our admin account will belong under the Break Glass group. 
