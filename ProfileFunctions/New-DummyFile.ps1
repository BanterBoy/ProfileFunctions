function New-DummyFile {
    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = 'Medium'
    )]
    Param (
        [Parameter(Mandatory = $true)]
        [ValidateScript({ Test-Path $_ -PathType Container })]
        [string] $FilePath,

        [Parameter(Mandatory = $true)]
        [ValidateScript({ $_ -match '^[^\\/:*?"<>|]+$' })]
        [string] $FileName,

        [Parameter(Mandatory = $true)]
        [ValidateRange(1, [int]::MaxValue)]
        [int] $FileSizeMB
    )

    process {
        try {
            $fullPath = Join-Path -Path $FilePath -ChildPath $FileName
            $sizeBytes = $FileSizeMB * 1MB

            if ($PSCmdlet.ShouldProcess($fullPath, "Create dummy file of size $sizeBytes bytes")) {
                $fileStream = New-Object System.IO.FileStream($fullPath, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None, $sizeBytes)
                $fileStream.SetLength($sizeBytes)
                $fileStream.Close()
                Write-Output "$FileName created @ $sizeBytes bytes in size."
            }
        }
        catch {
            Write-Error -Message "Failed to create dummy file: $_"
        }
    }
}

# Example usage:
# New-DummyFile -FilePath "C:\temp" -FileName "dummy.txt" -FileSizeMB 10
