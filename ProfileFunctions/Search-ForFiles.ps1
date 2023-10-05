function Search-ForFiles {

    <#
    
        .SYNOPSIS
        A function to search for files
    
        .DESCRIPTION
        A function to search for files.
    
        Searches are performed by passing the parameters to Get-Childitem which will then recursively search through your specified file path and then perform a sort to output
        the most recently amended files at the top of the list.
    
        Outputs inlcude the Name, DirectoryName and FullName

        If the extension is not provided it defaults to searching for PS1 files (PowerShell Scripts).
    
        Using the switch you can choose to search the start or end of the file or selecting wild, will perform a wildcard search using your searchterm.
    
        .PARAMETER Path
        Species the search path. The search will perform a recursive search on the specified folder path.
    
        .PARAMETER SearchTerm
        Specifies the search string. This will define the text that the search will use to locate your files. Wildcard chars are not allowed.
    
        .PARAMETER Extension
        Specifies the extension. ".*" is the default. You can tab complete through the suggested list of extensions."

        '*.AIFF', '*.AIF', '*.AU', '*.AVI', '*.BAT', '*.BMP', '*.CHM', '*.CLASS', '*.CONFIG', '*.CSS', '*.CSV', '*.CVS', '*.DBF', '*.DIF', '*.DOC', '*.DOCX', '*.DLL', '*.DOTX', '*.EPUB',  '*.EPS', '*.EXE', '*.FM3', '*.GIF', '*.HQX', '*.HTM', '*.HTML', '*.ICO', '*.INF', '*.INI', '*.JAVA', '*.JPG', '*.JPEG', '*.JSON', '*.LOG', '*.MD', '*.MP4', '*.MAC', '*.MAP', '*.MDB', '*.MID', '*.MIDI', '*.MKV', '*.MOV', '*.QT', '*.MTB', '*.MTW', '*.PDB', '*.PDF', '*.P65', '*.PNG', '*.PPT', '*.PPTX', '*.PSD', '*.PSP', '*.PS1', '*.PSD1', '*.PSM1', '*.QXD', '*.RA', '*.RTF', '*.SIT', '*.SVG', '*.TAR', '*.TIF', '*.T65', '*.TXT', '*.VBS', '*.VSDX', '*.WAV', '*.WK3', '*.WKS', '*.WPD', '*.WP5', '*.XLS', '*.XLSX', '*.XML', '*.YML', '*.ZIP', '*.*'

        .AIFF or .AIF	Audio Interchange File Format
        .AU	Basic Audio
        .AVI	Multimedia Audio/Video
        .BAT	PC batch file
        .BMP	Windows BitMap
        .CLASS or .JAVA	Java files
        .CSV	Comma separated, variable length file (Open in Excel)
        .CVS	Canvas
        .DBF	dbase II, III, IV data
        .DIF	Data Interchange format
        .DOC or .DOCX	Microsoft Word for Windows/Word97
        .EPUB    EPUB ebook format
        .EPS	Encapsulated PostScript
        .EXE	PC Application
        .FM3	Filemaker Pro databases (the numbers following represent the version #)
        .GIF	Graphics Interchange Format
        .HQX	Macintosh BinHex
        .HTM or .HTML	Web page source text
        .JPG or JPEG	JPEG graphic
        .MAC	MacPaint
        <#
        .SYNOPSIS
            Searches for files in a specified directory based on search term, extension, and search type.
        .DESCRIPTION
            This function searches for files in a specified directory based on search term, extension, and search type. It can also search recursively and filter by last write time.
        .PARAMETER Path
            The base path to search.
        .PARAMETER SearchTerm
            The text to search for in the file names.
        .PARAMETER Extension
            The file extension(s) to search for. Defaults to all files.
        .PARAMETER SearchType
            The type of search to perform. Options are Start, End, or Wild. Defaults to Wild.
        .PARAMETER Recurse
            Indicates whether to search recursively.
        .PARAMETER LastWriteTime
            Filters the search results by last write time.
        .EXAMPLE
            Search-ForFiles -Path C:\Scripts -SearchTerm "test" -Extension ".ps1" -SearchType Wild -Recurse
            Searches for all files in the C:\Scripts directory and its subdirectories that contain "test" in their file names and have a .ps1 extension.
        .NOTES
            Author:     Luke Leigh
            Website:    https://scripts.lukeleigh.com/
            LinkedIn:   https://www.linkedin.com/in/lukeleigh/
            GitHub:     https://github.com/BanterBoy/
            GitHubGist: https://gist.github.com/BanterBoy
        #>

    [CmdletBinding(DefaultParameterSetName = 'Default',
        SupportsShouldProcess = $false,
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
        
    if ($files) {
        $files | Select-Object Name, DirectoryName, FullName, LastWriteTime
    }
}
