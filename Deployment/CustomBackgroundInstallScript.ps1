function Convert-ImageForTeams {
    <#
    .SYNOPSIS
    Converts images in a source folder to PNG format and creates thumbnail images.
    
    .DESCRIPTION
    This function converts images in a source folder to PNG format and creates thumbnail images. The converted images and thumbnails are saved in a destination folder with GUID-based names.
    
    .PARAMETER sourceFolder
    The path to the folder containing the source images.
    
    .PARAMETER destinationFolder
    The path to the folder where the converted images and thumbnails will be saved.
    
    .EXAMPLE
    Convert-ImageForTeams -sourceFolder "C:\Path\To\Source\Images" -destinationFolder "C:\Path\To\Destination"
    #>
    param (
        [string]$sourceFolder,
        [string]$destinationFolder
    )

    # Install the necessary .NET namespace
    Add-Type -AssemblyName System.Drawing

    # Dummy function to satisfy the GetThumbnailImage method
    function dummyCallback { return $false }

    # Loop through each image file in the source folder
    Get-ChildItem -Path $sourceFolder -File | ForEach-Object {

        # Generate a GUID for the new image name
        $guid = [guid]::NewGuid().ToString()

        # Create a .NET Bitmap object from the image file
        $originalImage = [System.Drawing.Image]::FromFile($_.FullName)

        # Save the image as a PNG with a GUID-based name
        $originalImage.Save("$destinationFolder\$guid.png", [System.Drawing.Imaging.ImageFormat]::Png)

        # Create a thumbnail image
        $thumbWidth = 278
        $thumbHeight = 159
        $thumbnailImage = $originalImage.GetThumbnailImage($thumbWidth, $thumbHeight, [System.Drawing.Image+GetThumbnailImageAbort]$dummyCallback, [System.IntPtr]::Zero)

        # Save the thumbnail image as a PNG with a GUID-based name and "_thumb" suffix
        $thumbnailImage.Save("$destinationFolder\$guid`_thumb.png", [System.Drawing.Imaging.ImageFormat]::Png)

        # Dispose of the image objects to free resources
        $originalImage.Dispose()
        $thumbnailImage.Dispose()
    }
}

function Expand-NinjaOneZip {
    <#
    .SYNOPSIS
        Extracts the contents of a NinjaOne Zip file to a specified destination folder.
    .DESCRIPTION
        The Expand-NinjaOneZip function extracts the contents of a NinjaOne Zip file to a specified destination folder.
    .PARAMETER ZipFile
        Specifies the path to the NinjaOne Zip file to extract.
    .PARAMETER Destination
        Specifies the path to the destination folder where the contents of the Zip file will be extracted.
    .EXAMPLE
        Expand-NinjaOneZip -ZipFile "C:\Temp\NinjaOne.zip" -Destination "C:\Temp\Extracted"
        This example extracts the contents of the "NinjaOne.zip" file located in "C:\Temp" to the "C:\Temp\Extracted" folder.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
        [string]$ZipFile,
        [Parameter(Mandatory = $true)]
        [ValidateScript({ Test-Path -Path $_ -PathType Container })]
        [string]$Destination
    )

    # Import the Microsoft.PowerShell.Archive module
    Import-Module -Name Microsoft.PowerShell.Archive

    try {
        # Unzip the NinjaOne Zip file
        Expand-Archive -Path $ZipFile -DestinationPath $Destination -ErrorAction Stop
    }
    catch {
        Write-Error "Failed to unzip file: $_"
    }
}

function Get-TeamsFolderStructure {
    <#
    .SYNOPSIS
        Gets the folder structure for Microsoft Teams backgrounds.
    
    .DESCRIPTION
        This function retrieves the folder structure for Microsoft Teams backgrounds. It determines whether the old or new folder structure is being used and returns the appropriate base path and upload path.
    
    .OUTPUTS
        Returns a hashtable with the following keys:
        - "Structure": Indicates whether the old or new folder structure is being used.
        - "BasePath": The base path for the Microsoft Teams backgrounds.
        - "UploadPath": The upload path for the Microsoft Teams backgrounds.
    
    .EXAMPLE
        PS C:\> Get-TeamsFolderStructure
        Returns a hashtable with the folder structure for Microsoft Teams backgrounds.
    
    .NOTES
        Author: Unknown
        Last Edit: Unknown
    #>
    $TeamsBackgroundBasePath = $env:APPDATA + "\Microsoft\Teams\Backgrounds\"
    $TeamsBackgroundUploadPath = $TeamsBackgroundBasePath + "Uploads\"

    $NewTeamsBackgroundBasePath = $env:LOCALAPPDATA + "\Packages\MSTeams_8wekyb3d8bbwe\LocalCache\Microsoft\MSTeams\Backgrounds\"
    $NewTeamsBackgroundUploadPath = $NewTeamsBackgroundBasePath + "Uploads\"

    $TeamsFolderStructure = @{
        "Structure"  = "Old";
        "BasePath"   = $TeamsBackgroundBasePath;
        "UploadPath" = $TeamsBackgroundUploadPath;
    }

    if (Test-Path $NewTeamsBackgroundUploadPath) {
        $TeamsFolderStructure["Structure"] = "New"
        $TeamsFolderStructure["BasePath"] = $NewTeamsBackgroundBasePath
        $TeamsFolderStructure["UploadPath"] = $NewTeamsBackgroundUploadPath
    }

    return $TeamsFolderStructure
}

function Get-UserTeamsVersion {
    <#
    .SYNOPSIS
        This function retrieves the version of Microsoft Teams installed for the current user.
    .DESCRIPTION
        The function checks if Microsoft Teams is installed for the current user and retrieves its version if it is.
        If Microsoft Teams is not installed for the current user, the function returns a message indicating so.
    .EXAMPLE
        PS C:\> Get-UserTeamsVersion
        1.3.00.30866
    #>
    $TeamsExePath = "$env:LOCALAPPDATA\Microsoft\Teams\current\Teams.exe"
    if (Test-Path -Path $TeamsExePath) {
        $TeamsVersionInfo = Get-ItemProperty -Path $TeamsExePath
        return $TeamsVersionInfo.VersionInfo.ProductVersion
    }
    else {
        return "Teams not installed for this user"
    }
}

function Get-MachineTeamsVersion {
    <#
    .SYNOPSIS
        Gets the version of Microsoft Teams installed on a machine-wide basis.
    .DESCRIPTION
        This function retrieves the version of Microsoft Teams installed on a machine-wide basis by checking the registry key for Teams in the Uninstall subkey of HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion.
        If Teams is installed, the function returns the version number. Otherwise, it returns a message indicating that Teams is not installed on a machine-wide basis.
    .EXAMPLE
        PS C:\> Get-MachineTeamsVersion
        1.3.00.13565
    #>
    $TeamsVersionPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
    $TeamsVersionKey = Get-ItemProperty -Path $TeamsVersionPath | Where-Object { $_.DisplayName -like "Teams*" }

    if ($null -ne $TeamsVersionKey) {
        return $TeamsVersionKey.DisplayVersion
    }
    else {
        return "Teams not installed on a machine-wide basis"
    }
}

function Get-LatestTeamsVersion {
    <#
    .SYNOPSIS
        This function retrieves the latest version of Microsoft Teams from the Microsoft website.
    
    .DESCRIPTION
        The Get-LatestTeamsVersion function uses Invoke-WebRequest to retrieve the content of the Microsoft Teams download page.
        It then extracts the version number of the latest Windows x64 executable using a regular expression pattern.
        The function returns the latest version number as a string.
    
    .EXAMPLE
        PS C:\> Get-LatestTeamsVersion
        1.4.00.7556
    
    .NOTES
        Author: GitHub Copilot
    #>
    $url = "https://teams.microsoft.com/downloads"
    $webpage = Invoke-WebRequest -Uri $url
    $versionPattern = 'teams_windows_x64-(.*?).exe'
    $latestVersion = $webpage.Content | Select-String -Pattern $versionPattern -AllMatches | 
    ForEach-Object { $_.Matches } | 
    ForEach-Object { $_.Groups[1].Value } | 
    Sort-Object Version -Descending | 
    Select-Object -First 1
    return $latestVersion
}

function Get-TeamsInstallType {
    <#
    .SYNOPSIS
        Gets the installation type, version, and whether it is the latest version of Microsoft Teams.
    
    .DESCRIPTION
        This function gets the installation type (machine-wide or per-user), version, and whether it is the latest version of Microsoft Teams.
    
    .PARAMETER None
        This function does not accept any parameters.
    
    .EXAMPLE
        PS C:\> Get-TeamsInstallType
        Returns an object with the following properties:
            InstallType: Machine-wide or Per-user or Not installed
            Version: The version of Microsoft Teams installed
            IsLatest: True if the installed version is the latest version, False otherwise.
    
    .NOTES
        Author: GitHub Copilot
    #>
    $machineVersion = Get-MachineTeamsVersion
    $userVersion = Get-UserTeamsVersion
    $latestVersion = Get-LatestTeamsVersion
    $installType = $null
    $version = $null
    $isLatest = $false

    if ($machineVersion -ne "Teams not installed on a machine-wide basis") {
        $installType = "Machine-wide"
        $version = $machineVersion
    }
    elseif ($userVersion -ne "Teams not installed for this user") {
        $installType = "Per-user"
        $version = $userVersion
    }
    else {
        $installType = "Not installed"
    }

    if ($version -eq $latestVersion) {
        $isLatest = $true
    }

    # Create a custom PSObject
    $result = New-Object PSObject
    $result | Add-Member -MemberType NoteProperty -Name "InstallType" -Value $installType
    $result | Add-Member -MemberType NoteProperty -Name "Version" -Value $version
    $result | Add-Member -MemberType NoteProperty -Name "IsLatest" -Value $isLatest

    return $result
}

function Initialize-EventLogging {
    <#
    .SYNOPSIS
        Initializes event logging by creating a new event log source if it does not exist.
    
    .PARAMETER logName
        Specifies the name of the event log. The default value is "NinjaOneDeployments".
        Valid values are "Application", "System", "NinjaOneDeployments", and "AutomatedDeployment".
    
    .PARAMETER source
        Specifies the name of the event log source. The default value is "NinjaOneScripts".
        Valid values are "NinjaOneScripts" and "AutomatedDeployment".
    
    .NOTES
        Author: Unknown
        Last Edit: Unknown
    #>
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("Application", "System", "NinjaOneDeployments", "AutomatedDeployment")]
        [string]$logName = "NinjaOneDeployments",

        [Parameter(Mandatory = $false)]
        [ValidateSet("NinjaOneScripts", "AutomatedDeployment")]
        [string]$source = "NinjaOneScripts"
    )

    if (![string]::IsNullOrWhiteSpace($logName) -and ![string]::IsNullOrWhiteSpace($source)) {
        try {
            # Create the source if it does not exist
            if (![System.Diagnostics.EventLog]::SourceExists($source)) {
                $Message = "Initialize-EventLogging @ " + (Get-Date) + ": Creating LogSource for EventLog..."
                Write-Verbose $message
                [System.Diagnostics.EventLog]::CreateEventSource($source, $logName)
            }
            else {
                $Message = "Initialize-EventLogging @ " + (Get-Date) + ": LogSource exists already."
                Write-Verbose $message
            }
        }
        catch {
            Write-Error "An error occurred while initializing logging: $_"
        }
    }
    else {
        Write-Error "Invalid parameters. LogName and Source cannot be empty."
    }
}

Function Initialize-TeamsLocalUploadFolder {
    <#
    .SYNOPSIS
        Initializes the local upload folder for Microsoft Teams backgrounds.
    
    .DESCRIPTION
        This function checks if the local upload folder for Microsoft Teams backgrounds exists and creates it if it doesn't. 
        It also checks if the local folder for new Teams exists and sets a flag accordingly.
    
    .PARAMETER IncludeNewTeams
        Specifies whether to include the local folder for new Teams in the check. Default is $false.
    
    .EXAMPLE
        Initialize-TeamsLocalUploadFolder -IncludeNewTeams $true
    
    .NOTES
        Author: Unknown
        Last Edit: Unknown
    #>
    param (
        [Parameter(Mandatory = $false)] [boolean]$IncludeNewTeams
    )

    $TeamsBackgroundBasePath = $env:APPDATA + "\Microsoft\Teams\Backgrounds\"
    $TeamsBackgroundUploadPath = $TeamsBackgroundBasePath + "\Uploads\"

    If (!(Test-Path $TeamsBackgroundUploadPath)) {
        $Message = "Initialize-TeamsLocalUploadFolder  @ " + (Get-Date) + ": Local AppData\Microsoft\Teams\Backgrounds\ folder does not exist. Trying to create it..."
        New-LogEvent -message $Message
        try {
            New-Item -ItemType Directory -Path $TeamsBackgroundBasePath -Name "Uploads"
            $Message = "Initialize-TeamsLocalUploadFolder  @ " + (Get-Date) + ": Successfully created Uploads folder in AppData\Microsoft\Teams\Backgrounds\."
            New-LogEvent -message $Message

            $teamsLocalUploadFolderExists = $true
        }
        catch {
            $Message = "Initialize-TeamsLocalUploadFolder @ " + (Get-Date) + ": ERROR trying to create local Upload Folder: " + $_.Exception.Message
            New-LogEvent -message $message
            $teamsLocalUploadFolderExists = $false
        }
    }
    else {
        $teamsLocalUploadFolderExists = $true 
    }
    if ($IncludeNewTeams -eq $true) {
        $NewTeamsBackgroundBasePath = $env:LOCALAPPDATA + "\Packages\MSTeams_8wekyb3d8bbwe\LocalCache\Microsoft\MSTeams\Backgrounds\"
        $NewTeamsBackgroundUploadPath = $NewTeamsBackgroundBasePath + "\Uploads\"
        If (!(Test-Path $NewTeamsBackgroundUploadPath)) {
            $Message = "Initialize-TeamsLocalUploadFolder  @ " + (Get-Date) + ": Local folder for new Teams does not exist. Indicates New Teams is not present on this system."
            New-LogEvent -message $Message
            $NewTeamsLocalUploadFolderExists = $false
        }
        else {
            $NewTeamsLocalUploadFolderExists = $true
        }
    }
    return $NewTeamsLocalUploadFolderExists
}

Function New-LogEvent {
    <#
    .SYNOPSIS
    A function to log events.

    .DESCRIPTION
    This function writes an event to the event log.

    .PARAMETER logName
    The name of the log where the event will be written. Default is "NinjaOneDeployments".

    .PARAMETER source
    The source of the event. Default is "NinjaOneScripts".

    .PARAMETER entryType
    The type of the event. Must be one of "Error", "Warning", "Information", "SuccessAudit", "FailureAudit". Default is "Information".

    .PARAMETER eventId
    The ID of the event. Default is 1847.

    .PARAMETER message
    The message of the event. This parameter is mandatory.

    .EXAMPLE
    New-LogEvent -message "This is a test event."
    #>
    param (
        [Parameter(Mandatory = $false)]
        [string]$logName = "NinjaOneDeployments",

        [Parameter(Mandatory = $false)]
        [string]$source = "NinjaOneScripts",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Error", "Warning", "Information", "SuccessAudit", "FailureAudit")]
        [string]$entryType = "Information",
        
        [Parameter(Mandatory = $false)]
        [int]$eventId = 1847,
        
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$message
    )

    try {
        Write-EventLog -LogName $logName -Source $source -EntryType $entryType -EventId $eventId -Message $message
    }
    catch {
        Write-Error "Failed to write to event log: $_"
    }
}

# Set the path to the NinjaOne Zip file and the temporary folder
$directoryPath = 'C:\Temp\Team-backgrounds\'
if (-not (Test-Path $directoryPath)) {
    New-Item -ItemType Directory -Path $directoryPath
}
$ZipFile = "C:\Temp\Team-backgrounds.zip"
$TempFolder = "C:\Temp\Team-backgrounds\"

# Initialize event logging
Initialize-EventLogging -logName "NinjaOneDeployments" -source "NinjaOneScripts"

# Log the paths to the event log with more details
$Message = "The path to the NinjaOne Zip file is set to: " + $ZipFile
New-LogEvent -message $Message
$Message = "The path to the temporary folder for image processing is set to: " + $TempFolder
New-LogEvent -message $Message

# Get the folder structure for Teams backgrounds and log to the event log with more details
$TeamsFolderStructure = Get-TeamsFolderStructure
$Message = "The folder structure for Teams backgrounds is identified as: " + $TeamsFolderStructure["Structure"]
New-LogEvent -message $Message

# Get the Teams installation type and log to the event log with more details
$TeamsInstallType = Get-TeamsInstallType
$Message = "The installation type for Microsoft Teams on this machine is: " + $TeamsInstallType.InstallType
New-LogEvent -message $Message

# Retrieve the current version of Teams and log to the event log with more details
$TeamsVersion = $TeamsInstallType.Version
$Message = "The current version of Microsoft Teams installed on this machine is: " + $TeamsVersion
New-LogEvent -message $Message

# Expand the NinjaOne Zip file to a temporary folder and log details to the event log. A list of the files in the Zip file will be collected and logged in one event log entry.
Expand-NinjaOneZip -ZipFile $ZipFile -Destination $TempFolder
$Message = "The NinjaOne Zip file has been successfully expanded to the temporary folder."
New-LogEvent -message $Message
$Message = "The files extracted from the NinjaOne Zip file are: " + (Get-ChildItem -Path $ZipFile -File).Name -join ', '
New-LogEvent -message $Message

# Convert the images in the temporary folder to PNG format and create thumbnail images. Log details to the event log and collect a list of the converted images and thumbnails to log in one event log entry.
Convert-ImageForTeams -sourceFolder $TempFolder -destinationFolder $TempFolder
$Message = "All images in the temporary folder have been converted to PNG format and thumbnail images have been created."
New-LogEvent -message $Message
$Message = "The converted images and thumbnails are: " + (Get-ChildItem -Path $TempFolder -File).Name -join ', '
New-LogEvent -message $Message
