<#
.SYNOPSIS
Retrieves the last Group Policy update time for a specified computer.

.DESCRIPTION
The Get-LastGPOUpdateTime function queries the registry of a remote computer to retrieve the last Group Policy update time. It calculates the time span since the last update and returns the result as a custom object.

.PARAMETER ComputerName
The name of the computer to query.

.EXAMPLE
Get-LastGPOUpdateTime -ComputerName "Computer01"
This example retrieves the last Group Policy update time for the computer named "Computer01".

.OUTPUTS
The function returns a custom object with the following properties:
- ComputerName: The name of the computer.
- LastGPOUpdateTime: The date and time of the last Group Policy update.
- DaysSinceLastUpdate: The number of days since the last update.
- TimeSinceLastUpdate: The time span since the last update in the format "hours, minutes, seconds".

.NOTES
Author: Your Name
Date: Today's Date
Version: 1.0
#>
function Get-LastGPOUpdateTime {
    param (
        [Parameter(Mandatory=$true)]
        [string]$ComputerName
    )

    try {
        $gpResult = Invoke-Command -ComputerName $ComputerName -ScriptBlock {
            [datetime]::FromFileTime(([Int64] ((Get-ItemProperty -Path "Registry::HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Group Policy\State\Machine\Extension-List\{00000000-0000-0000-0000-000000000000}").startTimeHi) -shl 32) -bor ((Get-ItemProperty -Path "Registry::HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Group Policy\State\Machine\Extension-List\{00000000-0000-0000-0000-000000000000}").startTimeLo))
        }
        $lastGPUpdateDate = Get-Date ($gpResult[0])
        $timeSinceLastUpdate = New-TimeSpan -Start $lastGPUpdateDate -End (Get-Date)

        $result = New-Object PSObject
        $result | Add-Member -Type NoteProperty -Name "ComputerName" -Value $ComputerName
        $result | Add-Member -Type NoteProperty -Name "LastGPOUpdateTime" -Value $lastGPUpdateDate
        $result | Add-Member -Type NoteProperty -Name "DaysSinceLastUpdate" -Value $timeSinceLastUpdate.Days
        $result | Add-Member -Type NoteProperty -Name "TimeSinceLastUpdate" -Value ("{0} hours, {1} minutes, {2} seconds" -f $timeSinceLastUpdate.Hours, $timeSinceLastUpdate.Minutes, $timeSinceLastUpdate.Seconds)

        return $result
    }
    catch {
        $errMsg = $_.Exception.Message
        Write-Verbose "An error occurred while querying the Group Policy update time on $($ComputerName): $errMsg"

        $errorDetails = New-Object PSObject
        $errorDetails | Add-Member -Type NoteProperty -Name "ComputerName" -Value $ComputerName
        $errorDetails | Add-Member -Type NoteProperty -Name "Error" -Value $errMsg

        return $errorDetails
    }
}