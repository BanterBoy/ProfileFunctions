function Randomize-FilesIntoSubfolders {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$baseDirectory,
        [Parameter(Mandatory = $true)]
        [int]$numFolders
    )

    # Check if the directory exists
    if (-Not (Test-Path -Path $baseDirectory)) {
        Write-Error "The directory '$baseDirectory' does not exist."
        return
    }

    # Check if the directory is not empty
    $files = Get-ChildItem -Path $baseDirectory -File
    if ($files.Count -eq 0) {
        Write-Warning "There are no files in the base directory '$baseDirectory' to move."
        return
    }

    # Generate random folder names and create them
    $randomFolderNames = 1..$numFolders | ForEach-Object {
        $randomFolderName = [System.IO.Path]::GetRandomFileName().Replace(".", "")
        $folderPath = Join-Path -Path $baseDirectory -ChildPath $randomFolderName
        New-Item -Path $folderPath -ItemType Directory | Out-Null
        $folderPath
    }

    # Move files to random folders
    foreach ($file in $files) {
        $randomFolderPath = Get-Random -InputObject $randomFolderNames
        $destinationPath = Join-Path -Path $randomFolderPath -ChildPath $file.Name
        Move-Item -Path $file.FullName -Destination $destinationPath
    }
}

# Example Usage:
# Randomize-FilesIntoSubfolders -baseDirectory "C:\Path\To\Your\Files" -numFolders 5
