function RageQuit {
	<#
    .SYNOPSIS
    Forces the computer to shut down immediately.

    .DESCRIPTION
    The RageQuit function stops the computer forcefully and immediately. This should be used with caution as it does not prompt the user for confirmation and may result in data loss if there are any unsaved changes.

    .PARAMETER LogPath
    The path where the log file should be created. If not provided, logs will be saved in the user's temp directory.

    .PARAMETER Force
    If specified, the computer will be shut down without asking for user confirmation.

    .EXAMPLE
    RageQuit -LogPath "C:\Logs\shutdown.log" -Force
    Forcefully shuts down the computer and logs the action to C:\Logs\shutdown.log.

    .EXAMPLE
    RageQuit -Force
    Forcefully shuts down the computer without logging.

    .INPUTS
    None. You cannot pipe objects to this function.

    .OUTPUTS
    None. This function does not produce any output.

    .NOTES
    Author: Your Name
    Date: 2024-06-30
    #>

	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[Parameter(Mandatory = $false, HelpMessage = "The path where the log file should be created.")]
		[string]$LogPath = "$env:TEMP\shutdown.log",

		[Parameter(Mandatory = $false, HelpMessage = "Force the shutdown without asking for user confirmation.")]
		[switch]$Force
	)

	begin {
		# Import PoshLog and initialize logging
		Import-Module PoshLog
		$log = New-Logger -FileSink -FilePath $LogPath -MinLevel Debug
		$log.LogInformation("RageQuit function initiated.")

		function Write-Log {
			param (
				[string]$Message,
				[string]$Level = "Information"
			)
			try {
				switch ($Level) {
					"Information" { $log.LogInformation($Message) }
					"Warning" { $log.LogWarning($Message) }
					"Error" { $log.LogError($Message) }
					default { $log.LogInformation($Message) }
				}
			}
			catch {
				Write-Error "Failed to write log: $_"
			}
		}
	}

	process {
		if ($Force -or $PSCmdlet.ShouldContinue("This will forcefully shut down your computer and may result in data loss. Do you want to continue?", "Confirm Shutdown")) {
			if ($PSCmdlet.ShouldProcess("The computer", "Forceful shutdown")) {
				try {
					Write-Log "Shutdown initiated by RageQuit function."
					Stop-Computer -Force
				}
				catch {
					Write-Log "Failed to shutdown the computer: $_" "Error"
					Write-Error "Failed to shutdown the computer: $_"
				}
			}
		}
		else {
			Write-Log "Shutdown cancelled by user." "Warning"
			Write-Output "Shutdown cancelled by user."
		}
	}
}

# Example usage
# RageQuit -LogPath "C:\Logs\shutdown.log" -Force
