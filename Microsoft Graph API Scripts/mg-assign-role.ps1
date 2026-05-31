# Define the role name and user
$rolename = "Azure AD Joined Device Local Administrator"
$user = "test@test.onmicrosoft.com"

# Get the user ID from Microsoft Graph
Write-Host "Getting user ID"
$userid = (Invoke-MgGraphRequest -Uri "https://graph.microsoft.com/beta/users/$user" -Method Get -OutputType PSObject).id
Write-Host "User ID obtained: $userid"

# Get the role ID to assign from Microsoft Graph
Write-Host "Getting role ID"
$uri = "https://graph.microsoft.com/beta/roleManagement/directory/roleDefinitions"
$roletoassign = (((Invoke-MgGraphRequest -Uri $uri -Method Get -OutputType PSObject).value) | where-object DisplayName -eq $rolename).id
Write-Host "Role ID obtained: $roletoassign"

# Define the parameters for the new role assignment
$params = @{
    "@odata.type" = "#microsoft.graph.unifiedRoleAssignment"
    RoleDefinitionId = "$roletoassign"
    PrincipalId = "$userid"
    DirectoryScopeId = "/"
}

$json = @'
{
"@odata.type": "#microsoft.graph.unifiedRoleAssignment",
"roleDefinitionId": "$roletoassign",
"principalId": "$userid",
"directoryScopeId": "/"
}
'@

$posturi = "https://graph.microsoft.com/beta/roleManagement/directory/roleAssignments"

# Create a new role assignment
Write-Host "Creating new role assignment"
Invoke-MgGraphRequest -Uri $posturi -Method Post -Body $json -ContentType "application/json"
Write-Host "Role assignment created successfully"
