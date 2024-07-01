[CmdletBinding(DefaultParameterSetName = 'Default',
	PositionalBinding = $true,
	SupportsShouldProcess = $true)]
[OutputType([string], ParameterSetName = 'Default')]
[Alias('something')]
Param
(
	[Parameter(ParameterSetName = 'Default',
		Mandatory = $true,
		ValueFromPipeline = $true,
		ValueFromPipelineByPropertyName = $true,
		ValueFromRemainingArguments = $true,
		Position = 0,
		HelpMessage = 'Enter the Name of the computer you would like to connect to.')]
	[Alias('cn')]
	[string[]]
	$ComputerName = $env:COMPUTERNAME,

	[Parameter(ParameterSetName = 'Default',
		Mandatory = $false,
		ValueFromPipeline = $true,
		ValueFromPipelineByPropertyName = $true,
		HelpMessage = 'Enter computer name or pipe input'
	)]
	[Alias('cred')]
	[ValidateNotNull()]
	[System.Management.Automation.PSCredential]
	[System.Management.Automation.Credential()]
	$Credential

)

