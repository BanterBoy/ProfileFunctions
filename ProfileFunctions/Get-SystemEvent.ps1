function Get-SystemEvent {
	
	[CmdletBinding(DefaultParameterSetName = 'Default',
		supportsShouldProcess = $true,
		HelpUri = 'https://github.com/BanterBoy'
	)]
	[OutputType([string])]
	param
	(
		[Parameter(ParameterSetName = 'Default',
			Mandatory = $false,
			ValueFromPipeline = $true,
			ValueFromPipelineByPropertyName = $true,
			HelpMessage = 'Enter the name of the computer from which to retrieve events.'
		)]
		[Alias('cn')]
		[string[]]$ComputerName = $env:COMPUTERNAME,
		[Parameter(ParameterSetName = 'Default',
			Mandatory = $false,
			ValueFromPipeline = $true,
			ValueFromPipelineByPropertyName = $true,
			HelpMessage = 'Enter the credentials to use when connecting to the computer.'
		)]
		[Alias('cred')]
		[ValidateNotNull()]
		[System.Management.Automation.PSCredential]
		[System.Management.Automation.Credential()]
		$Credential,
		[Parameter(ParameterSetName = 'Default',
			Mandatory = $false,
			ValueFromPipeline = $true,
			ValueFromPipelineByPropertyName = $true,
			HelpMessage = 'Enter the number of days of events to retrieve.'
		)]
		[Alias('d')]
		[int[]]$Days = 10
	)
	BEGIN {
	}
	PROCESS {
		foreach ($Computer in $ComputerName) {
			if ($PSCmdlet.ShouldProcess("$Computer", "Extracting events")) {
				if ($Credential) {
					try {
						$Results = Get-WinEvent -ComputerName $Computer -Credential $Credential | Where-Object -FilterScript { ($_.Level -eq 2) -or ($_.Level -eq 3) } | Where-Object -Property TimeCreated -GT (Get-Date).AddDays( - "$Days") -ErrorAction SilentlyContinue | Select-Object TimeCreated, Message, MachineName
						if ($null -eq $Results) {
							Write-Error "No events Found on $Computer"
						}
						else {
							Write-Output $Results
						}
					}
					catch {
						Write-Error "Failed to retrieve events from $Computer"
					}
		
				}
				else {
					try {
						$Results = Get-WinEvent -ComputerName $Computer | Where-Object -FilterScript { ($_.Level -eq 2) -or ($_.Level -eq 3) } | Where-Object -Property TimeCreated -GT (Get-Date).AddDays( - "$Days") -ErrorAction SilentlyContinue | Select-Object TimeCreated, Message, MachineName
						if ($null -eq $Results) {
							Write-Error "No events Found on $Computer"
						}
						else {
							Write-Output $Results
						}
					}
					catch {
						Write-Error "Failed to retrieve events from $Computer. Error: $_"
					}
				}
			}
		}
	}
	END {
	}
}