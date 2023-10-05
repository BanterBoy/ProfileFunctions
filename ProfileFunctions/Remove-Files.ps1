function Remove-Files {

    <#
    .SYNOPSIS
        Removes an array of files.

    .PARAMETER Files
        An array of files to be removed.

    .EXAMPLE
        Remove-Files -Files "C:\temp\file1.txt", "C:\temp\file2.txt"
        This example removes the files "file1.txt" and "file2.txt" from the "C:\temp" directory.

    .NOTES
        Author: [Author Name]
        Date: [Date]
    #>

    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [array]$Files
    )
    Write-Verbose -Message "Removing $($Files.Count) old files"
    $Files | ForEach-Object -Process {
        if ($PSCmdlet.ShouldProcess("$($_.Name)", "Deleting file...")) {
            Write-Verbose -Message "Removing file $($_.FullName)"
            try {
                $_ | Remove-Item
            }
            catch {
                Write-Error -Message "Failed to remove file $($_.FullName)"
            }
        }
    }
}
