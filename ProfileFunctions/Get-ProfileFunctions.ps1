function Get-ProfileFunctions {
	function Get-Functions {
		$funcs = @();
		Get-ChildItem "$PSScriptRoot\*.ps1" | Select-Object -Property BaseName
	}
	Get-Functions | Format-Wide -Autosize
}
