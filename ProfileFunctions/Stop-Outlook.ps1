
<#
.SYNOPSIS
Stops the Outlook process.

.DESCRIPTION
The Stop-Outlook function is used to stop the Outlook process. It checks if Outlook is running and stops it forcefully if it is.

.PARAMETER UseOldVersion
Use this switch to stop the old version of Outlook.

.EXAMPLE
Stop-Outlook -UseOldVersion
Stops the old version of Outlook.

.EXAMPLE
Stop-Outlook
Stops the current version of Outlook.

.NOTES
Author: [Your Name]
Date: [Current Date]
#>

function Stop-Outlook {
	param (
		[Parameter(Mandatory = $false, HelpMessage = "Use this switch to stop the old version of Outlook.")]
		[switch]$UseOldVersion
	)

	# Get-OutlookProcess function
	function Get-OutlookProcess {
		$OutlookProcessName = if ($UseOldVersion) { "outlook" } else { "olk" }
		return Get-Process -ProcessName $OutlookProcessName -ErrorAction SilentlyContinue
	}

	try {
		$OutlookProcess = Get-OutlookProcess
		if ($OutlookProcess) {
			$OutlookProcess | Stop-Process -Force
			Write-Verbose -Message "Outlook has been stopped."
		}
		else {
			Write-Verbose -Message "Outlook is not running."
		}
	}
	catch {
		Write-Error -Message "An error occurred while trying to stop Outlook: $_"
	}
}
