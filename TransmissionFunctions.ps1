<#
.SYNOPSIS
Updates transmission to use default settings:

SeedRatioLimit:         0
SeedRatioLimited:       $True 
IncompleteDirectory:    "/share/Download/transmission/incomplete" 
DownloadDirectory:      "/share/Download/transmission/completed" 
DownloadQueueSize:      15

.EXAMPLE
Set-TransmissionDefaultSettings
#>
function Set-TransmissionDefaultSettings {
    $path = "/share/Download/transmission"

	Set-TransmissionSession -SeedRatioLimit 0 -SeedRatioLimited $True -IncompleteDirectory "$path/incomplete" -DownloadDirectory "$path/completed" -DownloadQueueSize 15
}

<#
.SYNOPSIS
Checks to see if the transmission download directory is "/share/Download/transmission/completed", and updates to default settings if not.

.EXAMPLE
Test-TransmissionSettings
#>
function Test-TransmissionSettings {
    $path = "/share/Download/transmission"

    try {
        $session = Get-TransmissionSession

        if ($session.DownloadDirectory -ne "$path/completed") {
            Write-Host "Transmission settings have reverted, updating to default..."

            Set-TransmissionDefaultSettings
        }
    }
    catch {
        Write-Warning -Message "Failed to get transmission settings, NAS may be offline..."
    }
}