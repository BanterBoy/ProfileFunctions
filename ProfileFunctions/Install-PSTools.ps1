function Install-PSTools {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param()

	if ($PSCmdlet.ShouldProcess('PSTools', 'Install')) {
		Write-Verbose "Checking if PSTools is already installed..."
		if (Test-Path 'C:\Program Files\Sysinternals\PsExec.exe') {
			Write-Verbose "PSTools is already installed."
			return
		}

		try {
			Write-Verbose "Downloading PSTools..."
			Invoke-WebRequest -Uri 'https://download.sysinternals.com/files/PSTools.zip' -OutFile 'pstools.zip'

			Write-Verbose "Extracting PSTools..."
			Expand-Archive -Path 'pstools.zip' -DestinationPath "$env:TEMP\pstools"

			Write-Verbose "Checking if 'C:\Program Files\Sysinternals' directory exists..."
			if (!(Test-Path 'C:\Program Files\Sysinternals')) {
				Write-Verbose "Creating 'C:\Program Files\Sysinternals' directory..."
				New-Item -Path 'C:\Program Files\Sysinternals'
			}

			Write-Verbose "Copying PSTools to 'C:\Program Files\Sysinternals'..."
			Copy-Item -Path "$env:TEMP\pstools\*.*" -Destination 'C:\Program Files\Sysinternals'

			Write-Verbose "Cleaning up temporary files..."
			Remove-Item -Path "$env:TEMP\pstools" -Recurse
			Remove-Item -Path 'pstools.zip'

			Write-Verbose "Checking if user is an administrator..."
			$test = Test-IsAdmin
			if ($test -eq $true) {
				Write-Verbose "User is an administrator. Adding 'C:\Program Files\Sysinternals' to system 'Path'..."
				Add-EnvPath -Path 'C:\Program Files\Sysinternals' -Container 'Machine'
			}
			else {
				Write-Verbose "User is not an administrator. Adding 'C:\Program Files\Sysinternals' to user 'Path'..."
				Add-EnvPath -Path 'C:\Program Files\Sysinternals' -Container 'User'
			}
		}
		catch {
			Write-Error "An error occurred: $_"
		}
	}
}
