using module ..\..\CarbonCLI\CarbonCLI.Classes.psm1

BeforeAll {
	$ProjectRoot = (Resolve-Path "$PSScriptRoot/../..").Path
	Remove-Module -Name CarbonCLI -ErrorAction 'SilentlyContinue' -Force
	Import-Module $ProjectRoot\CarbonCLI\CarbonCLI.psm1 -Force
}

AfterAll {
	Remove-Module -Name CarbonCLI -Force
}

Describe "Receive-CbcJob" {
	Context "When using multiple connections with a specific server" {
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
            $job = [CbcJob]::new("xxx", "observation_search", "Running", $s1)
		}

		It "Should return jobs (completed) only from the specific server" {
			Mock Invoke-CbcRequest -ModuleName CarbonCLI {
				@{
					StatusCode = 200
					Content    = Get-Content "$ProjectRoot/Tests/resources/observations_api/results_search_job.json"
				}
			} -ParameterFilter {
				$Endpoint -eq $global:CBC_CONFIG.endpoints["Observations"]["Results"] -and
				$Server -eq $s1 -and
				$Method -eq "GET"
			}

			$observations = Receive-CbcJob -Id "xxx" -Type "observation_search" -Server @($s1)
			$observations.Count | Should -Be 1
			$observations[0].Server | Should -Be $s1
            $observations[0] | Should -Be CbcObservation
		}

		It "Should return jobs (completed) only from the specific server by job object" {
			Mock Invoke-CbcRequest -ModuleName CarbonCLI {
				@{
					StatusCode = 200
					Content    = Get-Content "$ProjectRoot/Tests/resources/observations_api/results_search_job.json"
				}
			} -ParameterFilter {
				$Endpoint -eq $global:CBC_CONFIG.endpoints["Observations"]["Results"] -and
				$Server -eq $s1 -and
				$Method -eq "GET"
			}

			$observations = Receive-CbcJob -Job $job
			$observations.Count | Should -Be 1
			$observations[0].Server | Should -Be $s1
			$observations[0] | Should -Be CbcObservation
		}

		It "Should not return jobs (still running) only from the specific server by job object" {
			Mock Invoke-CbcRequest -ModuleName CarbonCLI {
				@{
					StatusCode = 200
					Content    = Get-Content "$ProjectRoot/Tests/resources/observations_api/results_search_job_running.json"
				}
			} -ParameterFilter {
				$Endpoint -eq $global:CBC_CONFIG.endpoints["Observations"]["Results"] -and
				$Server -eq $s1 -and
				$Method -eq "GET"
			}

			{Receive-CbcJob -Job $job -ErrorAction Stop} | Should -Throw
            $Error[0] | Should -Be "Not ready to retrieve."
		}

        It "Should not return jobs due to error" {
			Mock Invoke-CbcRequest -ModuleName CarbonCLI {
                @{
                    StatusCode = 400
                    Content    = Get-Content "$ProjectRoot/Tests/resources/observations_api/results_search_job_running.json"
                }
			} -ParameterFilter {
				$Endpoint -eq $global:CBC_CONFIG.endpoints["Observations"]["Results"] -and
				$Method -eq "GET"
			}

			{Receive-CbcJob -Job @($job) -ErrorAction Stop} | Should -Throw
            $Error[0] | Should -BeLike "Cannot complete action for xxx for*"
			
		}
	}

	Context "When using multiple connections" {
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
            $job1 = [CbcJob]::new("xxx", "observation_search", "Running", $s1)
            $job2 = [CbcJob]::new("xxx2", "observation_details", "Running", $s2)
			$job3 = [CbcJob]::new("xxx3", "process_search", "Running", $s1)
            $job4 = [CbcJob]::new("xxx4", "process_details", "Running", $s2)
		}

		It "Should return one job (the other still running)" {
			Mock Invoke-CbcRequest -ModuleName CarbonCLI {
                if ($Endpoint -eq $global:CBC_CONFIG.endpoints["Observations"]["Results"]) {
                    @{
                        StatusCode = 200
                        Content    = Get-Content "$ProjectRoot/Tests/resources/observations_api/results_search_job_running.json"
                    }
                }
                else {
                    @{
                        StatusCode = 200
                        Content    = Get-Content "$ProjectRoot/Tests/resources/observations_api/results_search_job.json"
                    }
                }
			} -ParameterFilter {
				(
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Observations"]["Results"] -or
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["ObservationDetails"]["Results"]
                ) -and
				$Method -eq "GET"
			}

			$observations = Receive-CbcJob -Job @($job1, $job2)
			$observations.Count | Should -Be 1
			$observations[0].Server | Should -Be $s2
			$observations[0] | Should -Be CbcObservationDetails
		}

		It "Should return one process job (the other still running)" {
			Mock Invoke-CbcRequest -ModuleName CarbonCLI {
                if ($Endpoint -eq $global:CBC_CONFIG.endpoints["ProcessDetails"]["Results"]) {
                    @{
                        StatusCode = 200
                        Content    = Get-Content "$ProjectRoot/Tests/resources/process_api/results_search_job_running.json"
                    }
                }
                else {
                    @{
                        StatusCode = 200
                        Content    = Get-Content "$ProjectRoot/Tests/resources/process_api/results_search_job.json"
                    }
                }
			} -ParameterFilter {
				(
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Processes"]["Results"] -or
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["ProcessDetails"]["Results"]
                ) -and
				$Method -eq "GET"
			}

			$processes = Receive-CbcJob -Job @($job3, $job4)
			$processes.Count | Should -Be 1
			$processes[0].Server | Should -Be $s1
			$processes[0] | Should -Be CbcProcess
		}

		It "Should return one process details job (the other still running)" {
			Mock Invoke-CbcRequest -ModuleName CarbonCLI {
                if ($Endpoint -eq $global:CBC_CONFIG.endpoints["Processes"]["Results"]) {
                    @{
                        StatusCode = 200
                        Content    = Get-Content "$ProjectRoot/Tests/resources/process_api/results_search_job_running.json"
                    }
                }
                else {
                    @{
                        StatusCode = 200
                        Content    = Get-Content "$ProjectRoot/Tests/resources/observations_api/results_search_job.json"
                    }
                }
			} -ParameterFilter {
				(
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Processes"]["Results"] -or
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["ProcessDetails"]["Results"]
                ) -and
				$Method -eq "GET"
			}

			$processes = Receive-CbcJob -Job @($job3, $job4)
			$processes.Count | Should -Be 1
			$processes[0].Server | Should -Be $s2
			$processes[0] | Should -Be CbcProcessDetails
		}


        It "Should not return any jobs wrong type" {
            {Receive-CbcJob -Id "xxx" -Type "alabala" -ErrorAction Stop} | Should -Throw
            $Error[0] | Should -BeLike "Not a valid type alabala"
		}

        It "Should return jobs (completed) from one server" {
			Mock Invoke-CbcRequest -ModuleName CarbonCLI {
                if ($Endpoint -eq $global:CBC_CONFIG.endpoints["Observations"]["Results"]) {
                    @{
                        StatusCode = 200
                        Content    = Get-Content "$ProjectRoot/Tests/resources/observations_api/results_search_job.json"
                    }
                }
                else {
                    @{
                        StatusCode = 400
                        Content    = Get-Content "$ProjectRoot/Tests/resources/observations_api/results_search_job.json"
                    }
                }
			} -ParameterFilter {
				(
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["Observations"]["Results"] -or
                    $Endpoint -eq $global:CBC_CONFIG.endpoints["ObservationDetails"]["Results"]
                ) -and
				$Method -eq "GET"
			}

			$observations = Receive-CbcJob -Job @($job1, $job2)
			$observations.Count | Should -Be 1
			$observations[0].Server | Should -Be $s1
            $observations[0] | Should -Be CbcObservation
		}
	}
}