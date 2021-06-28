function Get-Password {
	<#
	.EXAMPLE
	$user = Get-Password -Label UserName
	$pass = Get-Password -Label password

	.OUTPUTS
	$user | Format-List

	.OUTPUTS
	Label		   : UserName
	EncryptedString : domain\administrator

	.OUTPUTS
	$pass | Format-List
	Label		   : password
	EncryptedString : SomeSecretPassword

	.OUTPUTS
	$user.EncryptedString
	domain\administrator

	.OUTPUTS
	$pass.EncryptedString
	SomeSecretPassword

	#>
	param([Parameter(Mandatory)]
		[string]$Label)
	$directoryPath = Select-FolderLocation
	if (![string]::IsNullOrEmpty($directoryPath)) {
		Write-Host "You selected the directory: $directoryPath"
	}
	$filePath = "$directoryPath\$Label.txt"
	if (-not (Test-Path -Path $filePath)) {
		throw "The password with Label [$($Label)] was not found!"
	}
	$password = Get-Content -Path $filePath | ConvertTo-SecureString
	$decPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))
	[pscustomobject]@{
		Label		   = $Label
		EncryptedString = $decPassword
	}
}