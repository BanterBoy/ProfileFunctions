function Remove-RDPUserSession {
	<#
    .SYNOPSIS
        Function to extend the use of the QUser Command to remove RDP user sessions.

    .DESCRIPTION
		This function can be used to extend the use of the QUser Command in order to automate the removal of RDP user sessions. This command will query the specified server(s) and output the session details (ID, SessionName, LogonTime, IdleTime, Username, State, ServerName).

		These details are output as objects and can therefore be manipulated to use with additional commands.

    .PARAMETER ComputerName
        Enter the Name/IP/FQDN for the computer you would like to retrieve the information from or pipe in a list of computers.

    .PARAMETER IdentityNo
        Enter User ID for the session you would like to shut down or pipe input.

    .PARAMETER SessionName
        Enter the Session Name you would like to shut down.

    .PARAMETER Username
        Enter the Username for the session you would like to shut down.

    .PARAMETER Force
        Forcefully log off the user.

    .EXAMPLE
		Remove-RDPUserSession -ComputerName DANTOOINE -IdentityNo 2

		ID          : 2
		SessionName : rdp-tcp#7
		LogonTime   : 25/03/2020 01:49
		IdleTime    : 2:41
		Username    : administrator
		State       : Active
		ServerName  : DANTOOINE

    .EXAMPLE
        Remove-RDPUserSession -ComputerName DANTOOINE -Username administrator -Force

    .NOTES
		Author:     Luke Leigh
		Website:    https://blog.lukeleigh.com/
		LinkedIn:   https://www.linkedin.com/in/lukeleigh/
		GitHub:     https://github.com/BanterBoy/
		GitHubGist: https://gist.github.com/BanterBoy

	.LINK
		https://github.com/BanterBoy
	#>

	[CmdletBinding(DefaultParameterSetName = 'ParameterSet1',
		SupportsShouldProcess = $true,
		PositionalBinding = $false,
		HelpUri = 'http://www.microsoft.com/',
		ConfirmImpact = 'Medium')]
	[OutputType([String])]
	Param (
		# Enter the Name/IP/FQDN for the computer you would like to retrieve the information from or pipe in a list of computers.
		[Parameter(ParameterSetName = 'Default',
			Mandatory = $true,
			ValueFromPipeline = $true,
			ValueFromPipelineByPropertyName = $true,
			Position = 0,
			HelpMessage = 'Enter the Name/IP/FQDN for the computer you would like to retrieve the information from or pipe in a list of computers.')]
		[ValidateNotNullOrEmpty()]
		[Alias('cn')]
		[string]
		$ComputerName,
		
		[Parameter(ParameterSetName = 'Default',
			Mandatory = $false,
			ValueFromPipeline = $true,
			ValueFromPipelineByPropertyName = $true,
			HelpMessage = 'Enter User ID for the session you would like to shut down or pipe input.')]
		[string]$IdentityNo,

		[Parameter(ParameterSetName = 'Default',
			Mandatory = $false,
			HelpMessage = 'Enter the Session Name you would like to shut down.')]
		[string]$SessionName,

		[Parameter(ParameterSetName = 'Default',
			Mandatory = $false,
			HelpMessage = 'Enter the Username for the session you would like to shut down.')]
		[string]$Username,

		[Parameter(ParameterSetName = 'Default',
			Mandatory = $false,
			HelpMessage = 'Forcefully log off the user.')]
		[switch]$Force
	)

	Process {
		try {
			# Query the sessions on the specified computer
			$Sessions = Get-RDPUserReport -ComputerName $ComputerName

			# Filter the session based on provided parameters
			$SessionToRemove = $Sessions | Where-Object {
				($null -ne $IdentityNo -and $_.ID -eq $IdentityNo) -or
				($null -ne $SessionName -and $_.SessionName -eq $SessionName) -or
				($null -ne $Username -and $_.Username -eq $Username)
			}

			if ($SessionToRemove) {
				foreach ($session in $SessionToRemove) {
					if ($PSCmdlet.ShouldProcess("Session ID $($session.ID) on $ComputerName", "Log off")) {
						if ($Force) {
							Write-Verbose "Forcefully logging off session ID $($session.ID) on $ComputerName"
							logoff $session.ID /server:$ComputerName /v
						}
						else {
							Write-Verbose "Logging off session ID $($session.ID) on $ComputerName"
							logoff $session.ID /server:$ComputerName
						}
					}
				}
			}
			else {
				Write-Warning "No matching session found on $ComputerName"
			}
		}
		catch {
			Write-Error "An error occurred while trying to remove the RDP user session: $_"
		}
	}
}
