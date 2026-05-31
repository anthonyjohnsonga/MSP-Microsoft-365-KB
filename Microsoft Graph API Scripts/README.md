# Microsoft Graph API Scripts

This folder contains PowerShell scripts for interacting with the Microsoft Graph API to manage Microsoft 365 and Entra ID resources.

---

### [MicrosoftGraph.ps1](./MicrosoftGraph.ps1)

A setup and connection script for the Microsoft Graph PowerShell module. It installs the `Microsoft.Graph.Authentication` module from the PowerShell Gallery, imports it, and connects to Microsoft Graph with a broad set of permission scopes covering role assignments, Conditional Access policies, device management, group management, and more. Run this script first to establish an authenticated Graph session before running other scripts in this folder.

---

### [mg-assign-role.ps1](./mg-assign-role.ps1)

Assigns a Microsoft Entra ID (Azure AD) directory role to a specified user via the Microsoft Graph API. The script looks up the user's Object ID and the role's Definition ID by name, then submits a role assignment request to the Graph API. Update the `$rolename` and `$user` variables at the top of the script before running.

---

### [mg-create-user.ps1](./mg-create-user.ps1)

Creates a new user account in Microsoft Entra ID via the Microsoft Graph API. The script builds a JSON payload from a set of user detail variables (display name, given name, surname, mail nickname, usage location, password, and domain) and posts it to the Graph API users endpoint. The new account is created with `forceChangePasswordNextSignIn` set to true. Update the variables at the top of the script with the target user's details before running.
