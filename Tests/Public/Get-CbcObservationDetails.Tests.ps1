using module ..\..\src\PSCarbonBlackCloud.Classes.psm1

BeforeAll {
	$ProjectRoot = (Resolve-Path "$PSScriptRoot/../..").Path
	Remove-Module -Name PSCarbonBlackCloud -ErrorAction 'SilentlyContinue' -Force
	Import-Module $ProjectRoot\src\PSCarbonBlackCloud.psm1 -Force
}

AfterAll {
	Remove-Module -Name PSCarbonBlackCloud -Force
}

Describe "Get-CbcObservationDetails" {
	Context "When using single connections " {
        BeforeEach {
            $Uri1 = "https://t.te1/"
            $Org1 = "test1"
            $secureToken1 = "test1" | ConvertTo-SecureString -AsPlainText
            $Uri2 = "https://t.te2/"
            $Org2 = "test2"
            $secureToken2 = "test2" | ConvertTo-SecureString -AsPlainText
            $s1 = [CbcServer]::new($Uri1, $Org1, $secureToken1)
            $s2 = [CbcServer]::new($Uri2, $Org2, $secureToken2)
            $global:DefaultCbcServers = [System.Collections.ArrayList]@()
            $global:DefaultCbcServers.Add($s1) | Out-Null
            $global:DefaultCbcServers.Add($s2) | Out-Null
            $global:called = $false
        }
        Context "When using the 'Id' parameter set" {
            It "Should set the HTTP Request Body accordingly" {
                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    @{
                        StatusCode = 200
                        Content    = Get-Content "$ProjectRoot/Tests/resources/observations_api/start_details_job.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["ObservationDetails"]["StartJob"] -and
                    $Method -eq "POST" -and
                    $Server -eq $s1
                }

                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    @{
                        StatusCode = 200
                        Content    = Get-Content "$ProjectRoot/Tests/resources/observations_api/results_details_job.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["ObservationDetails"]["Results"] -and
                    $Method -eq "GET" -and
                    $Server -eq $s1
                }

                $observation = Get-CbcObservationDetails -Id "d266ac1613e011ee9c5d536794589aaa:82a39c64-3e31-452d-6440-716d68040aaa" -Server $s1
                $observation.DeviceId | Should -Be 11412673
            }

            It "Should return CbcJob object" {
                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    @{
                        StatusCode = 200
                        Content    = Get-Content "$ProjectRoot/Tests/resources/observations_api/start_details_job.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["ObservationDetails"]["StartJob"] -and
                    $Method -eq "POST" -and
                    $Server -eq $s1
                }

                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    @{
                        StatusCode = 200
                        Content    = Get-Content "$ProjectRoot/Tests/resources/observations_api/results_details_job.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["ObservationDetails"]["Results"] -and
                    $Method -eq "GET" -and
                    $Server -eq $s1
                }

                $job = Get-CbcObservationDetails -Id "d266ac1613e011ee9c5d536794589aaa:82a39c64-3e31-452d-6440-716d68040aaa" -Server $s1 -AsJob
                $job.Status | Should -Be "Running"
                $job.Type | Should -Be "observation_details"
                $job | Should -Be CbcJob
            }

            It "Should fail with exception" {
                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    @{
                        StatusCode = 400
                        Content    = Get-Content "$ProjectRoot/Tests/resources/observations_api/start_details_job.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["ObservationDetails"]["StartJob"] -and
                    $Method -eq "POST" -and
                    $Server -eq $s1
                }

                {Get-CbcObservationDetails -Id "d266ac1613e011ee9c5d536794589aaa:82a39c64-3e31-452d-6440-716d68040aaa" -ErrorAction Stop} | Should -Throw 
                $Error[0] | Should -BeLike "Cannot create observation details job for*"
            }
        }
        Context "When using the 'AlertId' parameter set" {
            BeforeAll {
                $Uri1 = "https://t.te1/"
                $Org1 = "test1"
                $secureToken1 = "test1" | ConvertTo-SecureString -AsPlainText
                $Uri2 = "https://t.te2/"
                $Org2 = "test2"
                $secureToken2 = "test2" | ConvertTo-SecureString -AsPlainText
                $s1 = [CbcServer]::new($Uri1, $Org1, $secureToken1)
                $s2 = [CbcServer]::new($Uri2, $Org2, $secureToken2)
                $global:DefaultCbcServers = [System.Collections.ArrayList]@()
                $global:DefaultCbcServers.Add($s1) | Out-Null
                $global:DefaultCbcServers.Add($s2) | Out-Null
                $global:called = $false
            }
            It "Should set the HTTP Request Body accordingly" {
                $global:called = $false
                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    @{
                        StatusCode = 200
                        Content    = Get-Content "$ProjectRoot/Tests/resources/observations_api/start_details_job.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["ObservationDetails"]["StartJob"] -and
                    $Method -eq "POST" -and
                    ($Server -eq $s1 -or $Server -eq $s2) -and
                    ($Body | ConvertFrom-Json).alert_id -eq "82a39c64-3e31-452d-6440-716d68040524"
                }

                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    if (!$global:called) {
                        $global:called = $true
                        @{
                            StatusCode = 200
                            Content    = Get-Content "$ProjectRoot/Tests/resources/observations_api/results_search_job_running.json"
                        }
                    }
                    else {
                        @{
                            StatusCode = 200
                            Content    = Get-Content "$ProjectRoot/Tests/resources/observations_api/results_details_job.json"
                        }
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["ObservationDetails"]["Results"] -and
                    $Method -eq "GET" -and
                    ($Server -eq $s1 -or $Server -eq $s2)
                }

                $observations = Get-CbcObservationDetails -AlertId "82a39c64-3e31-452d-6440-716d68040524"
                $observations[0].AlertId[0] | Should -Be "82a39c64-3e31-452d-6440-716d68040524"
                $observations[1].AlertId[0] | Should -Be "82a39c64-3e31-452d-6440-716d68040524"
            }
        }
    }
    Context "When using multiple connections " {
        BeforeEach {
            $global:DefaultCbcServers = [System.Collections.ArrayList]@()
            $Uri = "https://t.te1/"
            $Org = "test1"
            $secureToken = "test1" | ConvertTo-SecureString -AsPlainText
            $s1 = [CbcServer]::new($Uri, $Org, $secureToken)
            $global:DefaultCbcServers.Add($s1) | Out-Null
            $Uri2 = "https://t.te2/"
            $Org2 = "test2"
            $secureToken2 = "test2" | ConvertTo-SecureString -AsPlainText
            $s2 = [CbcServer]::new($Uri2, $Org2, $secureToken2)
            $global:DefaultCbcServers.Add($s2) | Out-Null
        }
        Context "When using the 'Id' parameter set" {
            It "Should set the HTTP Request Body accordingly" {
                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    @{
                        StatusCode = 200
                        Content    = Get-Content "$ProjectRoot/Tests/resources/observations_api/start_details_job.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["ObservationDetails"]["StartJob"] -and
                    $Method -eq "POST" -and
                    ($Server -eq $s1 -or $Server -eq $s2)
                }

                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    @{
                        StatusCode = 200
                        Content    = Get-Content "$ProjectRoot/Tests/resources/observations_api/results_details_job.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["ObservationDetails"]["Results"] -and
                    $Method -eq "GET" -and
                    ($Server -eq $s1 -or $Server -eq $s2)
                }

                $observation = Get-CbcObservationDetails -Id "d266ac1613e011ee9c5d536794589aaa:82a39c64-3e31-452d-6440-716d68040aaa"
                $observation[0].DeviceId | Should -Be 11412673
                $observation.Count | Should -Be 2
            }
        }
        Context "When using the 'AlertId' parameter set" {
            It "Should set the HTTP Request Body accordingly" {
                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    @{
                        StatusCode = 200
                        Content    = Get-Content "$ProjectRoot/Tests/resources/observations_api/start_details_job.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["ObservationDetails"]["StartJob"] -and
                    $Method -eq "POST" -and
                    ($Server -eq $s1 -or $Server -eq $s2) -and
                    ($Body | ConvertFrom-Json).alert_id -eq "82a39c64-3e31-452d-6440-716d68040524"
                }

                Mock Invoke-CbcRequest -ModuleName PSCarbonBlackCloud {
                    @{
                        StatusCode = 200
                        Content    = Get-Content "$ProjectRoot/Tests/resources/observations_api/results_details_job.json"
                    }
                } -ParameterFilter {
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["ObservationDetails"]["Results"] -and
                    $Method -eq "GET" -and
                    ($Server -eq $s1 -or $Server -eq $s2)
                }

                $observations = Get-CbcObservationDetails -AlertId "82a39c64-3e31-452d-6440-716d68040524"
                $observations[0].AlertId[0] | Should -Be "82a39c64-3e31-452d-6440-716d68040524"
                $observations.Count | Should -Be 2
            }
        }
    }
}