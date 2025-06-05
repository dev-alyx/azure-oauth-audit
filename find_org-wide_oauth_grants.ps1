<# USE CAUTION: Do not revoke OAuth consents without thorough technical and policy review. #>
param(
    [Parameter(Mandatory = $true, HelpMessage = "Enter path for exported CSV file (e.g. C:\temp\output.csv)")]
    [string]$CSVpath
)

Connect-MgGraph -Scopes "Application.Read.All"

# get AllPrincipals OAuth2 permission grants
$allPrincipalApps = Get-MgOauth2PermissionGrant -Filter "ConsentType eq 'AllPrincipals'" -All
$results = @()
foreach ($app in $allPrincipalApps) {
    $appResult = Get-MgServicePrincipal -Filter "Id eq '$($app.ClientId)'" -ErrorAction SilentlyContinue
    if ($appResult) {
        $results += [PSCustomObject]@{
            DisplayName = $appResult.DisplayName
            ConsentId   = $app.Id
            ClientId    = $app.ClientId
            ConsentType = $app.ConsentType
            Scope       = $app.Scope
        }
    } else {
        Write-Host "Service Principal with ClientId '$($app.ClientId)' not found."
    }
}

# pull role assignments
$results | Export-Csv -Path $CSVpath -NoTypeInformation