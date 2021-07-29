function Search-ForFiles {
    <#
    
        .SYNOPSIS
        A function to search for files
    
        .DESCRIPTION
        A function to search for files.
    
        Searches are performed by passing the parameters to Get-Childitem which will then
        recursively search through your specified file path and then perform a sort to output
        the most recently amended files at the top of the list.
    
        Outputs inlcude the Name,DirectoryName and FullName
    
        Name                        DirectoryName                                       FullName
        ----                        -------------                                       --------
        Get-PublicDnsRecord.ps1     C:\GitRepos\scripts-blog\PowerShell\functions\dns   C:\GitRepos\scripts-blog\PowerShell\functions\dns\Get-PublicDnsRecord.ps1
    
        If the extension is not provided it defaults to searching for PS1 files (PowerShell Scripts).
    
        Using the switch you can choose to search the start or end of the file or selecting wild,
        will perform a wildcard search using your searchterm.
    
        .PARAMETER Path
        Species the search path. The search will perform a recursive search on the specified folder path.
    
        .PARAMETER SearchTerm
        Specifies the search string. This will define the text that the search will use to locate your files. Wildcard chars are not allowed.
    
        .PARAMETER Extension
        Specifies the extension. ".ps1" is the default. You can tab complete through the suggested list or you can enter your own file extension e.g. ".jpg"
    
        .PARAMETER SearchType
        Specifies the type of search perfomed. Options are Start, End or Wild. This will search either the beginning, end or somewhere inbetween. If no option is selected, it will default to performing a wildcard search.
    
        .EXAMPLE
        Search-Scripts -Path .\scripts-blog\PowerShell\ -SearchTerm dns -SearchType Wild -Extension .ps1
        
        Name                        DirectoryName                                       FullName
        ----                        -------------                                       --------
        Get-PublicDnsRecord.ps1     C:\GitRepos\scripts-blog\PowerShell\functions\dns   C:\GitRepos\scripts-blog\PowerShell\functions\dns\Get-PublicDnsRecord.ps1
        
        Recursively scans the folder path looking for all files containing the searchterm and lists the files located in the output
    
        .INPUTS
        You can pipe objects to these perameters.
    
        - Path [string]
        - SearchTerm [string]
        - Extension [string]
        - SearchType [string]
    
    
        .OUTPUTS
        System.String. Search-Scripts returns a string with the extension or file name.
    
        Name                        DirectoryName                                       FullName
        ----                        -------------                                       --------
        Get-PublicDnsRecord.ps1     C:\GitRepos\scripts-blog\PowerShell\functions\dns   C:\GitRepos\scripts-blog\PowerShell\functions\dns\Get-PublicDnsRecord.ps1
    
        .NOTES
        Author:     Luke Leigh
        Website:    https://scripts.lukeleigh.com/
        LinkedIn:   https://www.linkedin.com/in/lukeleigh/
        GitHub:     https://github.com/BanterBoy/
        GitHubGist: https://gist.github.com/BanterBoy
    
        .LINK
        https://github.com/BanterBoy/scripts-blog
        Get-Childitem
        Select-Object
    
    #>
    [CmdletBinding(DefaultParameterSetName = 'Default',
        SupportsShouldProcess = $true,
        ConfirmImpact = 'Medium')]
    [Alias()]
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
            Mandatory,
            Position = 1,
            ParameterSetName = "Default",
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            HelpMessage = "Enter the text you would like to search for."
        )]    
        [ValidateNotNullOrEmpty()]
        [string]$SearchTerm,
        
        [Parameter(
            Mandatory = $false,
            Position = 2,
            ParameterSetName = "Default",
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            HelpMessage = "Select the file extension you are looking for. Defaults to '*.ps1' files.")]
        [ValidateSet('.csv', '.doc', '.docx', '.json', '.log', '.pdf', '.ps1', '.txt', '.xls', '.xlsx', '.*') ]
        [string]$Extension = '.*',

        [Parameter(
            Mandatory = $false,
            Position = 3,
            ParameterSetName = "Default",
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            HelpMessage = "Select the type of search. You can select Start/End/Wild to perform search for a file.")]
        [ValidateSet('Start', 'End', 'Wild') ]
        [string]$SearchType

    )

    switch ($SearchType) {
        Start {
            if ($pscmdlet.ShouldProcess("Target", "Operation")) {
                try {
                    $FileName = "$SearchTerm*" + $Extension
                    Get-ChildItem -Path $Path -Include $FileName -Recurse |
                    Select-Object -Property Name, DirectoryName, FullName
                }
                catch {
                    Write-Warning "Catch all"
                }
            }
        }
        End {
            if ($pscmdlet.ShouldProcess("Target", "Operation")) {
                try {
                    $FileName = "*$SearchTerm" + $Extension
                    Get-ChildItem -Path $Path -Include $FileName -Recurse |
                    Select-Object -Property Name, DirectoryName, FullName
                }
                catch {
                    Write-Warning "Catch all"
                }
            }
        }
        Wild {
            if ($pscmdlet.ShouldProcess("Target", "Operation")) {
                try {
                    $FileName = "*$SearchTerm*" + $Extension
                    Get-ChildItem -Path $Path -Include $FileName -Recurse |
                    Select-Object -Property Name, DirectoryName, FullName
                }
                catch {
                    Write-Warning "Catch all"
                }
            }
        }
        Default {
            if ($pscmdlet.ShouldProcess("Target", "Operation")) {
                try {
                    $FileName = "*$SearchTerm*" + $Extension
                    Get-ChildItem -Path $Path -Include $FileName -Recurse |
                    Select-Object -Property Name, DirectoryName, FullName
                }
                catch {
                    Write-Warning "Catch all"
                }
            }
        }
    }
}
