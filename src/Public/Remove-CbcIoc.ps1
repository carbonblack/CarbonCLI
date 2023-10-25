using module ../PSCarbonBlackCloud.Classes.psm1
<#
.DESCRIPTION
This cmdlet removes ioc from all valid connections.
.LINK  
https://developer.carbonblack.com/reference/carbon-black-cloud/cb-threathunter/latest/ioc-api
.SYNOPSIS
This cmdlet removes ioc from all valid connections.
.PARAMETER Id
Filter param: Specify the Id of the ioc to remove.
.PARAMETER Ioc
Filter param: Specify the CbcIoc to remove.
.PARAMETER Server
Sets a specified Cbc Server from the current connections to execute the cmdlet with.
.NOTES
Permissions needed: DELETE org.feeds
.EXAMPLE
PS > Delete-CbcIoc -Id R4cMgFIhRaakgk749MRr6Q

Removes ioc with specific ids from all connections. 
If you have multiple connections and you want ioc from a specific connection
you can add the `-Server` param.

PS > Delete-CbcIoc -Id R4cMgFIhRaakgk749MRr6Q -Server $SpecifiedServer
.EXAMPLE
PS > $ioc = Get-CbcIoc -Id R4cMgFIhRaakgk749MRr6Q
PS > Delete-CbcIoc -Ioc $ioc

Removes specific ioc by proving CbcIoc
#>

function Remove-CbcIoc {
    [CmdletBinding(DefaultParameterSetName = "Default")]
    param(
        [Parameter(ParameterSetName = "Default", Mandatory = $true)]
        [string]$FeedId,

        [Parameter(ParameterSetName = "Default", Mandatory = $true)]
        [string]$ReportId,

        [Parameter(ParameterSetName = "Default", Mandatory = $true)]
        [string[]]$Id,

        [Parameter(ParameterSetName = "Ioc", Mandatory = $true)]
        [CbcIoc[]]$Ioc,

        [Parameter(ParameterSetName = "Default")]
        [CbcServer[]]$Server
    )

    process {
        if ($Server) {
            $ExecuteServers = $Server
        }
        else {
            $ExecuteServers = $global:DefaultCbcServers
        }
       
        switch ($PSCmdlet.ParameterSetName) {
            "Default" {
                $ExecuteServers | ForEach-Object {
                    $Report = Get-CbcReport -FeedId $FeedId -Id $ReportId -Server $_
                    $RequestBody = @{}
                    $UpdatedReport = @{}
                    $UpdatedReport.title = $Report.Title
                    $UpdatedReport.description = $Report.Description
                    $UpdatedReport.severity = $Report.Severity
                    $UpdatedReport.timestamp = [int](Get-Date -UFormat %s -Millisecond 0)
                    $UpdatedReport.id = $Report.Id
                    $UpdatedReport.iocs_v2 = @()
                    if ($Report.IocsV2.Count -gt 1) {
                        $Report.IocsV2 | ForEach-Object {
                            if (!$Id.Contains($_.id)) {
                                $UpdatedReport.iocs_v2 += $_
                            }
                        }
                        $RequestBody = $UpdatedReport        
                        $RequestBody = $RequestBody | ConvertTo-Json -Depth 100
        
                        $Response = Invoke-CbcRequest -Endpoint $global:CBC_CONFIG.endpoints["Report"]["Details"] `
                            -Method PUT `
                            -Server $_ `
                            -Params @($FeedId, $ReportId) `
                            -Body $RequestBody
        
                        if ($Response.StatusCode -ne 200) {
                            Write-Error -Message $("Cannot remove iocs for $($_)")
                        }
                        else {
                            Write-Debug -Message $("Ioc(s) successfully deleted.")
                        }
                    }
                }
            }
            "Ioc" {
                $IocGroups = $Ioc | Group-Object -Property Server, ReportId
                foreach ($Group in $IocGroups) {
                    $IocsToDelete = @()
                    foreach ($CurrIoc in $Group.Group) {
                        $IocsToDelete += $CurrIoc.Id
                        $CurrentServer = $CurrIoc.Server
                        $CurrentReportId = $CurrIoc.ReportId
                        $CurrentFeedId = $CurrIoc.FeedId
                    }
                    $RequestBody = @{}
                    $Report = Get-CbcReport -FeedId $CurrentFeedId -Id $CurrentReportId -Server $CurrentServer
                    $UpdatedReport = @{}
                    $UpdatedReport.title = $Report.Title
                    $UpdatedReport.description = $Report.Description
                    $UpdatedReport.severity = $Report.Severity
                    $UpdatedReport.timestamp = [int](Get-Date -UFormat %s -Millisecond 0)
                    $UpdatedReport.id = $Report.Id
                    $UpdatedReport.iocs_v2 = @()
                    if ($Report.IocsV2.Count -gt 1) {
                        $Report.IocsV2 | ForEach-Object {
                            if (!$IocsToDelete.Contains($_.id)) {
                                $UpdatedReport.iocs_v2 += $_
                            }
                        }
                        $RequestBody = $UpdatedReport        
                        $RequestBody = $RequestBody | ConvertTo-Json -Depth 100
        
                        $Response = Invoke-CbcRequest -Endpoint $global:CBC_CONFIG.endpoints["Report"]["Details"] `
                            -Method PUT `
                            -Server $CurrentServer `
                            -Params @($CurrentFeedId, $CurrentReportId) `
                            -Body $RequestBody
        
                        if ($Response.StatusCode -ne 200) {
                            Write-Error -Message $("Cannot remove iocs for $($CurrentServer)")
                        }
                        else {
                            Write-Debug -Message $("Ioc(s) successfully deleted.")
                        }
                    }
                }
            }
        }
    }
}