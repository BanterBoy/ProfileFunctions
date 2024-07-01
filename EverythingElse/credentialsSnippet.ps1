[Parameter(ParameterSetName = 'Default',
	Mandatory = $false,
	ValueFromPipeline = $true,
	ValueFromPipelineByPropertyName = $true,
	HelpMessage = 'Enter computer name or pipe input'
)]
[Alias('cn')]
[string[]]$ComputerName = $env:COMPUTERNAME,

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
