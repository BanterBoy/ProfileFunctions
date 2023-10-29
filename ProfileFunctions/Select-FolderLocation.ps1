function Select-FolderLocation {
	<#
	.SYNOPSIS
		Displays a dialog box that enables the user to select a folder.
	.DESCRIPTION
		The Select-FolderLocation function displays a dialog box that enables the user to select a folder. 
		If the user clicks the OK button, the function returns the path of the selected folder. 
		If the user clicks the Cancel button, the function returns nothing.
	.PARAMETER InitialDirectory
		Specifies the initial folder displayed in the dialog box. The default is C:\.
	.PARAMETER LoopUntilValid
		Specifies whether to keep displaying the dialog box until the user selects a valid folder. The default is $true.
	.PARAMETER LiteralPath
		Specifies a path to a folder that is used instead of displaying the dialog box.
	.EXAMPLE
		Select-FolderLocation -InitialDirectory "C:\Users\JohnDoe\Documents" -LoopUntilValid $false
		Displays a dialog box that enables the user to select a folder. The initial folder displayed in the dialog box is "C:\Users\JohnDoe\Documents". 
		The function returns the path of the selected folder. If the user clicks the Cancel button, the function returns nothing.
	#>
	param (
		[string]$InitialDirectory = "C:\",
		[bool]$LoopUntilValid = $true,
		[string]$LiteralPath
	)

	if ($LiteralPath) {
		$script:FolderPath = $LiteralPath
		return $LiteralPath
	}

	[Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
	[System.Windows.Forms.Application]::EnableVisualStyles()
	$browse = New-Object System.Windows.Forms.FolderBrowserDialog
	$browse.SelectedPath = $InitialDirectory
	$loop = $LoopUntilValid
	while ($loop) {
		if ($browse.ShowDialog() -eq "OK") {
			$loop = $false
		}
		else {
			$res = [System.Windows.Forms.MessageBox]::Show("You clicked Cancel. Would you like to try again or exit?", "Select a location", [System.Windows.Forms.MessageBoxButtons]::RetryCancel)
			if ($res -eq "Cancel") {
				return
			}
		}
	}
	$script:FolderPath = $browse.SelectedPath
	$browse.SelectedPath
	$browse.Dispose()
}
