function Reorganize-FilesByType {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$baseDirectory
    )

    # Check if the directory exists
    if (-Not (Test-Path -Path $baseDirectory)) {
        Write-Error "The directory '$baseDirectory' does not exist."
        return
    }

    # Get all files in the directory and subdirectories
    $files = Get-ChildItem -Path $baseDirectory -File -Recurse

    # Loop through each file
    foreach ($file in $files) {
        # Extract the file extension and prepare the target subfolder path
        $fileExtension = $file.Extension.TrimStart('.')
        if ($fileExtension -eq '') {
            $fileExtension = 'NoExtension'
        }
        $targetFolder = Join-Path -Path $baseDirectory -ChildPath $fileExtension

        # Create the subfolder if it doesn't exist
        if (-Not (Test-Path -Path $targetFolder)) {
            New-Item -Path $targetFolder -ItemType Directory | Out-Null
        }

        # Move the file to the target subfolder if it's not already there
        $targetFilePath = Join-Path -Path $targetFolder -ChildPath $file.Name
        if ($file.FullName -ne $targetFilePath) {
            Move-Item -Path $file.FullName -Destination $targetFilePath
        }
    }

    # Clean up empty folders
    $allFolders = Get-ChildItem -Path $baseDirectory -Directory -Recurse
    foreach ($folder in $allFolders) {
        if ((Get-ChildItem -Path $folder.FullName).Count -eq 0) {
            Remove-Item -Path $folder.FullName
        }
    }
}

# Example Usage:
# Reorganize-FilesByType -baseDirectory "C:\Path\To\Your\Files"
