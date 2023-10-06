function Get-ProfileFunctions {

	function Get-FunctionsPS7 {
		$funcs = @();
		Get-ChildItem "$PSScriptRoot\*.ps1" | Select-Object -Property BaseName
		Get-ChildItem "$PSScriptRoot\7Only\*.ps1" | Select-Object -Property BaseName
		return $funcs
	}

	function Get-FunctionsPSEarlier {
		$funcs = @();
		Get-ChildItem "$PSScriptRoot\*.ps1" | Select-Object -Property BaseName
		Get-ChildItem "$PSScriptRoot\6Instead\*.ps1" | Select-Object -Property BaseName
		return $funcs
	}

	if ($PSVersionTable.PSVersion.Major -ge 6) {
		Get-FunctionsPS7 | Format-Wide -Autosize
	}
	else {
		Get-FunctionsPSEarlier | Format-Wide -Autosize
	}


}
