Function Get-MyHistory {
	<#
	.SYNOPSIS
		Get-MyHistory will recall the previous commands entered into the console in a format that is easy to copy and paste.
	
	.DESCRIPTION
		Get-MyHistory will recall the previous commands entered into the console in a format that is easy to copy and paste.
	
	.PARAMETER Quantity
		Enter a value between 1 and 9999 to recall the number of historical commands.
	
	.EXAMPLE
				PS C:\> Get-MyHistory
	
	.OUTPUTS
		string
	
	.NOTES
		This function uses the Get-History cmdlet to retrieve the command history.
#>
	
	[CmdletBinding(DefaultParameterSetName = 'Default',
		PositionalBinding = $true)]
	[OutputType([string], ParameterSetName = 'Default')]
	Param
	(
		[Parameter(Mandatory = $false,
			ValueFromPipeline = $true,
			ValueFromPipelineByPropertyName = $true,
			Position = 0)]
		[Alias('q')]
		[ValidateRange(1, 9999)]
		[int]
		$Quantity = 1
	)
	
	Begin {
		Write-Verbose "Starting Get-MyHistory function"
	}
	
	Process {
		Write-Verbose "Retrieving the last $Quantity commands from history"
		Get-History | Select-Object -Property CommandLine -Last $Quantity
	}
	
	End {
		Write-Verbose "Finished Get-MyHistory function"
	}
}