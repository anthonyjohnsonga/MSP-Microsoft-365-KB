# Microsoft Defender

This folder contains reference guides for configuring and managing Microsoft Defender security features on Windows endpoints in a Microsoft 365 managed environment.

---

### [Microsoft Defender SmartScreen & Network Protection](./Microsoft%20Defender%20Smartscreen%20Network%20Protection.md)

An MSP reference guide explaining the difference between Microsoft Defender SmartScreen and Network Protection, and how to close the browser coverage gap that exists when users browse in Chrome or Firefox instead of Edge. The guide covers how SmartScreen works, why it only protects Edge natively, how Network Protection operates at the Windows kernel level via the Windows Filtering Platform to enforce web filtering across all browsers, and the three Intune/Defender portal policies required to implement it (MDE EDR onboarding, Attack Surface Reduction Network Protection in Block mode, and Web Content Filtering). Also includes a verification checklist, PowerShell commands to confirm the configuration on-device, and alternative DNS-layer and proxy-based solutions for environments without MDE licensing.
