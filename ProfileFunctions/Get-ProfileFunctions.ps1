function Get-ProfileFunctions {
	<#
	.SYNOPSIS
		This script contains functions to retrieve PowerShell functions from a specific directory.
	.DESCRIPTION
		This script contains two functions, Get-FunctionsPS7 and Get-FunctionsPSEarlier, which retrieve PowerShell functions from the directory where this script is located. The Get-AllProfileFunctions function determines which of these two functions to use based on the version of PowerShell being used. The Get-ProfileFunctions function allows the user to filter the retrieved functions by verb and/or noun, and optionally format the output using Format-Wide.
	.PARAMETER Verb
		Specifies the verb to filter the retrieved functions by. Defaults to "*".
	.PARAMETER Noun
		Specifies the noun to filter the retrieved functions by. Defaults to "*".
	.PARAMETER Wide
		If specified, formats the output using Format-Wide -Autosize.
	.EXAMPLE
		PS C:\> Get-ProfileFunctions -Verb Get -Noun Item -Wide
		This example retrieves all functions with the verb "Get" and the noun "Item" from the directory where this script is located, and formats the output using Format-Wide -Autosize.
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $false)]
		[string]$Verb = "*",
		[Parameter(Mandatory = $false)]
		[string]$Noun = "*",
		[Parameter(Mandatory = $false)]
		[switch]$Wide,
		[Parameter(Mandatory = $false)]
		[switch]$Personal
	)

	function Get-FunctionsPS7 {
		$funcs = @();
		Get-ChildItem "$PSScriptRoot\*.ps1" | Select-Object -Property BaseName
		Get-ChildItem "$PSScriptRoot\7Only\*.ps1" | Select-Object -Property BaseName
		if ($Personal) {
			Get-ChildItem "$PSScriptRoot\personal\*.ps1" | Select-Object -Property BaseName
		}
		return $funcs
	}

	function Get-FunctionsPSEarlier {
		$funcs = @();
		Get-ChildItem "$PSScriptRoot\*.ps1" | Select-Object -Property BaseName
		Get-ChildItem "$PSScriptRoot\6Instead\*.ps1" | Select-Object -Property BaseName
		if ($Personal) {
			Get-ChildItem "$PSScriptRoot\personal\*.ps1" | Select-Object -Property BaseName
		}
		return $funcs
	}
		
	function Get-AllProfileFunctions {
			
		if ($PSVersionTable.PSVersion.Major -ge 6) {
			Get-FunctionsPS7 | Format-Wide -Autosize
		}
		else {
			Get-FunctionsPSEarlier | Format-Wide -Autosize
		}
	}

	# if output is specified, then output the using format-wide -autosize
	# otherwise, return the objects

	if ($PSVersionTable.PSVersion.Major -ge 6) {
		$funcs = Get-FunctionsPS7
	}
	else {
		$funcs = Get-FunctionsPSEarlier
	}

	if ($Verb -ne "*") {
		$funcs = $funcs | Where-Object { $_.BaseName -like "$Verb-*" }
	}

	if ($Noun -ne "*") {
		$funcs = $funcs | Where-Object { $_.BaseName -like "*-$Noun" }
	}

	if ($Wide) {
		$funcs | Format-Wide -Autosize
	}
	else {
		return $funcs
	}
}
