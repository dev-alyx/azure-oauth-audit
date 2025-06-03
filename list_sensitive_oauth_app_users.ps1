<# USE CAUTION: Do not revoke OAuth consents without thorough technical and policy review. #>
param(
    [Parameter(Mandatory = $true,
        HelpMessage = "Enter ClientId/ServicePrincipalId of application (e.g. 4ab8c509-b21b-4b6e-bcaa-5d447c52dac5)")]
    [string]$ServicePrincipalId,

    [Parameter(Mandatory = $true,
        HelpMessage = "Enter path for exported CSV file (e.g. C:\temp\output.csv)")]
    [string]$CSVpath
)

Connect-MgGraph -Scopes "Application.Read.All"

# get service principal using id
$sp = Get-MgServicePrincipal -ServicePrincipalId $ServicePrincipalId

$results = @()

# pull role assignments
$assignments = Get-MgServicePrincipalAppRoleAssignedTo -ServicePrincipalId $sp.Id -All | Select-Object -Property Id, PrincipalDisplayName, PrincipalId, ResourceDisplayName, CreatedDateTime

foreach ($assignment in $assignments) {
    # get UPNs
    $user = Get-MgUser -UserId $assignment.PrincipalId -ErrorAction SilentlyContinue
    $results += [PSCustomObject]@{
        PrincipalDisplayName = $assignment.PrincipalDisplayName
        PrincipalId          = $assignment.PrincipalId
        ResourceDisplayName  = $assignment.ResourceDisplayName
        CreatedDateTime      = ($assignment.CreatedDateTime).ToString("yyMMdd-HHmmss")
        UserPrincipalName    = $user.UserPrincipalName
    }
}
$assignments = $results

# csv out
$assignments | Export-Csv -Path $CSVpath -NoTypeInformation