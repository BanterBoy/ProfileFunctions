<#
.SYNOPSIS
    Gets files that are older than a specified number of days.

.DESCRIPTION
    The Get-OldFiles function gets files that are older than a specified number of days. You can specify the path to search, the file type to search for, and whether to search recursively. You can also choose to summarize the results or display detailed information about each file. The function returns an object with the following properties:
    - TimeStamp: The date and time that the file was last modified.
    - Path: The path to the file.
    - FileName: The name of the file.
    - FileSize: The size of the file in a human-readable format.
    - FullPath: The full path to the file.

.PARAMETER Path
    Specifies the path to search for files. This parameter is mandatory. Wildcards are permitted. If the path includes escape characters, enclose it in single quotation marks. Single quotation marks tell PowerShell not to interpret any characters as escape sequences.

.PARAMETER LiteralPath
    Specifies the literal path to search for files. This parameter is mandatory. Unlike Path, the value of LiteralPath is used exactly as it is typed. No characters are interpreted as wildcards. If the path includes escape characters, enclose it in single quotation marks. Single quotation marks tell PowerShell not to interpret any characters as escape sequences.

.PARAMETER Days
    Specifies the number of days that a file must be older than to be included in the results. The default value is 7.

.PARAMETER FileName
    Specifies the file type to search for. The default value is "*.*".

.PARAMETER Recurse
    Indicates whether to search recursively. By default, the search is not recursive.

.PARAMETER Summarize
    Indicates whether to summarize the results. If this parameter is specified, the function returns a string that summarizes the number of files found and their total size.

.EXAMPLE
    PS C:\> Get-OldFiles -Path C:\Logs -Days 30 -FileName *.log -Recurse

    This example gets all log files in the C:\Logs directory and its subdirectories that are older than 30 days.

.EXAMPLE
    PS C:\> Get-OldFiles -LiteralPath "C:\Program Files" -Days 90 -FileName *.dll -Summarize

    This example gets all DLL files in the C:\Program Files directory that are older than 90 days and returns a summary of the results.

.EXAMPLE
    PS C:\> Get-OldFiles -Path C:\Logs -Days 30 -FileName *.log -Recurse -Summarize

    This example gets all log files in the C:\Logs directory and its subdirectories that are older than 30 days and returns a summary of the results.

.NOTES
        Author: Luke Leigh
        Last Edit: 21/07/2023
        Version: 1.0
#>
function Get-OldFiles {
    [CmdletBinding(DefaultParameterSetName = 'Path',
        SupportsShouldProcess = $true,
        ConfirmImpact = 'Medium')]
    [Alias('gof')]
    [OutputType([String])]
    param(
        [Parameter(Mandatory = $true,
            Position = 0,
            ParameterSetName = 'Path')]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({ Test-Path -Path $_ })]
        [String]$Path,

        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'LiteralPath')]
        [string]$LiteralPath,

        [Parameter(Mandatory = $false,
            Position = 1)]
        [ValidateNotNullOrEmpty()]
        [ValidateRange(1, 9999)]
        [Int]$Days = 7,

        [Parameter(Mandatory = $true,
            Position = 2)]
        [ValidateNotNullOrEmpty()]
        [String]$FileName,

        [Parameter(Mandatory = $false)]
        [switch]$Recurse,

        [Parameter(Mandatory = $false)]
        [switch]$Summarize
        
    )

    begin {
        Write-Verbose -Message "Starting processing of $($FileName) files older than $($Days) days"
        $TotalSize = 0
    }

    process {
        if ($PSBoundParameters.ContainsKey('LiteralPath')) {
            $Path = $LiteralPath
        }

        if ($Summarize) {
            Write-Verbose -Message "Calculating total size of $($FileName) files older than $($Days) days"
            $ChildItemParams = @{
                LiteralPath = $Path
                File        = $true
                Recurse     = $Recurse.IsPresent
                Filter      = $FileName
            }
            $TotalSize = Get-ChildItem @ChildItemParams | Where-Object -FilterScript {
                $_.LastWriteTime -lt (Get-Date).AddDays(-$Days)
            } | Measure-Object -Property Length -Sum | Select-Object -ExpandProperty Sum
        }
        else {
            Write-Verbose -Message "Searching for $($FileName) files older than $($Days) days"
            $ChildItemParams = @{
                LiteralPath = $Path
                File        = $true
                Recurse     = $Recurse.IsPresent
                Filter      = $FileName
            }
            Get-ChildItem @ChildItemParams | Where-Object -FilterScript {
                $_.LastWriteTime -lt (Get-Date).AddDays(-$Days)
            } | ForEach-Object -Process {
                $FileSize = Get-FriendlySize -Bytes $_.Length
                $Properties = [ordered]@{
                    TimeStamp = $_.LastWriteTime
                    Path      = $_.Directory
                    FileName  = $_.Name
                    FileSize  = $FileSize.FriendlySize
                    FullPath  = $_.FullName
                }
                $Object = New-Object -TypeName psobject -Property $Properties
                Write-Output -InputObject $Object
                $TotalSize += $_.Length
            } | Sort-Object -Property TimeStamp
        }
    }

    end {
        $FileCount = @(Get-ChildItem @ChildItemParams | Where-Object -FilterScript {
                $_.LastWriteTime -lt (Get-Date).AddDays(-$Days)
            }).Count

        if ($Summarize) {
            $FriendlySize = Get-FriendlySize -Bytes $TotalSize
            Write-Verbose -Message "Found $($FileCount) $($FileName) files older than $($Days) days with a total size of $($FriendlySize.FriendlySize)"
            return "Found $($FileCount) $($FileName) files older than $($Days) days with a total size of $($FriendlySize.FriendlySize)"
        }
        else {
            Write-Verbose -Message "Completed processing of $($FileName) files older than $($Days) days"
        }
    }
}
