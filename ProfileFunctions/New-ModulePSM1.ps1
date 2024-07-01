function New-ModulePSM1 {
	<#
		.SYNOPSIS
			Creates a new module script file.
	
		.DESCRIPTION
			Command will create a PSM1 file based on the contents of the subfolder public inside the module folder.
	
		.PARAMETER FolderPath
			Please enter the file path for the data input. The location should be an HR Share with restricted access.
	
		.PARAMETER ModuleName
			Please enter the file path for the data input. The location should be an HR Share with restricted access.
	
		.EXAMPLE
			PS C:\> New-ModulePSM1 -FolderPath 'Value1' -ModuleName 'Value2'
	
		.NOTES
			Additional information about the function.
	#>
	
	[CmdletBinding(DefaultParameterSetName = 'Default',
		PositionalBinding = $true,
		SupportsPaging = $false)]
	param
	(
		[Parameter(ParameterSetName = 'Default',
			Mandatory = $true,
			ValueFromPipeline = $true,
			ValueFromPipelineByPropertyName = $true,
			Position = 1,
			HelpMessage = 'Please enter the file path for the data input. The location should be an HR Share with restricted access.')]
		[SupportsWildcards()]
		[string]
		$FolderPath,
	
		[Parameter(ParameterSetName = 'Default',
			Mandatory = $true,
			ValueFromPipeline = $true,
			ValueFromPipelineByPropertyName = $true,
			Position = 2,
			HelpMessage = 'Please enter the file path for the data input. The location should be an HR Share with restricted access.')]
		[string]
		$ModuleName
	)
	
	$Scripts = Get-ChildItem -Path "$FolderPath\Public" -File | Select-Object -Property BaseName, Name, FullName
	Remove-Item -Path "$FolderPath\$ModuleName.psm1" -ErrorAction SilentlyContinue
	New-Item -Path "$FolderPath\$ModuleName.psm1" -ItemType File
	
	foreach ($Script in $Scripts) {
		$Content = Get-Content -Path "$($Script.FullName)"
		Add-Content -Path "$FolderPath\$ModuleName.psm1" -Value $Content
	}
}
	
# Example usage
# New-ModulePSM1 -FolderPath "C:\GitRepos\PowerShellProfile" -ModuleName "PowerShellProfile" -Verbose
