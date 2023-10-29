function New-PSDrives {
	<#
	.SYNOPSIS
	Create PS Drives for all folders in a given path.
	
	.DESCRIPTION
	Create PS Drives for all folders in a given path.
	
	.PARAMETER PSRootFolder
	The root folder to create PS Drives for.
	
	.EXAMPLE
	New-PSDrives -PSRootFolder "C:\Users\username\Documents\WindowsPowerShell\Modules"
	
	.NOTES
	
	.LINK
	
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[ValidateScript({
				if (Test-Path $_ -PathType Container) {
					$true
				}
				else {
					throw "Path `$_` is not a valid directory"
				}
			})]
		[string]$PSRootFolder
	)

	$PSDrivePaths = Get-ChildItem -Path "$PSRootFolder\" -Directory

	$totalItems = $PSDrivePaths.Count
	$currentItem = 0

	foreach ($item in $PSDrivePaths) {
		$currentItem++
		Write-Progress -Activity "Creating PS Drives" -Status "Processing Item $currentItem of $totalItems" -PercentComplete (($currentItem / $totalItems) * 100)

		try {
			$paths = Test-Path -Path $item.FullName
			if ($paths -eq $true) {
				$driveName = $item.Name -replace '[;~\/\.:]', ''  # Remove invalid characters
				if (-not (Get-PSDrive -Name $driveName -ErrorAction SilentlyContinue)) {
					New-PSDrive -Name $driveName -PSProvider "FileSystem" -Root $item.FullName -Scope Global
					Write-Verbose "Drive $driveName created successfully."
				}
				else {
					Write-Verbose "Drive $driveName already exists."
				}
			}
		}
		catch {
			Write-Warning "Error creating drive $($driveName): $_"
		}
	}
}