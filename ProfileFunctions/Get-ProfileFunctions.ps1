function Get-ProfileFunctions {
	function Get-Functions {
		$psPath = "C:\GitRepos\ProfileFunctions"
		$funcs = @();
		Get-ChildItem "$psPath\ProfileFunctions\*.ps1" | Select-Object -Property BaseName
	}
	Get-Functions | Format-Wide -Autosize
}
