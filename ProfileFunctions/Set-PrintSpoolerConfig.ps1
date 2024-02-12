function Set-PrintSpoolerConfig {
	[CmdletBinding(DefaultParameterSetName = 'Default',
		HelpUri = 'https://github.com/BanterBoy',
		SupportsShouldProcess = $true)]
	[OutputType([string])]
	param
	(
		[Parameter(ParameterSetName = 'Default',
			Mandatory = $true,
			ValueFromPipeline = $true,
			ValueFromPipelineByPropertyName = $true,
			HelpMessage = 'Enter computer name or pipe input')]
		[Alias('cn')]
		[string[]]$ComputerName,

		[Parameter(ParameterSetName = 'Default',
			Mandatory = $true,
			HelpMessage = 'Enter desired status of the Print Spooler service')]
		[ValidateSet('Running', 'Stopped', 'Disabled', 'Enabled')]
		[string]$Status
	)

	PROCESS {
		foreach ($Computer in $ComputerName) {
			try {
				$localComputerName = [System.Environment]::MachineName
				if ($localComputerName -eq $Computer) {
					# Run the command locally
					$spoolerService = Get-Service -Name Spooler

					switch ($Status) {
						'Running' {
							if ($spoolerService.Status -ne 'Running') {
								if ($PSCmdlet.ShouldProcess("$Computer", "Start Spooler service")) {
									$spoolerService | Start-Service
									Write-Verbose "Started Spooler service on $Computer"
								}
							}
						}
						'Stopped' {
							if ($spoolerService.Status -ne 'Stopped') {
								if ($PSCmdlet.ShouldProcess("$Computer", "Stop Spooler service")) {
									$spoolerService | Stop-Service
									Write-Verbose "Stopped Spooler service on $Computer"
								}
							}
						}
						'Disabled' {
							if ($spoolerService.StartType -ne 'Disabled') {
								if ($PSCmdlet.ShouldProcess("$Computer", "Disable Spooler service")) {
									$spoolerService | Set-Service -StartupType Disabled
									Write-Verbose "Disabled Spooler service on $Computer"
								}
							}
						}
						'Enabled' {
							if ($spoolerService.StartType -eq 'Disabled') {
								if ($PSCmdlet.ShouldProcess("$Computer", "Enable Spooler service")) {
									$spoolerService | Set-Service -StartupType Automatic
									Write-Verbose "Enabled Spooler service on $Computer"
								}
							}
						}
					}
				}
				else {
					# Run the command remotely
					Invoke-Command -ComputerName $Computer -ScriptBlock {
						$spoolerService = Get-Service -Name Spooler

						switch ($using:Status) {
							'Running' {
								if ($spoolerService.Status -ne 'Running') {
									if ($PSCmdlet.ShouldProcess("$using:Computer", "Start Spooler service")) {
										$spoolerService | Start-Service
										Write-Verbose "Started Spooler service on $using:Computer"
									}
								}
							}
							'Stopped' {
								if ($spoolerService.Status -ne 'Stopped') {
									if ($PSCmdlet.ShouldProcess("$using:Computer", "Stop Spooler service")) {
										$spoolerService | Stop-Service
										Write-Verbose "Stopped Spooler service on $using:Computer"
									}
								}
							}
							'Disabled' {
								if ($spoolerService.StartType -ne 'Disabled') {
									if ($PSCmdlet.ShouldProcess("$using:Computer", "Disable Spooler service")) {
										$spoolerService | Set-Service -StartupType Disabled
										Write-Verbose "Disabled Spooler service on $using:Computer"
									}
								}
							}
							'Enabled' {
								if ($spoolerService.StartType -eq 'Disabled') {
									if ($PSCmdlet.ShouldProcess("$using:Computer", "Enable Spooler service")) {
										$spoolerService | Set-Service -StartupType Automatic
										Write-Verbose "Enabled Spooler service on $using:Computer"
									}
								}
							}
						}
					}
				}
			}
			catch {
				Write-Error "Failed to set Print Spooler service status on ${Computer}: $_"
			}
		}
	}
}