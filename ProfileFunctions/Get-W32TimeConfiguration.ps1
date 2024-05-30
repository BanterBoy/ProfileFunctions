function Get-W32TimeConfiguration {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)]
        [string]$ComputerName = $env:COMPUTERNAME
    )

    try {
        $w32tmOutput = w32tm /query /configuration /computer:$ComputerName
    } catch {
        Write-Error "Failed to run w32tm command: $_"
        return
    }

    $outputLines = $w32tmOutput -split "`n"

    $outputObject = New-Object PSObject

    $outputObject | Add-Member -NotePropertyName "ComputerName" -NotePropertyValue $ComputerName

    $headings = @{
        "EventLogFlags" = "EventLogFlags";
        "AnnounceFlags" = "AnnounceFlags";
        "TimeJumpAuditOffset" = "TimeJumpAuditOffset";
        "MinPollInterval" = "MinPollInterval";
        "MaxPollInterval" = "MaxPollInterval";
        "MaxNegPhaseCorrection" = "MaxNegPhaseCorrection";
        "MaxPosPhaseCorrection" = "MaxPosPhaseCorrection";
        "MaxAllowedPhaseOffset" = "MaxAllowedPhaseOffset";
        "FrequencyCorrectRate" = "FrequencyCorrectRate";
        "PollAdjustFactor" = "PollAdjustFactor";
        "LargePhaseOffset" = "LargePhaseOffset";
        "SpikeWatchPeriod" = "SpikeWatchPeriod";
        "LocalClockDispersion" = "LocalClockDispersion";
        "HoldPeriod" = "HoldPeriod";
        "PhaseCorrectRate" = "PhaseCorrectRate";
        "UpdateInterval" = "UpdateInterval";
        "DllName" = "DllName";
        "Enabled" = "Enabled";
        "InputProvider" = "InputProvider";
        "CrossSiteSyncFlags" = "CrossSiteSyncFlags";
        "AllowNonstandardModeCombinations" = "AllowNonstandardModeCombinations";
        "ResolvePeerBackoffMinutes" = "ResolvePeerBackoffMinutes";
        "ResolvePeerBackoffMaxTimes" = "ResolvePeerBackoffMaxTimes";
        "CompatibilityFlags" = "CompatibilityFlags";
        "LargeSampleSkew" = "LargeSampleSkew";
        "SpecialPollInterval" = "SpecialPollInterval";
        "Type" = "Type"
    }

    foreach ($line in $outputLines) {
        foreach ($heading in $headings.Keys) {
            if ($line -match "$($heading):\s(.*)") {
                if (!($outputObject | Get-Member -Name $headings[$heading])) {
                    $outputObject | Add-Member -NotePropertyName $headings[$heading] -NotePropertyValue $Matches[1]
                }
                break
            }
        }
    }

    return $outputObject
}