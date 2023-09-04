# Automatically Sync Team Site Libraries

This is a part of phase 1 of your migration from your on-prem file servers to the M365 cloud file system.

- Install [PnP Powershell](https://pnp.github.io/powershell/) module
    - You will need to grant admin consent for the tenant. If you're not a global admin, get help from one.
- Have a tenant admin account credential for use with this script.
- Know your tenant Sharepoint Admin URL
    - Something like `https://YourOrgName-admin.sharepoint.com`

## Microsoft Learn
> https://learn.microsoft.com/en-us/sharepoint/use-group-policy#configure-team-site-libraries-to-sync-automatically

## Script Details

Copy the block of code below and save it to a file named `Get-SPOSiteIds.ps1`.

You can then execute it in a shell with `.\Get-SPOSiteIds.ps1`.

You will be prompted for your Sharepoint Admin Site URL, an Outfile path, and an Error file path. Files should be `.csv` type. If files exist, they will be deleted by the script.

You can also specify the arguments in the script invocation: `.\Get-SPOSiteIds.ps1 -AdminSiteUrl "https://YourOrgName-admin.sharepoint.com" -OutFile "~\Documents\SPO-Site-Ids.csv" -ErrorFile "~\Documents\SPO-Id-Script-Errors.csv"`

```powershell
[CmdletBinding()]
param (
    [Parameter(Mandatory)][String]$AdminSiteUrl,
    [Parameter(Mandatory)][String]$OutFile,
    [Parameter(Mandatory)][String]$ErrorFile
)

# Logging function
Function Send-LogMsgToFile {
    [CmdletBinding()]
    param (
        [Parameter()][String]$Title,
        [Parameter()][String]$SiteId,
        [Parameter()][Switch]$Err
    )
    if ($Err) {
        $file = $ErrorFile
    } else {
        $file = $OutFile
    }
    if (!(Test-Path -Path $file -PathType Leaf)) {
        New-Item $file -Type File 
    }
    [PSCustomObject]@{"TimeStamp"=(Get-Date -Format yyyy-MM-dd-HH:mm:ss);"Title"="$Title";"SiteId"="$SiteId"} | Export-Csv -Path $file -Append -NoTypeInformation
}

# Doing the work
Connect-PnPOnline -Url $AdminSiteUrl -Interactive
$TenantId = Get-PnPTenantId
Get-PnPTenantSite -Detailed | ? { $_.Template -eq "GROUP#0" } | Select Title, URL | % {
    $Title = $_.Title
    $Url = $_.Url
    Connect-PnPOnline -Url $Url -Interactive
    Try {
        $SiteId = ((Get-PnPSite -Includes ID).Id).Guid
        $WebId = ((Get-PnPWeb -Includes ID).Id).Guid
        $ListId = (Get-PnPList -Includes ID | ? {$_.Title -eq "Documents"}).Id
        $WebUrl = "$Url&version=1"
        $FullId = "tenantId=$TenantId&siteId={$SiteId}&webId={$WebId}&listId={$ListId}&webUrl=$WebUrl"
        Send-LogMsgToFile -Title $Title -SiteId $FullId
    } Catch {
        Write-Error $Error[0]
    }
}
```