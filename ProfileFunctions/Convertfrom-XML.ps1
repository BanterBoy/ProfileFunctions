function Convertfrom-XML {
	<#
		.SYNOPSIS
			Short description
		.DESCRIPTION
			Long description

		# Download Json.NET
		# Popular high-performance JSON framework for .NET
		# https://www.newtonsoft.com/json

		.EXAMPLE
			Example of how to use this cmdlet
		.EXAMPLE
			Another example of how to use this cmdlet
		.INPUTS
			Inputs to this cmdlet (if any)
		.OUTPUTS
			Output from this cmdlet (if any)
		.NOTES
			General notes
		.COMPONENT
			The component this cmdlet belongs to
		.ROLE
			The role this cmdlet belongs to
		.FUNCTIONALITY
			The functionality that best describes this cmdlet
	#>
	[CmdletBinding(DefaultParameterSetName='Default',
				   SupportsShouldProcess=$true,
				   PositionalBinding=$false,
				   HelpUri = 'http://www.microsoft.com/',
				   ConfirmImpact='Medium')]
	[Alias()]
	[OutputType([String])]
	Param (
		# This parameter accepts the file path as a string.
		[Parameter(Mandatory=$true,
				   Position=0,
				   ValueFromPipeline=$true,
				   ValueFromPipelineByPropertyName=$true,
				   ValueFromRemainingArguments=$false, 
				   ParameterSetName='Default')]
		[ValidateNotNullOrEmpty()]
		[Alias("fp")] 
		$FilePath
	)
	
	begin {
		# Adds a Microsoft .NET Framework type (a class) to a Windows PowerShell session
		Add-Type -Path $PSScriptRoot\Newtonsoft.Json\Newtonsoft.Json.dll
	}
	
	process {
		if ($pscmdlet.ShouldProcess("Target", "Operation")) {
			[XML]$global:FileObject = Get-Content -Path $FilePath
			$global:XMLObject = [Newtonsoft.Json.JsonConvert]::SerializeXmlNode($FileObject) | ConvertFrom-Json
			$global:XMLObject | Out-String
		}
	}
	
	end {
	}
}

<#
	# Serialize the XML to Json and convert files to Objects
	[XML]$global:tylerConfig1 = Get-Content $PSScriptRoot\config-Tyler-pfSense1.ventrica.local-updatedIPs-20191129.xml
	[XML]$global:tylerConfig2 = Get-Content $PSScriptRoot\config-Tyler-pfSense2.ventrica.local-updatedIPs-20191129.xml
	$global:tylerpfSense1 = [Newtonsoft.Json.JsonConvert]::SerializeXmlNode($tylerConfig1) | ConvertFrom-Json
	$global:tylerpfSense2 = [Newtonsoft.Json.JsonConvert]::SerializeXmlNode($tylerConfig2) | ConvertFrom-Json

	[XML]$global:maitlandConfig1 = Get-Content $PSScriptRoot\config-Maitland-pfSense1.ventrica.local-updatedIPs-20191129.xml
	[XML]$global:maitlandConfig2 = Get-Content $PSScriptRoot\config-Maitland-pfSense2.ventrica.local-updatedIPs-20191129.xml
	$global:maitlandpfSense1 = [Newtonsoft.Json.JsonConvert]::SerializeXmlNode($maitlandConfig1) | ConvertFrom-Json
	$global:maitlandpfSense2 = [Newtonsoft.Json.JsonConvert]::SerializeXmlNode($maitlandConfig2) | ConvertFrom-Json

	Write-Warning -Message "Query pfSense Firewall Objects"
	$tylerpfSense1.pfsense | Get-Member
	$tylerpfSense2.pfsense | Get-Member

	$maitlandpfSense1.pfsense | Get-Member
	$maitlandpfSense2.pfsense | Get-Member


	$tylerpfSense1.pfsense | Get-Member -MemberType *prop* | Select-Object Name -OutVariable Tyler1pfSense | Format-Table
	$tylerpfSense2.pfsense | Get-Member -MemberType *prop* | Select-Object Name -OutVariable Tyler2pfSense | Format-Table

	$maitlandpfSense1.pfsense | Get-Member -MemberType *prop* | Select-Object Name -OutVariable maitland1pfSense | Format-Table
	$maitlandpfSense2.pfsense | Get-Member -MemberType *prop* | Select-Object Name -OutVariable maitland2pfSense | Format-Table

	Write-Warning -Message "Variables are persistent"
	Get-Variable -Name tyler*
	Get-Variable -Name maitland*
#>
