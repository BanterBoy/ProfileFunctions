<#
.SYNOPSIS
    Searches for files in a specified directory and returns a list of files that match the specified criteria.

.DESCRIPTION
    The Search-ForFiles function searches for files in a specified directory and returns a list of files that match the specified criteria. The function supports searching for files based on file name, file extension, and last write time. The function can also perform a recursive search of subdirectories.

.PARAMETER Path
    Specifies the base path to search. This parameter is mandatory.

.PARAMETER SearchTerm
    Specifies the text to search for in the file name. This parameter is optional and defaults to "*".

.PARAMETER Extension
    Specifies the file extension(s) to search for. This parameter is optional and defaults to all files.

.PARAMETER SearchType
    Specifies the type of search to perform. Valid values are "Start", "End", and "Wild". This parameter is optional and defaults to "Wild".

.PARAMETER Recurse
    Specifies whether to perform a recursive search of subdirectories. This parameter is optional and defaults to false.

.PARAMETER LastWriteTime
    Specifies the minimum last write time for files to include in the search results. This parameter is optional.

.OUTPUTS
    Returns a list of files that match the specified criteria.

.EXAMPLE
    Search-ForFiles -Path "C:\MyFiles" -SearchTerm "Report" -Extension ".docx" -SearchType "Start" -Recurse

    This example searches for files in the "C:\MyFiles" directory that start with "Report", have a ".docx" extension, and are located in subdirectories.

.NOTES
    Author: Luke Leigh
    Last Edit: 16/10/2023
#>
function Search-ForFiles {
    [CmdletBinding(DefaultParameterSetName = 'Default',
        SupportsShouldProcess = $true,
        ConfirmImpact = 'Medium')]
    [Alias('Find-Files', 'sff')]
    [OutputType([String])]
    Param(
        [Parameter(
            Mandatory,
            Position = 0,
            ParameterSetName = "Default",
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            HelpMessage = "Enter the base path you would like to search."
        )]
        [ValidateNotNullOrEmpty()]
        [Alias("PSPath")]
        [string]$Path,
        
        [Parameter(
            Mandatory = $false,
            Position = 1,
            ParameterSetName = "Default",
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            HelpMessage = "Enter the text you would like to search for."
        )]
        [ValidateNotNullOrEmpty()]
        [string]$SearchTerm = "*",
        
        [Parameter(
            Mandatory = $false,
            Position = 2,
            ParameterSetName = "Default",
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            HelpMessage = "Select the file extension(s) you are looking for. Defaults to all files."
        )]
        [string[]]$Extension = @('*'),
        
        [Parameter(
            Mandatory = $false,
            Position = 3,
            ParameterSetName = "Default",
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            HelpMessage = "Select the type of search. You can select Start/End/Wild to perform search for a file."
        )]
        [ValidateSet('Start', 'End', 'Wild')]
        [string]$SearchType,
        
        [Parameter(Mandatory = $false)]
        [switch]$Recurse,
        
        [Parameter(Mandatory = $false)]
        [DateTime]$LastWriteTime
    )
        

    process {
        try {
            $searchPattern = "*$SearchTerm*"
            switch ($SearchType) {
                Start {
                    $searchPattern = "$SearchTerm*"
                }
                End {
                    $searchPattern = "*$SearchTerm"
                }
            }

            Write-Verbose "Search pattern: $searchPattern"

            $ChildItemParams = @{
                Path    = $Path
                File    = $true
                Recurse = $Recurse.IsPresent
                Include = $Extension
            }

            Write-Verbose "Child item parameters: $($ChildItemParams | Out-String)"

            $files = Get-ChildItem @ChildItemParams -ErrorAction Stop | Where-Object { $_.Name -like $searchPattern -and $_.LastWriteTime -ge $LastWriteTime } | Sort-Object -Property LastWriteTime -Descending

            Write-Verbose "Found $($files.Count) files"
        }
        catch {
            Write-Error "An error occurred: $_"
            throw $_
        }

        if ($PSCmdlet.ShouldProcess($Path, "Search for files matching '$SearchTerm'")) {
            return $files
        }
    }
}
