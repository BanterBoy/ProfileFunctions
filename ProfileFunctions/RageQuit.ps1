function RageQuit {
    <#
    .SYNOPSIS
    Forces the computer to shut down or restart immediately.

    .DESCRIPTION
    The RageQuit function stops or restarts the computer forcefully and immediately. This should be used with caution as it does not prompt the user for confirmation and may result in data loss if there are any unsaved changes.

    .PARAMETER Force
    If specified, the computer will be shut down or restarted without asking for user confirmation.

    .PARAMETER Restart
    If specified, the computer will be restarted instead of shut down.

    .INPUTS
    System.String. You can pipe a string that specifies the action ("Restart" or "Shutdown") to the function.

    .OUTPUTS
    None. This function does not produce any output.

    .NOTES
    Author: Your Name
    Date: 2024-06-30
    #>

    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, HelpMessage = "Force the shutdown or restart without asking for user confirmation.")]
        [switch]$Force,

        [Parameter(Mandatory = $false, HelpMessage = "Restart the computer instead of shutting it down.")]
        [switch]$Restart
    )

    begin {
        # Function to write to the event log
        function Write-EventLogEntry {
            param (
                [string]$Message,
                [string]$EventType = "Information"
            )
            $eventID = 1001 # Custom event ID
            $source = "RageQuit"
            $username = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
            if (-not (Get-EventLog -LogName Application -Source $source -ErrorAction SilentlyContinue)) {
                New-EventLog -LogName Application -Source $source
            }
            Write-EventLog -LogName Application -Source $source -EventID $eventID -EntryType $EventType -Message "$Message`nUser: $username"
        }
    }

    process {
        $action = if ($Restart) { "restart" } else { "shutdown" }
        if ($Force -or $PSCmdlet.ShouldContinue("This will forcefully $action your computer and may result in data loss. Do you want to continue?", "Confirm $action")) {
            if ($PSCmdlet.ShouldProcess("The computer", "Forceful $action")) {
                try {
                    Write-EventLogEntry -Message "$action initiated by RageQuit function." -EventType "Information"
                    if ($Restart) {
                        Restart-Computer -Force
                    }
                    else {
                        Stop-Computer -Force
                    }
                }
                catch {
                    Write-EventLogEntry -Message "Failed to $action the computer: $_" -EventType "Error"
                    Write-Error "Failed to $action the computer: $_"
                }
            }
        }
        else {
            Write-EventLogEntry -Message "$action cancelled by user." -EventType "Warning"
            Write-Output "$action cancelled by user."
        }
    }
}

# Example usage:
# RageQuit -Force
# RageQuit -Restart -Force

# Example usage with pipeline input:
# "Restart" | RageQuit -Force
# "Shutdown" | RageQuit -Force
