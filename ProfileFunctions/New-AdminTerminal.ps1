function New-AdminTerminal {
    <#
	.Synopsis
	Starts an Elevated Microsoft Terminal.

	.Description
	Opens a new Microsoft Terminal Elevated as Administrator. If the user is already running an elevated
	Microsoft Terminal, a message is displayed in the console session.

	.Example
	New-AdminShell

	#>

    if (Test-IsAdmin = $True) {
        Write-Warning -Message "Admin Shell already running!"
    }
    else {
        Start-Process "wt.exe" -ArgumentList "-p pwsh" -Verb runas -PassThru
    }
}