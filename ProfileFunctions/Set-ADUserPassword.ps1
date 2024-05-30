function Set-ADUserPassword {
	[CmdletBinding(
		SupportsShouldProcess = $true,
		ConfirmImpact = "Medium"
	)]
	param(
		[Parameter(
			Mandatory = $true,
			Position = 0)]
		[string]
		$SamAccountName,
		[Parameter(
			Mandatory = $true,
			Position = 1
		)]
		[securestring]
		$Password
	)
	begin {

	}
	process {
		if ($SamAccountName) {
			if ($PSCmdlet.ShouldProcess("$SamAccountName", "Setting AD User password...")) {
				try {
					Set-ADUser -SamAccountName $SamAccountName -Password $Password
				}
				catch {
					Write-Error -Message "$_"
				}
			}
		}
	}
	end {

	}
}
