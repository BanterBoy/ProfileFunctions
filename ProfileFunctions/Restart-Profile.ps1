function Restart-Profile {
	<#
	.SYNOPSIS
		Reloads specified PowerShell profiles or all available profiles for the current user and host if no profile is specified.
	
	.DESCRIPTION
		The Restart-Profile function reloads specified PowerShell profiles or all available profiles for the current user and host if no profile is specified. 
		It checks for the existence of each profile and if it exists, the profile is sourced into the current session.
	
	.EXAMPLE
		Restart-Profile -ProfileKeys 'CurrentUserHost'
	
	.EXAMPLE
		Restart-Profile
	#>
	[CmdletBinding()]
	param(
		[Parameter(ValueFromPipeline = $true)]
		[ValidateSet('AllUsersAllHosts', 'AllUsersCurrentHost', 'CurrentUserAllHosts', 'CurrentUserHost')]
		[string[]]$ProfileKeys = @('AllUsersAllHosts', 'AllUsersCurrentHost', 'CurrentUserAllHosts', 'CurrentUserHost')
	)

	$profileMap = @{
		'AllUsersAllHosts'    = $Profile.AllUsersAllHosts
		'AllUsersCurrentHost' = $Profile.AllUsersCurrentHost
		'CurrentUserAllHosts' = $Profile.CurrentUserAllHosts
		'CurrentUserHost'     = $Profile.CurrentUserCurrentHost
	}

	$ProfileKeys | ForEach-Object {
		$profilePath = $profileMap[$_]
		if ($profilePath -and (Test-Path $profilePath)) {
			Write-Verbose "Running $profilePath"
			try {
				. $profilePath
			}
			catch {
				Write-Error "Failed to source profile $($profilePath): $_"
			}
		}
	}
}
