function New-FileofSize {

    <#
    .SYNOPSIS
    Creates a new file of specified size.
    
    .DESCRIPTION
    This script creates a new file with a specified size in MB, KB, or GB at the given file path.
    
    .NOTES
    Author  : Luke Leigh
    Website : https://blog.lukeleigh.com
    Twitter : https://twitter.com/luke_leighs
    
    .PARAMETER FilePath
    The path where the new file will be created. Must be an existing directory.
    
    .PARAMETER FileName
    The name of the new file. 
    
    .PARAMETER FileSize
    The size of the new file. Must be a positive integer.
    
    .PARAMETER SizeType
    The size type of the new file (KB, MB, GB). Default is MB.
    
    .INPUTS
    None. Does not accept piped input.
    
    .OUTPUTS
    String. Returns a message about the file creation.
    
    .EXAMPLE
    New-FileofSize -FilePath "C:\GitRepos" -FileName "NewDummy.txt" -FileSize 2048 -SizeType MB
    
    .LINK
    https://blog.lukeleigh.com
    
    .FUNCTIONALITY
    File creation
    #>
    
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([String])]
    Param (
        # The path where the new file will be created
        [Parameter(Mandatory = $true, HelpMessage = "The path where the new file will be created")]
        [ValidateScript({ Test-Path $_ -PathType Container })]
        [string]$FilePath,
    
        # The name of the new file
        [Parameter(Mandatory = $true, HelpMessage = "The name of the new file")]
        [string]$FileName,
    
        # The size of the new file
        [Parameter(Mandatory = $true, HelpMessage = "The size of the new file")]
        [ValidateRange(1, [int]::MaxValue)]
        [int]$FileSize,
    
        # The size type of the new file (KB, MB, GB)
        [Parameter(Mandatory = $false, HelpMessage = "The size type of the new file (KB, MB, GB)")]
        [ValidateSet("KB", "MB", "GB")]
        [string]$SizeType = "MB"
    )
    
    begin {
        # Initialization code can be added here if needed
    }
    
    process {
        try {
            $fullFilePath = Join-Path -Path $FilePath -ChildPath $FileName
    
            # Convert file size to bytes
            switch ($SizeType) {
                "KB" { $sizeBytes = $FileSize * 1KB }
                "MB" { $sizeBytes = $FileSize * 1MB }
                "GB" { $sizeBytes = $FileSize * 1GB }
            }
    
            if ($PSCmdlet.ShouldProcess("$fullFilePath", "Create dummy file of size $FileSize $SizeType")) {
                $FileStream = [System.IO.File]::Create($fullFilePath)
                $FileStream.SetLength($sizeBytes)
                $FileStream.Close()
                $FileStream.Dispose()
    
                Write-Output "File '$FileName' created at '$FilePath' with size $FileSize $SizeType."
            }
        }
        catch {
            Write-Error -Message "An error occurred while creating the file: $_"
        }
    }
    
    end {
        # Cleanup code can be added here if needed
    }
}
