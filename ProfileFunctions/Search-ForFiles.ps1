<#
.SYNOPSIS
    Searches for files in a specified directory that match a given search term and file extension(s).
.DESCRIPTION
    This function searches for files in a specified directory that match a given search term and file extension(s). 
    The search can be performed for files that start with, end with, or contain the search term. 
    The function can also search recursively and filter by last write time.
.PARAMETER Path
    Specifies the base path you would like to search.
.PARAMETER SearchTerm
    Specifies the text you would like to search for.
.PARAMETER Extension
    Specifies the file extension(s) you are looking for. Defaults to all files.
.PARAMETER SearchType
    Specifies the type of search. You can select Start/End/Wild to perform search for a file.
.PARAMETER Recurse
    Specifies whether to search recursively.
.PARAMETER LastWriteTime
    Specifies the last write time to filter by.
.EXAMPLE
    Search-ForFiles -Path "C:\MyFolder" -SearchTerm "test" -Extension ".txt" -SearchType "Wild" -Recurse -LastWriteTime "2022-01-01"
    This example searches for files in the C:\MyFolder directory that contain the text "test" and have a .txt extension. 
    The search is performed recursively and filters by files that were last written to on or after January 1st, 2022.
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
        
    $searchPattern = "*$SearchTerm*"
    switch ($SearchType) {
        Start {
            $searchPattern = "$SearchTerm*"
        }
        End {
            $searchPattern = "*$SearchTerm"
        }
    }
        
    $ChildItemParams = @{
        Path    = $Path
        File    = $true
        Recurse = $Recurse.IsPresent
        Include = $Extension
    }
        
    $files = Get-ChildItem @ChildItemParams | Where-Object { $_.Name -like $searchPattern -and $_.LastWriteTime -ge $LastWriteTime } | Sort-Object -Property LastWriteTime -Descending
    
    if ($PSCmdlet.ShouldProcess($Path, "Search for files matching '$SearchTerm'")) {
        return $files
    }
}
