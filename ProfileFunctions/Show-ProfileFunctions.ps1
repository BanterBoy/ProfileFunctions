function Show-ProfileFunctions {
	$Path = Join-Path $PSScriptRoot "/Microsoft.PowerShell_profile.ps1"
	$functionNames = Get-ContainedCommand $Path -ItemType FunctionDefinition |	Select-Object -ExpandProperty Name
	$functionNames | Sort-Object
}