function Get-PatchTuesday {

	<#
		.SYNOPSIS
			Get the Patch Tuesday for a given month
		
		.DESCRIPTION
			This function can be used to find the date for Microsoft's Patch Tuesday in any given Month. The default command without parameters will return the Patch Tuesday date for the current month.
		
		.PARAMETER Month
			The month to check
		
		.PARAMETER Year
			The year to check
		
		.EXAMPLE
			PS C:\> Get-PatchTuesday
			This example will return the Patch Tuesday for the current month
		.EXAMPLE
			PS C:\> Get-PatchTuesday -Month 12 -Year 2015
			This example will return the Patch Tuesday for December 2015
		.EXAMPLE
			PS C:\> Get-PatchTuesday -Month 12
			This example will return the Patch Tuesday for December this year
		.OUTPUTS
			string
		
		.NOTES
			Author:     Luke Leigh
			Website:    https://blog.lukeleigh.com/
			LinkedIn:   https://www.linkedin.com/in/lukeleigh/
			GitHub:     https://github.com/BanterBoy/
			GitHubGist: https://gist.github.com/BanterBoy
		
		.LINK
			https://github.com/BanterBoy
	#>
	
	[CmdletBinding(DefaultParameterSetName = 'Default',
		PositionalBinding = $true,
		SupportsShouldProcess = $true)]
	[OutputType([string], ParameterSetName = 'Default')]
	[Alias('gpt')]
	param
	(
		[Parameter(ParameterSetName = 'Default',
			ValueFromPipeline = $true,
			ValueFromPipelineByPropertyName = $true,
			ValueFromRemainingArguments = $true,
			Position = 1,
			HelpMessage = 'Please enter the Month you wish to check')]
		[ValidateSet('1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12')]
		[Alias('m')]
		[string]
		$Month = (Get-Date).Month,
		[Parameter(ParameterSetName = 'Default',
			ValueFromPipeline = $true,
			ValueFromPipelineByPropertyName = $true,
			ValueFromRemainingArguments = $true,
			Position = 2,
			HelpMessage = 'Enter the year you wish to check e.g. "2021"')]
		[ValidateLength(4, 4)]
		[string]
		$Year = (Get-Date).Year
	)
	if ($PSCmdlet.ShouldProcess("$($Month)" + "-" + "$($Year)", "Locating date")) {
		$firstdayofmonth = [datetime] ([string]$Month + "/1/" + [string]$Year)
		(0 .. 30 | ForEach-Object {
				$firstdayofmonth.adddays($_)
			} |
			Where-Object {
				$_.dayofweek -like "Tue*"
			})[1].ToString('D')
	}
}
