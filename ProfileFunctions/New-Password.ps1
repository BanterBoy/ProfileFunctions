function New-Password {
	<# Example

	.EXAMPLE
	Save-Password -Label UserName

	.EXAMPLE
	Save-Password -Label Password

	#>
	param([Parameter(Mandatory)]
		[string]$Label)
	$securePassword = Read-host -Prompt 'Input password' -AsSecureString | ConvertFrom-SecureString
	$directoryPath = Select-FolderLocation
	if (![string]::IsNullOrEmpty($directoryPath)) {
		Write-Host "You selected the directory: $directoryPath"
	}
	else {
		"You did not select a directory."
	}
	$securePassword | Out-File -FilePath "$directoryPath\$Label.txt"
}