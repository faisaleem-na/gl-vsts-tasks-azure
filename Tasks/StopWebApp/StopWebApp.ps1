[CmdletBinding()]
param()

Trace-VstsEnteringInvocation $MyInvocation

try {
    # Get inputs.
    $WebAppName = Get-VstsInput -Name WebAppName -Require
    $Slot = Get-VstsInput -Name Slot
    $StoppedUrl = Get-VstsInput -Name StoppedUrl

    # Initialize Azure.
    Import-Module $PSScriptRoot\ps_modules\VstsAzureHelpers_
    Initialize-Azure

    # Import the loc strings.
    Import-VstsLocStrings -LiteralPath $PSScriptRoot/Task.json
    
    $resourceGroupName = Get-WebAppResourceGroupName -webAppName $WebAppName

    if ($Slot) {    
        Write-VstsTaskVerbose -Message "[Azure Call] Stopping slot: $WebAppName / $Slot"
        $result = Stop-AzureRmWebAppSlot -ResourceGroupName $resourceGroupName -Name $WebAppName -Slot $Slot -Verbose
        Write-VstsTaskVerbose -Message "[Azure Call] Slot stopped: $WebAppName / $Slot"
    }
    else {
        Write-VstsTaskVerbose -Message "[Azure Call] Stopping Web App: $WebAppName"
        $result = Stop-AzureRmWebApp -ResourceGroupName $resourceGroupName -Name $WebAppName -Verbose
        Write-VstsTaskVerbose -Message "[Azure Call] Web App stopped: $WebAppName"
    }

    $scheme = "http"
    $hostName = $result.HostNames[0]
    foreach ($hostNameSslState in $result.HostNameSslStates) {
        if ($hostName -eq $hostNameSslState.Name) {
            if (-not $hostNameSslState.SslState -eq 0) {
                $scheme = "https"
            }

            break
        }
    }

    $urlValue = "${scheme}://$hostName"

    Write-Host (Get-VstsLocString -Key "WebappsuccessfullystoppedatUrl0" -ArgumentList $urlValue)

    # Set ouput variable with $destinationUrl
    if (-not [string]::IsNullOrEmpty($StoppedUrl)) {
        if ([string]::IsNullOrEmpty($StoppedUrl)) {
            Throw (Get-VstsLocString -Key "Unabletoretrievewebappurlforwebapp0" -ArgumentList $webAppName)
        }

        Set-VstsTaskVariable -Name $StoppedUrl -Value $urlValue
    }
}
finally {
    Trace-VstsLeavingInvocation $MyInvocation
}
