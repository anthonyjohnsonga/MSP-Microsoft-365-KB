# Microsoft Defender

This folder contains reference guides for configuring and managing Microsoft Defender security features on Windows endpoints in a Microsoft 365 managed environment.

---

### [Microsoft Defender SmartScreen & Network Protection](./Microsoft%20Defender%20Smartscreen%20Network%20Protection.md)

An MSP reference guide explaining the difference between Microsoft Defender SmartScreen and Network Protection, and how to close the browser coverage gap that exists when users browse in Chrome or Firefox instead of Edge. The guide covers how SmartScreen works, why it only protects Edge natively, how Network Protection operates at the Windows kernel level via the Windows Filtering Platform to enforce web filtering across all browsers, and the three Intune/Defender portal policies required to implement it (MDE EDR onboarding, Attack Surface Reduction Network Protection in Block mode, and Web Content Filtering). Also includes a verification checklist, PowerShell commands to confirm the configuration on-device, and alternative DNS-layer and proxy-based solutions for environments without MDE licensing.

---

### [Microsoft 365 Display Name Spoofing Guide](./Microsoft%20365%20Display%20Name%20Spoofing%20Guide.md)

A layered defense guide for protecting Microsoft 365 Business Premium tenants against display name spoofing — a phishing technique where attackers impersonate internal staff using matching display names from external domains. Covers 5 defense layers: email authentication (SPF/DKIM/DMARC), external sender callouts in EAC, anti-phishing user impersonation protection in Defender for Office 365 P1, mail flow rules targeting executive display names, and user awareness training via Attack Simulator. Includes an implementation checklist with priority and user impact ratings, and monitoring guidance for quarantine review, spoof intelligence, and DMARC reporting.

---

### [Microsoft 365 DMARC Rollout Guide](./Microsoft%20365%20DMARC%20Rollout%20Guide.md)

A phased rollout guide for moving a domain's DMARC policy from monitoring (`p=none`) through `p=quarantine` to full enforcement (`p=reject`) without breaking legitimate mail flow. Explains DMARC alignment (SPF/DKIM, relaxed vs. strict), the `pct=` staged-enforcement tag and its common misunderstandings, and a phase-by-phase timeline with exit criteria for each stage. Includes a pre-change checklist and sender inventory, fixes for common alignment failures (third-party vendors, website forms, copiers, forwarding, SPF lookup limits), subdomain and non-sending-domain strategy, Microsoft 365-specific behavior (DKIM enablement, high-risk delivery pool, no forensic reports), a change control template with rollback plan, DNS testing commands, customer-facing language, and an MSP decision matrix.
