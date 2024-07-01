[CmdletBinding(SupportsShouldProcess = $true)]
param (
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
	$Credential,
	[Parameter(ParameterSetName = 'Default',
		Mandatory = $false,
		ValueFromPipeline = $true,
		ValueFromPipelineByPropertyName = $true,
		HelpMessage = 'Enter computer name or pipe input'
	)]
	[string[]]$SamAccountName
)
Process {
	if ($PSCmdlet.ShouldProcess("$ComputerName / $SamAccountName", "ExampleParamsInScript")) {
		# Script content goes here
		
	}
}
