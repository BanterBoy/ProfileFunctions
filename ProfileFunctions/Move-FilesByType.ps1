function Move-FilesByType {
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

    # Get all files in the directory
    $files = Get-ChildItem -Path $baseDirectory -File

    # Loop through each file
    foreach ($file in $files) {
        # Extract the file extension and prepare the target subfolder path
        $fileExtension = $file.Extension.TrimStart('.')
        $targetFolder = Join-Path -Path $baseDirectory -ChildPath $fileExtension

        # Create the subfolder if it doesn't exist
        if (-Not (Test-Path -Path $targetFolder)) {
            New-Item -Path $targetFolder -ItemType Directory | Out-Null
        }

        # Move the file to the target subfolder
        $targetFilePath = Join-Path -Path $targetFolder -ChildPath $file.Name
        Move-Item -Path $file.FullName -Destination $targetFilePath
    }
}

# Example Usage:
# Move-FilesByType -baseDirectory "C:\Path\To\Your\Files"
