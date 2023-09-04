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