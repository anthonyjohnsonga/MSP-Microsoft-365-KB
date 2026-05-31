# Microsoft Teams

This folder contains helpdesk technician reference guides for managing Microsoft Teams policies and configuration in a Microsoft 365 environment.

---

### [Teams – External File Sharing via CsTeamsFilesPolicy](./Teams%20-%20External%20File%20Sharing%20via%20CsTeamsFilesPolicy.md)

A reference guide explaining why Microsoft Teams blocks native file attachments in chats with external users by default, and how to resolve it using the `CsTeamsFilesPolicy` PowerShell cmdlets. The guide covers checking the current policy state, enabling file sharing globally for the entire tenant or scoped to specific users and groups, understanding policy rank precedence for group assignments, and verifying effective policy assignments using `Get-CsUserPolicyAssignment`. It also clarifies that SharePoint external sharing settings are a separate layer that must also be configured for recipients to open shared files, and includes a full quick reference table of all relevant commands.
