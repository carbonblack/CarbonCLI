using module ../PSCarbonBlackCloud.Classes.psm1
<#
.DESCRIPTION
This cmdlet returns all reports or specific report from all valid connections.
.LINK  
https://developer.carbonblack.com/reference/carbon-black-cloud/cb-threathunter/latest/feed-api
.SYNOPSIS
This cmdlet returns all reports or specific report from all valid connections.
.PARAMETER FeedId
Id of the Feed
.PARAMETER Feed
CbcFeed object
.PARAMETER Id
Specify the Id of the report to retrieve.
.OUTPUTS
CbcReport[]
.NOTES
Permissions needed: READ org.feeds
.EXAMPLE
PS > Get-CbcReport -FeedId 5hBIvXltQqy0oAAqdEh0A, jwUoZu1WRBujSoCcYNa6fA

Returns all reports for specific feed from all connections. 
If you have multiple connections and you want alerts from a specific connection
you can add the `-Server` param.

PS > Get-CbcReport -FeedId 5hBIvXltQqy0oAAqdEh0A, jwUoZu1WRBujSoCcYNa6fA -Server $SpecifiedServer
.EXAMPLE
PS > Get-CbcReport -FeedId 5hBIvXltQqy0oAAqdEh0A, jwUoZu1WRBujSoCcYNa6fA -Id 11a1a1a1-b22b-3333-44cc-dd5555d5d5fd, 11a1a1a1-b22b-3333-44cc-dd5555d5d5fs

Returns the report with specified Id under feed.
.EXAMPLE
PS > $Feed = Get-CbcFeed -Id 5hBIvXltQqy0oAAqdEh0A
PS > Get-CbcReport -Feed $Feed

Returns all reports for specific feed.

.EXAMPLE
PS > $Feed = Get-CbcFeed -Id 5hBIvXltQqy0oAAqdEh0A
PS > Get-CbcReport -Feed $Feed -Id 11a1a1a1-b22b-3333-44cc-dd5555d5d5fd

Returns report with specific id for specific feed.
#>

function Get-CbcReport {
    [CmdletBinding(DefaultParameterSetName = "Default")]
    [OutputType([CbcReport[]])]
    param(
        [Parameter(ParameterSetName = "Default", Position = 0, Mandatory = $true)]
        [string[]]$FeedId,

        [Parameter(ParameterSetName = "Feed", Position = 0, Mandatory = $true)]
        [CbcFeed[]]$Feed,

        [Parameter(ParameterSetName = "Default", Position = 1)]
        [Parameter(ParameterSetName = "Feed", Position = 1)]
        [Parameter(ParameterSetName = "Id", Position = 1)]
        [string[]]$Id,

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
                    $CurrentServer = $_
     
                    $FeedId | ForEach-Object {
                        $Response = Invoke-CbcRequest -Endpoint $global:CBC_CONFIG.endpoints["Report"]["Search"] `
                            -Method GET `
                            -Server $CurrentServer `
                            -Params @($_) `

                        if ($Response.StatusCode -ne 200) {
                            Write-Error -Message $("Cannot get reports(s) for $($CurrentServer)")
                        }
                        else {
                            $JsonContent = $Response.Content | ConvertFrom-Json
                            $JsonContent.results | ForEach-Object {
                                if ($PSBoundParameters.ContainsKey("Id")) {
                                    if ($Id.Contains($_.id)) {
                                        return Initialize-CbcReport $_ $CurrentServer
                                    }
                                }
                                else {
                                    return Initialize-CbcReport $_ $CurrentServer
                                }
                            }
                        }
                    }
                }
            }
            "Feed" {
                $Feed | ForEach-Object {
                    $FeedId = $_.id
                    $CurrentServer = $_.Server
                    $Response = Invoke-CbcRequest -Endpoint $global:CBC_CONFIG.endpoints["Report"]["Search"] `
                        -Method GET `
                        -Server $CurrentServer `
                        -Params $FeedId `

                    if ($Response.StatusCode -ne 200) {
                        Write-Error -Message $("Cannot get reports(s) for $($CurrentServer)")
                    }
                    else {
                        $JsonContent = $Response.Content | ConvertFrom-Json
                        $JsonContent.results | ForEach-Object {
                            if ($PSBoundParameters.ContainsKey("Id")) {
                                if ($Id.Contains($_.id)) {
                                    return Initialize-CbcReport $_ $CurrentServer
                                }
                            }
                            else {
                                return Initialize-CbcReport $_ $CurrentServer
                            }
                        }
                    }
                }
            }
        }
    }
}