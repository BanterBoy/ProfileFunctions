function Get-W32TimeSource {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)]
        [string]$ComputerName = $env:COMPUTERNAME
    )

    try {
        $w32tmOutput = w32tm /query /status /verbose /computer:$ComputerName
    } catch {
        Write-Error "Failed to run w32tm command: $_"
        return
    }

    $outputLines = $w32tmOutput -split "`n"

    $outputObject = New-Object PSObject

    $outputObject | Add-Member -NotePropertyName "ComputerName" -NotePropertyValue $ComputerName

    $headings = @{
        "Leap Indicator" = "LeapIndicator";
        "Stratum" = "Stratum";
        "Precision" = "Precision";
        "Root Delay" = "RootDelay";
        "Root Dispersion" = "RootDispersion";
        "ReferenceId" = "ReferenceId";
        "Last Successful Sync Time" = "LastSuccessfulSyncTime";
        "Source" = "Source";
        "Poll Interval" = "PollInterval";
        "Phase Offset" = "PhaseOffset";
        "ClockRate" = "ClockRate";
        "State Machine" = "StateMachine";
        "Time Source Flags" = "TimeSourceFlags";
        "Server Role" = "ServerRole";
        "Last Sync Error" = "LastSyncError";
        "Time since Last Good Sync Time" = "TimeSinceLastGoodSyncTime"
    }

    foreach ($line in $outputLines) {
        foreach ($heading in $headings.Keys) {
            if ($line -match "$($heading):\s(.*)") {
                $outputObject | Add-Member -NotePropertyName $headings[$heading] -NotePropertyValue $Matches[1]
                break
            }
        }
    }

    return $outputObject
}