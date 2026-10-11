# Microsoft Graph API Scripts

**Applies to:** Microsoft Graph PowerShell; Microsoft Entra ID in the Global cloud<br>
**Scope:** Delegated tenant connections, cloud-only member user creation, and directory role assignment<br>
**Last Updated:** October 10, 2026

## 1. Connect to the Target Tenant

### [MicrosoftGraph.ps1](./MicrosoftGraph.ps1)

Run in PowerShell with access to PowerShell Gallery. The script installs `Microsoft.Graph.Authentication` only when missing, imports it, ends any existing Graph session, and connects to an explicitly selected tenant. Authentication lasts for the current PowerShell process. Select permissions by task:

| Task | Requested delegated permissions |
|---|---|
| `CreateUser` | `User.Create` |
| `AssignRole` | `User.ReadBasic.All`, `RoleManagement.ReadWrite.Directory` |
| `Custom` | The scopes supplied through `-Scopes` |

```powershell
# Replace with the customer's tenant GUID; do not store customer IDs in this repo.
$tenantId = Read-Host 'Customer tenant ID'
.\MicrosoftGraph.ps1 -TenantId $tenantId -Task CreateUser
```

The signed-in account must have permission to perform the operation in that tenant. Obtain administrator consent where required. For user provisioning, use an appropriately authorized administrator, such as User Administrator. For directory role assignment, Privileged Role Administrator is the least-privileged supported role. Activate eligible roles through PIM before running the operation. Licensing is separate: creating an account does not assign a Microsoft 365 license; the selected directory role can also have licensing prerequisites.

For another task, specify its documented scopes explicitly:

```powershell
.\MicrosoftGraph.ps1 -TenantId $tenantId -Task Custom -Scopes 'Group.Read.All'
```

**MSP note:** Verify the returned `TenantId`, `Account`, and `Scopes` for each customer. Selecting narrower scopes does not revoke permissions previously consented to the enterprise application.

## 2. Create a User

### [mg-create-user.ps1](./mg-create-user.ps1)

Creates a cloud-only member user through the stable Graph `v1.0/users` endpoint. Provide user details as parameters and enter the temporary password at the secure prompt. The script checks the connected tenant, serializes JSON to preserve quotes and backslashes, requires a password change at next sign-in, and stops on request errors. It returns the created user's ID, display name, and UPN.

```powershell
.\mg-create-user.ps1 -TenantId $tenantId `
    -DisplayName 'User One' -GivenName 'User' -Surname 'One' `
    -UserPrincipalName 'user1@contoso.com' -MailNickname 'user1' `
    -UsageLocation 'GB'
```

Replace the example UPN with a verified, managed domain in the target tenant. `UsageLocation` must be a valid two-letter country code. Federated-domain provisioning requiring `onPremisesImmutableId`, guest invitations, sovereign clouds, and app-only authentication are outside this script's scope.

The password must briefly exist as plaintext in memory for the HTTPS request. The script clears its payload references and frees the unmanaged password buffer afterward; this does not guarantee erasure of managed string copies. Do not print the request body or save passwords in scripts, transcripts, or repository files.

## 3. Assign a Directory Role

### [mg-assign-role.ps1](./mg-assign-role.ps1)

Looks up the user's Object ID and the role's Definition ID, then submits a tenant-wide role assignment request. This script currently uses the Graph beta endpoint. Update `$rolename` and `$user` in your local working copy before running; keep customer identifiers out of commits.

```powershell
.\MicrosoftGraph.ps1 -TenantId $tenantId -Task AssignRole
# Verify the tenant and edit the role/user values before running.
.\mg-assign-role.ps1
```

## 4. Verify and Recover

- Confirm `Get-MgContext` shows the intended customer tenant before each operation.
- Verify the created account under **Entra ID > Users > All users**, including UPN, usage location, and account status. Assign licenses separately if required.
- Verify role membership under **Entra ID > Roles & admins > Selected role > Assignments**.
- If a request fails or times out, inspect the tenant before retrying; a server-side change might have completed.
- Roll back an unwanted user by reviewing dependencies and deleting the newly created account in Entra. Remove an unintended role assignment from the selected role's assignments.
- Finish with `Disconnect-MgGraph`. Disconnecting ends authentication; it does not undo changes or revoke consent.

## Sources

- [Microsoft Graph PowerShell authentication commands](https://learn.microsoft.com/en-us/powershell/microsoftgraph/authentication-commands)
- [Create user: permissions and request requirements](https://learn.microsoft.com/en-us/graph/api/user-post-users?view=graph-rest-1.0)
- [Get user: permissions](https://learn.microsoft.com/en-us/graph/api/user-get?view=graph-rest-1.0)
- [Create directory role assignment: permissions and roles](https://learn.microsoft.com/en-us/graph/api/rbacapplication-post-roleassignments?view=graph-rest-1.0)
