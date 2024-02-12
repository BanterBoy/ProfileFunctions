<#
.SYNOPSIS
Creates a new shell process with various options.

.DESCRIPTION
The New-Shell function creates a new shell process with the ability to specify the shell type, run as elevated permissions, or run with specific user credentials. It provides flexibility in starting PowerShell or pwsh (PowerShell Core) shells with different parameter sets.

.PARAMETER User
Specifies the shell to start. Valid values are 'PowerShell' or 'pwsh'.

.PARAMETER RunAs
Specifies the shell to start with elevated permissions. Valid values are 'PowerShellRunAs' or 'pwshRunAs'.

.PARAMETER RunAsUser
Specifies the shell to start with specific user credentials. Valid values are 'PowerShellRunAsUser' or 'pwshRunAsUser'.

.PARAMETER Credentials
Provides the credentials of the user to run the shell as. This parameter is mandatory when using the 'RunAsUser' parameter set.

.PARAMETER NoProfile
Starts the shell without loading the user profile.

.EXAMPLE
New-Shell -User PowerShell
Starts a new PowerShell shell.

.EXAMPLE
New-Shell -RunAs PowerShellRunAs
Starts a new PowerShell shell with elevated permissions.

.EXAMPLE
New-Shell -RunAsUser PowerShellRunAsUser -Credentials $cred
Starts a new PowerShell shell with specific user credentials.

#>
function New-Shell {

	[CmdletBinding(DefaultParameterSetName = 'User')]
	param
	(
		[Parameter(ParameterSetName = 'User',
			Mandatory = $false,
			Position = 0,
			HelpMessage = 'Specify the shell to start: PowerShell or pwsh')]
		[ValidateSet ('PowerShell', 'pwsh')]
		[string]
		$User,
		[Parameter(ParameterSetName = 'RunAs',
			Mandatory = $false,
			Position = 0,
			HelpMessage = 'Specify the shell to start with elevated permissions: PowerShellRunAs or pwshRunAs')]
		[ValidateSet ('PowerShellRunAs', 'pwshRunAs')]
		[string]
		$RunAs,
		[Parameter(ParameterSetName = 'RunAsUser',
			Mandatory = $false,
			Position = 1,
			HelpMessage = 'Specify the shell to start with specific user credentials: PowerShellRunAsUser or pwshRunAsUser')]
		[ValidateSet ('PowerShellRunAsUser', 'pwshRunAsUser')]
		[string]
		$RunAsUser,
		[Parameter(ParameterSetName = 'RunAsUser',
			Mandatory = $true,
			Position = 2,
			HelpMessage = 'Provide the credentials of the user to run the shell as')]
		[pscredential]
		$Credentials,
		[Parameter(Mandatory = $false,
			HelpMessage = 'Specify this switch to start the shell without loading the profile')]
		[switch]
		$NoProfile
	)
	
	$arguments = if ($NoProfile) { @("-NoProfile") } else { @() }

	switch ($User) {
		PowerShell {
			Start-Process -FilePath:"PowerShell.exe" -ArgumentList $arguments -PassThru:$true
		}
		pwsh {
			Start-Process -FilePath:"pwsh.exe" -ArgumentList $arguments -PassThru:$true
		}
		WindowsTerminal {
			Start-Process -FilePath:"wt.exe" -ArgumentList $arguments -PassThru:$true
		}
	}
	switch ($RunAs) {
		PowerShellRunAs {
			Start-Process -FilePath:"PowerShell.exe" -Verb:RunAs -ArgumentList $arguments -PassThru:$true
		}
		pwshRunAs {
			Start-Process -FilePath:"pwsh.exe" -Verb:RunAs -ArgumentList $arguments -PassThru:$true
		}
		WindowsTerminalRunAs {
			Start-Process -FilePath:"wt.exe" -Verb:RunAs -ArgumentList $arguments -PassThru:$true
		}
	}
	switch ($RunAsUser) {
		PowerShellRunAsUser {
			Start-Process -Credential:$Credentials -FilePath:"PowerShell.exe" -LoadUserProfile:$true -UseNewEnvironment:$true -ArgumentList ("-Mta" + $arguments)
		}
		pwshRunAsUser {
			Start-Process -Credential:$Credentials -FilePath:"pwsh.exe" -LoadUserProfile:$true -UseNewEnvironment:$true -ArgumentList ("-Mta" + $arguments)
		}
		WindowsTerminalRunAsUser {
			Start-Process -Credential:$Credentials -FilePath:"wt.exe" -LoadUserProfile:$true -UseNewEnvironment:$true -ArgumentList ("-Mta" + $arguments)
		}
	}
}
