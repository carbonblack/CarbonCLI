using module ../CarbonCLI.Classes.psm1

function Initialize-CbcProcess {
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [PSCustomObject]$Response,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [CbcServer]$Server
    )
    [CbcProcess]::new(
        $Response.process_guid,
        $Response.alert_category,
        $Response.alert_id,
        $Response.backend_timestamp,
        $Response.blocked_hash,
        $Response.device_external_ip,
        $Response.device_id,
        $Response.device_internal_ip,
        $Response.device_os,
        $Response.device_policy,
        $Response.device_policy_id,
        $Response.device_sensor_version,
        $Response.event_type,
        $Response.parent_guid,
        $Response.process_cmdline,
        $Response.process_effective_reputation,
        $Response.process_guid,
        $Response.process_hash,
        $Response.process_name,
        $Response.ttp,
        $Server
    )
}
