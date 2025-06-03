<# USE CAUTION: Do not revoke OAuth consents without thorough technical and policy review. #>
param(
    [Parameter(Mandatory = $true, HelpMessage = "Enter path for exported CSV file (e.g. C:\temp\output.csv)")]
    [string]$CSVpath
)

# sensitive OAuth scopes
$scopeFilters = @(
    'Files.Read',
    'Files.Read.All',
    'Sites.Read.All',
    'MyFiles.Read',
    'AllSites.Read'
)

Connect-MgGraph -Scopes "Application.Read.All"

# get, filter OAuth2 perm grants
$results = @()

$grants = Get-MgOauth2PermissionGrant -All |
    Where-Object {
        $scope = $_.Scope
        $scopeFilters.Where({ $scope -like "*$_*" }).Count -gt 0
    }

# cache for clientId->displayName mapping
# this avoids making multiple api calls, takes less time
$clientIdToDisplayName = @{}

$grants | ForEach-Object {
    $clientId = $_.ClientId
    if (-not $clientIdToDisplayName.ContainsKey($clientId)) {
        $sp = Get-MgServicePrincipal -Filter "Id eq '$clientId'" -ErrorAction SilentlyContinue
        $displayName = if ($sp) { $sp.DisplayName } else { $null }
        $clientIdToDisplayName[$clientId] = $displayName
    } else {
        $displayName = $clientIdToDisplayName[$clientId]
    }
    $results += [PSCustomObject]@{
        ClientId    = $clientId
        Scope       = $_.Scope
        ConsentType = $_.ConsentType
        DisplayName = $displayName
    }
}

# csv out
$results | Export-Csv -Path $CSVpath -NoTypeInformation

<#
Per Microsoft, to revoke permissions granted to a specific application, you can use the following command:

Remove-MgOauth2PermissionGrant -OAuth2PermissionGrantId #<OAuth2PermissionGrantId>

Where `OAuth2PermissionGrantId` is the `Id` value from the `Get-MgOauth2PermissionGrant` output.
This command will only revoke the permissions granted to that application by the specified user, not all consents for that application.

To revoke all permissions granted to an application, you can use the following command:

Get-MgOauth2PermissionGrant -Filter "ClientId eq '$ServicePrincipalId'" | ForEach-Object {
    Remove-MgOauth2PermissionGrant -OAuth2PermissionGrantId $_.Id
}

Where `$ServicePrincipalId` is the `ClientId` of the service principal for which you want to revoke all consented permissions.
#>