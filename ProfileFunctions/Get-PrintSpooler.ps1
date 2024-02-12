function Get-PrintSpooler {
	<#
	.SYNOPSIS
		A brief description of the Get-PrintSpooler function.
	
	.DESCRIPTION
		A detailed description of the Get-PrintSpooler function.
	
	.PARAMETER ComputerName
		A description of the ComputerName parameter.
	
	.PARAMETER Credential
		A description of the Credential parameter.
	
	.EXAMPLE
		PS C:\> Get-PrintSpooler -ComputerName 'value1'
	
	.OUTPUTS
		System.String
	
	.NOTES
		Additional information about the function.
	#>
	
	[CmdletBinding(DefaultParameterSetName = 'Default',
		HelpUri = 'https://github.com/BanterBoy',
		SupportsShouldProcess = $true)]
	[OutputType([string])]
	param
	(
		[Parameter(ParameterSetName = 'Default',
			Mandatory = $false,
			ValueFromPipeline = $true,
			ValueFromPipelineByPropertyName = $true,
			HelpMessage = 'Enter computer name or pipe input')]
		[Alias('cn')]
		[string[]]$ComputerName = $env:COMPUTERNAME,

		[Parameter(ParameterSetName = 'Default',
			Mandatory = $false,
			HelpMessage = 'Enter your credentials')]
		[PSCredential]$Credential,

		[Parameter(ParameterSetName = 'Default',
			Mandatory = $false,
			HelpMessage = 'Restart the service')]
		[switch]$Restart
	)

	PROCESS {
		foreach ($Computer in $ComputerName) {
			if ($PSCmdlet.ShouldProcess($Computer, 'Get Print Spooler status')) {
				$localScriptBlock = {
					$spoolerService = Get-Service -Name Spooler

					Write-Verbose "Retrieved Spooler service status for $env:COMPUTERNAME"

					if ($Restart) {
						$spoolerService | Restart-Service -PassThru
						Write-Verbose "Restarted Spooler service on $env:COMPUTERNAME"
					}

					$spoolerService
				}

				$remoteScriptBlock = {
					$spoolerService = Get-Service -Name Spooler

					Write-Verbose "Retrieved Spooler service status for $using:Computer"

					if ($using:Restart) {
						$spoolerService | Restart-Service -PassThru
						Write-Verbose "Restarted Spooler service on $using:Computer"
					}

					$spoolerService
				}

				if ($Computer -eq $env:COMPUTERNAME) {
					# Use local command
					& $localScriptBlock
				}
				else {
					# Use remote command
					if ($null -ne $Credential) {
						Invoke-Command -ComputerName $Computer -Credential $Credential -ScriptBlock $remoteScriptBlock
					}
					else {
						Invoke-Command -ComputerName $Computer -ScriptBlock $remoteScriptBlock
					}
				}
			}
		}
	}
}
