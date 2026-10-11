# Create a cloud-only member user in the already connected customer's tenant.
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [guid]$TenantId,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$DisplayName,

    [Parameter(Mandatory)]
    [ValidatePattern('^[^\s@]+@[^\s@]+\.[^\s@]+$')]
    [string]$UserPrincipalName,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$MailNickname,

    [Parameter(Mandatory)]
    [ValidatePattern('^[A-Za-z]{2}$')]
    [string]$UsageLocation,

    [string]$GivenName,
    [string]$Surname
)

if ($TenantId -eq [guid]::Empty) { throw 'TenantId cannot be empty.' }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
$context = Get-MgContext
if (!$context -or $context.TenantId -ne $TenantId.ToString()) {
    throw 'Connect to the requested tenant with MicrosoftGraph.ps1 before creating the user.'
}
if ($context.AuthType -ne 'Delegated' -or $context.Environment -ne 'Global') {
    throw 'This script requires a delegated session in the Global Microsoft Graph environment.'
}

$password = Read-Host 'Enter the temporary password' -AsSecureString
if ($password.Length -eq 0) { $password.Dispose(); throw 'The password cannot be empty.' }
$passwordPointer = [IntPtr]::Zero
$payload = $null
$json = $null
try {
    $passwordPointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($password)
    $payload = @{
        accountEnabled = $true
        displayName = $DisplayName
        mailNickname = $MailNickname
        usageLocation = $UsageLocation.ToUpperInvariant()
        userPrincipalName = $UserPrincipalName
        passwordProfile = @{
            forceChangePasswordNextSignIn = $true
            password = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($passwordPointer)
        }
    }
    if ($GivenName) { $payload.givenName = $GivenName }
    if ($Surname) { $payload.surname = $Surname }
    $json = $payload | ConvertTo-Json -Depth 3

    Write-Host 'Creating new user'
    $createdUser = Invoke-MgGraphRequest -Method POST -Uri 'https://graph.microsoft.com/v1.0/users' -Body $json -ContentType 'application/json' -OutputType PSObject -ErrorAction Stop
    if (!$createdUser.id) { throw 'Graph did not return a created user ID. Check the tenant before retrying.' }
    Write-Host 'User created successfully'
    $createdUser | Select-Object id, displayName, userPrincipalName
} finally {
    if ($passwordPointer -ne [IntPtr]::Zero) {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($passwordPointer)
    }
    if ($payload) { $payload.passwordProfile.password = $null }
    $json = $null
    $password.Dispose()
}
