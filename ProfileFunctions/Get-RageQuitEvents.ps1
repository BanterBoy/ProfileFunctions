function Get-RageQuitEvents {
    <#
    .SYNOPSIS
    Retrieves event log entries for the RageQuit function.

    .DESCRIPTION
    This function retrieves event log entries that are generated by the RageQuit function from the Windows Application event log.

    .PARAMETER StartTime
    The start time from which to begin retrieving logs. If not specified, defaults to 24 hours ago.

    .PARAMETER EndTime
    The end time until which to retrieve logs. If not specified, defaults to the current time.

    .EXAMPLE
    Get-RageQuitEvents -StartTime (Get-Date).AddDays(-7)
    Retrieves all RageQuit-related logs from the past week.

    .EXAMPLE
    Get-RageQuitEvents
    Retrieves all RageQuit-related logs from the past 24 hours.

    .INPUTS
    None. You cannot pipe objects to this function.

    .OUTPUTS
    System.Diagnostics.EventLogEntry
    This function outputs event log entries related to RageQuit.

    .NOTES
    Author: Your Name
    Date: 2024-06-30
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "The start time from which to begin retrieving logs.")]
        [datetime]$StartTime = (Get-Date).AddHours(-24),

        [Parameter(Mandatory = $false, HelpMessage = "The end time until which to retrieve logs.")]
        [datetime]$EndTime = (Get-Date)
    )

    process {
        try {
            $logName = "Application"
            $source = "RageQuit"
            $eventID = 1001

            Write-Verbose "Retrieving event log entries for source '$source' from '$logName' log between $StartTime and $EndTime."

            $events = Get-EventLog -LogName $logName -Source $source -After $StartTime -Before $EndTime -ErrorAction Stop

            if ($events) {
                $filteredEvents = $events | Where-Object { $_.EventID -eq $eventID }
                if ($filteredEvents) {
                    Write-Verbose "Found $($filteredEvents.Count) event(s) related to RageQuit."
                    $filteredEvents | ForEach-Object {
                        $userMatch = $_.Message -match "User: (.+)"
                        [pscustomobject]@{
                            Index              = $_.Index
                            TimeGenerated      = $_.TimeGenerated
                            EntryType          = $_.EntryType
                            InstanceId         = $_.InstanceId
                            Source             = $_.Source
                            UserName           = if ($userMatch) { $matches[1] } else { "N/A" }
                            Message            = $_.Message
                            TimeWritten        = $_.TimeWritten
                            CategoryNumber     = $_.CategoryNumber
                            Category           = $_.Category
                            ReplacementStrings = $_.ReplacementStrings
                        }
                    }
                }
                else {
                    Write-Output "No RageQuit events found in the specified time range."
                }
            }
            else {
                Write-Output "No events found for source '$source' in the specified time range."
            }
        }
        catch {
            Write-Error "Failed to retrieve event log entries: $_"
        }
    }
}

# Example usage
# Get-RageQuitEvents -StartTime (Get-Date).AddDays(-7) -Verbose
# Get-RageQuitEvents -Verbose
