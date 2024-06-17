function Remove-FoldersWithoutSpecifiedFiles {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string[]]$FileTypes,

        [Parameter(Mandatory = $false)]
        [switch]$Validation,

        [Parameter(Mandatory = $false)]
        [string]$ReportPath = "DeletionReport.csv"
    )

    # Helper function to determine if a folder or any of its subfolders contain specified file types
    function Test-SpecifiedFilesExist {
        param (
            [Parameter(Mandatory = $true)]
            [string]$FolderPath,
    
            [Parameter(Mandatory = $true)]
            [string[]]$FileTypes
        )
    
        foreach ($fileType in $FileTypes) {
            if ((Get-ChildItem -Path $FolderPath -Filter "*.$fileType" -File -Recurse).Count -gt 0) {
                return $true
            }
        }
        return $false
    }

    # Helper function to get list of files in the folder
    function Get-FilesInFolder {
        param (
            [Parameter(Mandatory = $true)]
            [string]$FolderPath
        )

        return Get-ChildItem -Path $FolderPath -File -Recurse | Select-Object -ExpandProperty FullName
    }

    $deletionReport = @()

    # Get all directories recursively, sorted in descending order
    $directories = Get-ChildItem -Path $Path -Directory -Recurse | Sort-Object -Property FullName -Descending

    foreach ($dir in $directories) {
        if (-not (Test-SpecifiedFilesExist -FolderPath $dir.FullName -FileTypes $FileTypes)) {
            $filesInFolder = (Get-FilesInFolder -FolderPath $dir.FullName) -join "; "
            if ($Validation) {
                $deletionReport += [pscustomobject]@{
                    Path          = $dir.FullName
                    Type          = "Folder"
                    ContainsFiles = $filesInFolder
                }
            }
            else {
                try {
                    Remove-Item -Path $dir.FullName -Force -Recurse
                    Write-Output "Removed folder without specified files: $($dir.FullName)"
                }
                catch {
                    Write-Output "Failed to remove folder: $($dir.FullName) - $_"
                }
            }
        }
    }

    # Check if the root folder itself should be removed
    if (-not (Test-SpecifiedFilesExist -FolderPath $Path -FileTypes $FileTypes)) {
        $filesInFolder = (Get-FilesInFolder -FolderPath $Path) -join "; "
        if ($Validation) {
            $deletionReport += [pscustomobject]@{
                Path          = $Path
                Type          = "Folder"
                ContainsFiles = $filesInFolder
            }
        }
        else {
            try {
                Remove-Item -Path $Path -Force -Recurse
                Write-Output "Removed root folder without specified files: $Path"
            }
            catch {
                Write-Output "Failed to remove root folder: $Path - $_"
            }
        }
    }

    if ($Validation -and $deletionReport.Count -gt 0) {
        $deletionReport | Export-Csv -Path $ReportPath -NoTypeInformation
        Write-Output "Validation report saved to $ReportPath"
    }
    elseif ($Validation) {
        Write-Output "No folders or files to delete."
    }
}

# Example usage with validation:
# Remove-FoldersWithoutSpecifiedFiles -Path "\\deathstar.domain.leigh-services.com\MyMusic\" -FileTypes "mp3" -Validation -ReportPath "C:\Temp\NonMP3Folders.csv"

# Example usage without validation:
# Remove-FoldersWithoutSpecifiedFiles -Path "\\deathstar.domain.leigh-services.com\MyMusic\" -FileTypes "mp3"