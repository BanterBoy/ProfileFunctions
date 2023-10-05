function Search-ForFiles {

    <#

    .SYNOPSIS
    A function to search for files

<<<<<<< Updated upstream
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
=======
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
    .MAP	Web page imagemap
    .MDB	MS Access database
    .MID or .MIDI	MIDI sound
    .MKV    Matroska video
    .MOV or .QT	QuickTime Audio/Video
    .MTB or .MTW	MiniTab
    .PDF	Acrobat -Portable document format
    .P65
    .T65	PageMaker (the numbers following represent the version #) P=publication, T=template
    .PNG	Portable Network Graphics
    .PPT or .PPTX	PowerPoint
    .PSD	Adobe PhotoShop
    .PSP	PaintShop Pro
    .QXD	QuarkXPress
    .RA	RealAudio
    .RTF	Rich Text Format
    .SIT	Stuffit Compressed Archive
    .TAR	UNIX TAR Compressed Archive
    .TIF	TIFF graphic
    .TXT	ASCII text (Mac text does not contain line feeds--use DOS Washer Utility to fix)
    .WAV	Windows sound
    .WK3	Lotus 1-2-3 (the numbers following represent the version #)
    .WKS	MS Works
    WPD or .WP5	WordPerfect (the numbers following represent the version #)
    .XLS or .XLSX	Excel spreadsheet
    .ZIP	PC Zip Compressed Archive

    .PARAMETER SearchType
    Specifies the type of search perfomed. Options are Start, End or Wild. This will search either the beginning, end or somewhere inbetween. If no option is selected, it will default to performing a wildcard search.

    .EXAMPLE
    Search-ForFiles -Path .\scripts-blog\PowerShell\ -SearchTerm dns -SearchType Wild -Extension *.PS1
    
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
    System.String. Search-ForFiles returns a string with the extension or file name.

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
>>>>>>> Stashed changes

    [CmdletBinding(DefaultParameterSetName = 'Default',
        SupportsShouldProcess = $false,
        ConfirmImpact = 'Medium')]
    [Alias('Find-Files', 'sff')]
    Param(
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ParameterSetName = "Default",
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            HelpMessage = "Enter the base path you would like to search."
        )]
        [ValidateNotNullOrEmpty()]
        [Alias("PSPath")]
        [string]$Path,
<<<<<<< Updated upstream
        
=======

>>>>>>> Stashed changes
        [Parameter(
            Mandatory = $false,
            Position = 2,
            ParameterSetName = "Default",
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            HelpMessage = "Select the file extension you are looking for. Defaults to '*.*' files.")]
        [ValidateSet('*.AIFF', '*.AIF', '*.AU', '*.AVI', '*.BAT', '*.BMP', '*.CHM', '*.CLASS', '*.CONFIG', '*.CSS', '*.CSV', '*.CVS', '*.DBF', '*.DIF', '*.DOC', '*.DOCX', '*.DLL', '*.DOTX', '*.EPUB', '*.EPS', '*.EXE', '*.FM3', '*.GIF', '*.HQX', '*.HTM', '*.HTML', '*.ICO', '*.INF', '*.INI', '*.JAVA', '*.JPG', '*.JPEG', '*.JSON', '*.LOG', '*.MD', '*.MP4', '*.MAC', '*.MAP', '*.MDB', '*.MID', '*.MIDI', '*.MKV', '*.MOV', '*.QT', '*.MTB', '*.MTW', '*.PDB', '*.PDF', '*.P65', '*.PNG', '*.PPT', '*.PPTX', '*.PSD', '*.PSP', '*.PS1', '*.PSD1', '*.PSM1', '*.QXD', '*.RA', '*.RTF', '*.SIT', '*.SVG', '*.TAR', '*.TIF', '*.T65', '*.TXT', '*.VBS', '*.VSDX', '*.WAV', '*.WK3', '*.WKS', '*.WPD', '*.WP5', '*.XLS', '*.XLSX', '*.XML', '*.YML', '*.ZIP', '*.*') ]
        [string]$Extension = '*.*',

        [Parameter(
            Mandatory = $true,
            Position = 1,
            ParameterSetName = "Default",
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            HelpMessage = "Enter the text you would like to search for."
        )]
        [ValidateNotNullOrEmpty()]
        [string]$SearchTerm,
<<<<<<< Updated upstream
        
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
=======

        [switch]$Recurse,

        [switch]$LogErrors
    )
    Begin {
        $ErrorLog = @()
    }
    Process {
        if ($pscmdlet.ShouldProcess("$Path", "Search for $Extension files with the name $SearchTerm")) {
            try {
                $FileName = "$SearchTerm" + $Extension
                $ChildItemParams = @{
                    Path    = $Path
                    File    = $true
                    Recurse = $Recurse.IsPresent
                    Filter  = $FileName
                }
                Get-ChildItem @ChildItemParams
            }
            catch {
                $ErrorMessage = $_.Exception.Message
                if ($LogErrors.IsPresent) {
                    $ErrorLog += $ErrorMessage
                }
                Write-Warning $ErrorMessage
            }
        }
    }
    End {
        if ($LogErrors.IsPresent -and $ErrorLog.Count -gt 0) {
            $ErrorLog | Out-File -FilePath "C:\SearchForFilesErrors.txt" -Append
        }
>>>>>>> Stashed changes
    }
}
