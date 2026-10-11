# Connect to the selected customer's tenant with permissions for one task.
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [guid]$TenantId,

    [Parameter(Mandatory)]
    [ValidateSet('CreateUser', 'AssignRole', 'Custom')]
    [string]$Task,

    [string[]]$Scopes
)

if ($TenantId -eq [guid]::Empty) { throw 'TenantId cannot be empty.' }
if ($Task -eq 'Custom') {
    if (!$Scopes -or @($Scopes | Where-Object { [string]::IsNullOrWhiteSpace($_) }).Count) {
        throw 'Custom requires a nonempty -Scopes list.'
    }
} else {
    if ($PSBoundParameters.ContainsKey('Scopes')) { throw 'Use -Task Custom to specify -Scopes.' }
    $Scopes = switch ($Task) {
        'CreateUser' { 'User.Create' }
        'AssignRole' { 'User.ReadBasic.All'; 'RoleManagement.ReadWrite.Directory' }
    }
}

if (!(Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module -Name Microsoft.Graph.Authentication -Scope CurrentUser -Repository PSGallery -ErrorAction Stop
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop

# End any previous customer's session before signing into the target tenant.
if (Get-MgContext) { Disconnect-MgGraph -ErrorAction Stop | Out-Null }
Connect-MgGraph -TenantId $TenantId.ToString() -Scopes $Scopes -ContextScope Process -ErrorAction Stop
$context = Get-MgContext
if (!$context -or $context.TenantId -ne $TenantId.ToString()) {
    Disconnect-MgGraph -ErrorAction Stop | Out-Null
    throw 'The connected tenant does not match the requested tenant.'
}
$context | Select-Object TenantId, Account, Scopes, ContextScope
