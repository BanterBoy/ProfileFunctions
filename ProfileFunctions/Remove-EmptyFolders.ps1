function Remove-EmptyFolders {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Path
    )

    # Helper function to determine if a folder is empty
    function Is-EmptyFolder {
        param (
            [Parameter(Mandatory = $true)]
            [string]$FolderPath
        )
        # Check if the folder contains any files or subfolders
        if ((Get-ChildItem -Path $FolderPath -File).Count -eq 0 -and
            (Get-ChildItem -Path $FolderPath -Directory).Count -eq 0) {
            return $true
        }
        return $false
    }

    # Get all directories recursively
    $directories = Get-ChildItem -Path $Path -Directory -Recurse | Sort-Object -Property FullName -Descending

    foreach ($dir in $directories) {
        if (Is-EmptyFolder -FolderPath $dir.FullName) {
            try {
                Remove-Item -Path $dir.FullName -Force -Recurse
                Write-Output "Removed empty folder: $($dir.FullName)"
            }
            catch {
                Write-Output "Failed to remove folder: $($dir.FullName) - $_"
            }
        }
    }

    # Check if the root folder itself is empty and remove if necessary
    if (Is-EmptyFolder -FolderPath $Path) {
        try {
            Remove-Item -Path $Path -Force -Recurse
            Write-Output "Removed empty root folder: $Path"
        }
        catch {
            Write-Output "Failed to remove root folder: $Path - $_"
        }
    }
}

# Remove-EmptyFolders "\\deathstar.domain.leigh-services.com\MyMusic\" -Verbose
