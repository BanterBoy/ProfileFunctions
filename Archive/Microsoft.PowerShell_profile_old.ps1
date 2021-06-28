#--------------------
# Generic Profile Commands
#--------------------
function Get-GoogleSearch {
    Start-Process "https://www.google.co.uk/search?q=$args"
}

function Get-GoogleDirections {
    param([string] $From, [String] $To)

    process {
        Start-Process "https://www.google.com/maps/dir/$From/$To/"
    }
}

function Get-DuckDuckGoSearch {
    Start-Process "https://duckduckgo.com/?q=$args"
}

function Add-Office365Functions {
    $Modules = "AADRM", "AzureAD", "AzureADPreview", "Microsoft.Online.SharePoint.PowerShell", "MicrosoftTeams", "MSOnline", "SharePointPnPPowerShellOnline", "ActiveDirectory"
    foreach ($Module in $Modules) { 
        Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
        if ( Get-Module -Name $Module ) {
            Import-Module -Name $Module
            Write-Warning "Module Import - Imported $Module"
        }
        else {
            Write-Warning "Installing $Module"
            $execpol = Get-ExecutionPolicy -List
            if ( $execpol -ne 'Unrestricted' ) {
                Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser
            }
            Install-Module -Name $Module -Scope AllUsers -AllowClobber
        }
        Set-PSRepository -Name PSGallery -InstallationPolicy Untrusted
    }
    & (Join-Path $PSScriptRoot "\Connect-Office365Services.ps1")
}

function Test-IsAdmin {
    <#
.Synopsis
Tests if the user is an administrator
.Description
Returns true if a user is an administrator, false if the user is not an administrator
.Example
Test-IsAdmin
#>
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal $identity
    $principal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

function Show-IsAdminOrNot {
    $IsAdmin = Test-IsAdmin
    if ( $IsAdmin -eq "False") {
        Write-Warning -Message "Admin Privileges!"
    }
    else {
        Write-Warning -Message "User Privileges"
    }
}

function New-AdminShell {
    <#
	.Synopsis
	Starts an Elevated PowerShell Console.

	.Description
	Opens a new PowerShell Console Elevated as Administrator. If the user is already running an elevated
	administrator shell, a message is displayed in the console session.

	.Example
	New-AdminShell

	#>

    $Process = Get-Process | Where-Object { $_.Id -eq "$($PID)" }
    if (Test-IsAdmin = $True) {
        Write-Warning -Message "Admin Shell already running!"
    }
    else {
        if ($Process.Name -eq "PowerShell") {
            Start-Process -FilePath "PowerShell.exe" -Verb runas -PassThru
        }
        if ($Process.Name -eq "pwsh") {
            Start-Process -FilePath "pwsh.exe" -Verb runas -PassThru
        }
    }
}

function New-AdminTerminal {
    <#
	.Synopsis
	Starts an Elevated Microsoft Terminal.

	.Description
	Opens a new Microsoft Terminal Elevated as Administrator. If the user is already running an elevated
	Microsoft Terminal, a message is displayed in the console session.

	.Example
	New-AdminShell

	#>

    if (Test-IsAdmin = $True) {
        Write-Warning -Message "Admin Shell already running!"
    }
    else {
        Start-Process "wt.exe" -ArgumentList "-p pwsh" -Verb runas -PassThru
    }
}


function Format-Console {
    param (
        [int]$WindowHeight,
        [int]$WindowWidth,
        [int]$BufferHeight,
        [int]$BufferWidth
    )
    [System.Console]::SetWindowSize($WindowWidth, $WindowHeight)
    [System.Console]::SetBufferSize($BufferWidth, $BufferHeight)
}


function Get-ContainedCommand {
    param
    (
        [Parameter(Mandatory)][string]
        $Path,

        [string][ValidateSet('FunctionDefinition', 'Command' )]
        $ItemType
    )

    $Token = $Err = $null
    $ast = [Management.Automation.Language.Parser]::ParseFile( $Path, [ref] $Token, [ref] $Err)

    $ast.FindAll( { $args[0].GetType(). Name -eq "${ItemType}Ast" }, $true )

}

function New-Password {
    <# Example

	.EXAMPLE
	Save-Password -Label UserName

	.EXAMPLE
	Save-Password -Label Password

	#>
    param([Parameter(Mandatory)]
        [string]$Label)
    $securePassword = Read-host -Prompt 'Input password' -AsSecureString | ConvertFrom-SecureString
    $directoryPath = Select-FolderLocation
    if (![string]::IsNullOrEmpty($directoryPath)) {
        Write-Host "You selected the directory: $directoryPath"
    }
    else {
        "You did not select a directory."
    }
    $securePassword | Out-File -FilePath "$directoryPath\$Label.txt"
}

function Get-Password {
    <#
	.EXAMPLE
	$user = Get-Password -Label UserName
	$pass = Get-Password -Label password

	.OUTPUTS
	$user | Format-List

	.OUTPUTS
	Label           : UserName
	EncryptedString : domain\administrator

	.OUTPUTS
	$pass | Format-List
	Label           : password
	EncryptedString : SomeSecretPassword

	.OUTPUTS
	$user.EncryptedString
	domain\administrator

	.OUTPUTS
	$pass.EncryptedString
	SomeSecretPassword

	#>
    param([Parameter(Mandatory)]
        [string]$Label)
    $directoryPath = Select-FolderLocation
    if (![string]::IsNullOrEmpty($directoryPath)) {
        Write-Host "You selected the directory: $directoryPath"
    }
    $filePath = "$directoryPath\$Label.txt"
    if (-not (Test-Path -Path $filePath)) {
        throw "The password with Label [$($Label)] was not found!"
    }
    $password = Get-Content -Path $filePath | ConvertTo-SecureString
    $decPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))
    [pscustomobject]@{
        Label           = $Label
        EncryptedString = $decPassword
    }
}

function Restart-Profile {
    @(
        $Profile.AllUsersAllHosts,
        $Profile.AllUsersCurrentHost,
        $Profile.CurrentUserAllHosts,
        $Profile.CurrentUserCurrentHost
    ) |
    ForEach-Object {
        if (Test-Path $_) {
            Write-Verbose "Running $_"
            . $_
        }
    }
}

function New-GitDrives {
    $PSRootFolder = Select-FolderLocation
    $Exist = Test-Path -Path $PSRootFolder
    if (($Exist) = $true) {
        $PSDrivePaths = Get-ChildItem -Path "$PSRootFolder\"
        foreach ($item in $PSDrivePaths) {
            $paths = Test-Path -Path $item.FullName
            if (($paths) = $true) {
                New-PSDrive -Name $item.Name -PSProvider "FileSystem" -Root $item.FullName
            }
        }
    }
}

function New-Greeting {
    $Today = $(Get-Date)
    Write-Host "   Day of Week  -"$Today.DayOfWeek " - Today's Date -"$Today.ToShortDateString() "- Current Time -"$Today.ToShortTimeString()
    Switch ($Today.dayofweek) {
        Monday { Write-host "   Don't want to work today" }
        Friday { Write-host "   Almost the weekend" }
        Saturday { Write-host "   Everyone loves a Saturday ;-)" }
        Sunday { Write-host "   A good day to rest, or so I hear." }
        Default { Write-host "   Business as usual." }
    }
}

function Update-PowerShell {
    Invoke-Expression "& { $(Invoke-RestMethod https://aka.ms/install-powershell.ps1) } -UseMSI"
}

function New-ObjectToHashTable {
    param([
        Parameter(Mandatory , ValueFromPipeline)]
        $object)
    process	{
        $object |
        Get-Member -MemberType *Property |
        Select-Object -ExpandProperty Name |
        Sort-Object |
        ForEach-Object { [PSCustomObject ]@{
                Item  = $_
                Value = $object. $_
            }
        }
    }
}

function New-PSDrives {
    $PSRootFolder = Select-FolderLocation
    $PSDrivePaths = Get-ChildItem -Path "$PSRootFolder\"
    foreach ($item in $PSDrivePaths) {
        $paths = Test-Path -Path $item.FullName
        if (($paths) = $true) {
            New-PSDrive -Name $item.Name -PSProvider "FileSystem" -Root $item.FullName
        }
    }
}

function Select-FolderLocation {
    <#
        Example.
        $directoryPath = Select-FolderLocation
        if (![string]::IsNullOrEmpty($directoryPath)) {
            Write-Host "You selected the directory: $directoryPath"
        }
        else {
            "You did not select a directory."
        }
    #>
    [Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
    [System.Windows.Forms.Application]::EnableVisualStyles()
    $browse = New-Object System.Windows.Forms.FolderBrowserDialog
    $browse.SelectedPath = "C:\"
    $browse.ShowNewFolderButton = $true
    $browse.Description = "Select a directory for your report"
    $loop = $true
    while ($loop) {
        if ($browse.ShowDialog() -eq "OK") {
            $loop = $false
        }
        else {
            $res = [System.Windows.Forms.MessageBox]::Show("You clicked Cancel. Would you like to try again or exit?", "Select a location", [System.Windows.Forms.MessageBoxButtons]::RetryCancel)
            if ($res -eq "Cancel") {
                #Ends script
                return
            }
        }
    }
    $browse.SelectedPath
    $browse.Dispose()
}

function Show-ProfileFunctions {
    $Path = Join-Path $PSScriptRoot "/Microsoft.PowerShell_profile.ps1"
    $functionNames = Get-ContainedCommand $Path -ItemType FunctionDefinition |	Select-Object -ExpandProperty Name
    $functionNames | Sort-Object
}

function Show-PSDrive {
    Get-PSDrive | Format-Table -AutoSize
}

function Stop-Outlook {
    $OutlookRunning = Get-Process -ProcessName "Outlook"
    if (($OutlookRunning) = $true) {
        Stop-Process -ProcessName Outlook
    }
}

function PadOrTruncate([string]$s, [int]$length) {
    if ($s.length -le $length) {
        return $s.PadRight($length, " ")
    }

    $truncated = $s.Substring(0, ($length - 3))

    return "$truncated..."
}

function Get-FriendlySize {
    param($Bytes)
    $sizes = 'Bytes,KB,MB,GB,TB,PB,EB,ZB' -split ','
    for ($i = 0; ($Bytes -ge 1kb) -and
        ($i -lt $sizes.Count); $i++) { $Bytes /= 1kb }
    $N = 2; if ($i -eq 0) { $N = 0 }
    "{0:N$($N)} {1}" -f $Bytes, $sizes[$i]
}

function Get-DownloadPercent([decimal]$d) {
    $p = [math]::Round($d * 100)
    return "$p%"
}

function Save-PasswordFile {
    <# Example

	.EXAMPLE
	Save-Password -Label UserName

	.EXAMPLE
	Save-Password -Label Password

	#>
    param(
        [Parameter(Mandatory = $true,
            HelpMessage = "Enter password label")]
        [string]$Label,

        [Parameter(Mandatory = $false,
            HelpMessage = "Enter file path.")]
        [ValidateSet('Profile', 'Select') ]
        [string]$Path
    )

    switch ($Path) {
        Profile {
            $ProfilePath = ($PROFILE).Split('\Microsoft.PowerShell_profile.ps1')[0]
            $filePath = "$ProfilePath" + "\$Label.txt"
            $securePassword = Read-host -Prompt 'Input password' -AsSecureString | ConvertFrom-SecureString
            $securePassword | Out-File -FilePath "$filePath"
        }
        Select {
            $directoryPath = Select-FolderLocation
            $securePassword = Read-host -Prompt 'Input password' -AsSecureString | ConvertFrom-SecureString
            $securePassword | Out-File -FilePath "$directoryPath\$Label.txt"
        
        }
        Default {
            $ProfilePath = ($PROFILE).Split('\Microsoft.PowerShell_profile.ps1')[0]
            $filePath = "$ProfilePath" + "\$Label.txt"
            $securePassword = Read-host -Prompt 'Input password' -AsSecureString | ConvertFrom-SecureString
            $securePassword | Out-File -FilePath "$filePath"
        }
    }
}


#--------------------
# Menu - KeyPresses
#--------------------
# Add required assemblies
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName PresentationCore
 
#--------------------
# Pause to be able to press and hold a key
Start-Sleep -Seconds 2

#--------------------
# Key list
$Nokey = [System.Windows.Input.Key]::None
$key1 = [System.Windows.Input.Key]::LeftCtrl
$key2 = [System.Windows.Input.Key]::LeftShift

#--------------------
# Key presses
$isCtrl = [System.Windows.Input.Keyboard]::IsKeyDown($key1)
$isShift = [System.Windows.Input.Keyboard]::IsKeyDown($key2)

# If no key is pressed, launch User Home Profile
if ($Nokey -eq 'None') {
    Write-Warning -Message "No key has been pressed - User Home Profile"
    
    function Get-GistIframe {
        <#
            .DESCRIPTION
            Generate iframe code for blog.lukeleigh.com from a gist script
    
            .PARAMETER Url
            Mandatory. The gist URL to encode. Can be sent through the pipeline.
            
            .PARAMETER Height
            Optional, defaults to 500. The number of pixels that will be set as the height of the iframe.
            
            .PARAMETER Revert
            Optional. Decodes a previously generated URL.
            
            .EXAMPLE
            "<script src=`"https://gist.github.com/BanterBoy/65b11469a46757727ef929f3925668a6.js`"></script>" | Get-GistIframe
            
            .EXAMPLE
            Get-GistIframe -Url "<script src=`"https://gist.github.com/BanterBoy/65b11469a46757727ef929f3925668a6.js`"></script>" -Height 750
            
            .EXAMPLE
            Get-GistIframe -Url "%3Cscript%20src%3D%22https%3A%2F%2Fgist.github.com%2FBanterBoy%2F65b11469a46757727ef929f3925668a6.js%22%3E%3C%2Fscript%3E" -Revert
            #>
    
        param (
            [Parameter(Mandatory = $true, HelpMessage = "Gist js URL", ValueFromPipeline = $true)]
            [string]$Url,
    
            [Parameter(Mandatory = $false, HelpMessage = "iframe height in pixels, defaults to 500")]
            [int]$Height = 500,
    
            [Parameter(Mandatory = $false, HelpMessage = "Decodes a previously encoded URL")]
            [switch]$Revert
        )
    
        [string]$response = ""
    
        if ($Revert.IsPresent) {
            $response = [System.Web.HttpUtility]::UrlDecode($Url)
        }
        else {
            $response = "<iframe src=`"data:text/html;charset=utf-8,$([System.Web.HttpUtility]::UrlEncode($Url))`" style=`"
            margin: 0;
            padding: 0;
            width: 100%;
            height: $($Height)px;
            -moz-border-radius: 12px;
            -webkit-border-radius: 12px;
            border-radius: 12px;
            background-color: white;
            overflow: scroll;
        `"></iframe>"
        }
    
        $response | Set-Clipboard
    
        if ($Revert.IsPresent) {
            Write-Host "The following decoded URL has been copied to the clipboard:"
        }
        else {
            Write-Host "The following generated iframe code has been copied to the clipboard:"
        }
            
        Write-Host $response
    }
        
    function Start-Blogging {
        if (Test-IsAdmin = $True) {
            New-BlogServer
        }
        else {
            Write-Warning -message "Starting Admin Shell"
            Start-Process -FilePath "pwsh.exe" -Verb runas -PassThru
        }
    }

    function New-BlogServer {

        [CmdletBinding(DefaultParameterSetName = 'default')]

        param(
            [Parameter(Mandatory = $True,
                ValueFromPipeline = $True,
                HelpMessage = "Enter path or Browse to select dockerfile")]
            [ValidateSet('Select', 'Blog')]
            [string]$BlogPath,
            [string]$Path

        )

        switch ($BlogPath) {
        
            Select {
                try {
                    $PSRootFolder = Select-FolderLocation
                    New-PSDrive -Name BlogDrive -PSProvider "FileSystem" -Root $PSRootFolder
                    Set-Location -Path BlogDrive:
                    docker-compose.exe up
                }
                catch [System.Management.Automation.ItemNotFoundException] {
                    Write-Warning -Message "$_"
                }
            }

            Blog {
                try {
                    New-PSDrive -Name BlogDrive -PSProvider "FileSystem" -Root "$Path"
                    Set-Location -Path BlogDrive:
                    docker-compose.exe up
                }
                catch [System.Management.Automation.ItemNotFoundException] {
                    Write-Warning -Message "$_"
                }
            }
            Default {
                try {
                    $PSRootFolder = Select-FolderLocation
                    New-PSDrive -Name BlogDrive -PSProvider "FileSystem" -Root $PSRootFolder
                    Set-Location -Path BlogDrive:
                    docker-compose.exe up
                }
                catch [System.Management.Automation.ItemNotFoundException] {
                    Write-Warning -Message "$_"
                }
            }
        }
    }

    function New-BlogSession {
        $PSRootFolder = Select-FolderLocation
        New-PSDrive -Name BlogDrive -PSProvider "FileSystem" -Root $PSRootFolder
        code ($PSRootFolder) -n
    }

    function Show-LocalBlogSite {
        $ComputerDNSName = $env:COMPUTERNAME + '.' + (Get-NetIPConfiguration).NetProfile.Name
        $URL = "http://" + $ComputerDNSName + ":4000"
        Start-Process $URL
    }

    function Get-DockerStatsSnapshot {
        $running = docker images -q
        if ($null -eq $running) {
            Write-Warning -Message "No Docker Containers are running"
        }
        else {
            docker container stats --no-stream
        }
    }

    function Remove-BlogServer {
        $title = 'Clean Blog Environment'
        $question = 'Are you sure you want to proceed?'
        $choices = '&Yes', '&No'
        $decision = $Host.UI.PromptForChoice($title, $question, $choices, 1)
        if ($decision -eq 0) {
            $PSRootFolder = Select-FolderLocation
            New-PSDrive -Name BlogDrive -PSProvider "FileSystem" -Root $PSRootFolder
            Set-Location -Path BlogDrive:
            Write-Host 'Cleaning Environment - Removing Images'
            $images = docker images -q
            foreach ($image in $images) {
                docker rmi $image -f
                docker rm $(docker ps -a -f status=exited -q)
            }
            $vendor = Test-Path $PSRootFolder\vendor
            $site = Test-Path $PSRootFolder\_site
            $gemfile = Test-Path -Path $psrootfolder\gemfile.lock
            $jekyllmetadata = Test-Path -Path $psrootfolder\.jekyll-metadata
            Write-Warning -Message 'Cleaning Environment - Removing Vendor Bundle'
            if ($vendor = $true) {
                try {
                    Remove-Item -Path $PSRootFolder\vendor -Recurse -Force -ErrorAction Stop
                    Write-Verbose -Message 'Vendor Bundle removed.' -Verbose
                }
                catch [System.Management.Automation.ItemNotFoundException] {
                    Write-Verbose -Message 'Vendor Bundle does not exist.' -Verbose
                }
            }
            Write-Warning -Message 'Cleaning Environment - Removing _site Folder'
            if ($site = $true) {
                try {
                    Remove-Item -Path $psrootfolder\_site -Recurse -Force -ErrorAction Stop
                    Write-Verbose -Message '_site folder removed.' -Verbose
                }
                catch [System.Management.Automation.ItemNotFoundException] {
                    Write-Verbose -Message '_site folder does not exist.' -Verbose
                }
            }
            Write-Warning -Message 'Cleaning Environment - Removing Gemfile.lock File'
            if ($gemfile = $true) {
                try {
                    Remove-Item -Path $psrootfolder\gemfile.lock -Force -ErrorAction Stop
                    Write-Verbose -Message 'gemfile.lock removed.' -Verbose
                }
                catch [System.Management.Automation.ItemNotFoundException] {
                    Write-Verbose -Message 'gemfile.lock does not exist.' -Verbose
                }
            }
            Write-Warning -Message 'Cleaning Environment - Removing .jekyll-metadata File'
            if ($jekyllmetadata = $true) {
                try {
                    Remove-Item -Path $psrootfolder\.jekyll-metadata -Force -ErrorAction Stop
                    Write-Verbose -Message '.jekyll-metadata removed.' -Verbose
                }
                catch [System.Management.Automation.ItemNotFoundException] {
                    Write-Verbose -Message '.jekyll-metadata does not exist.' -Verbose
	
                }
                Set-Location -Path D:\GitRepos
            }
        }
        else {
            Write-Warning -Message 'Images left intact.'
        }
    }


}

# If LeftCtrl key is pressed, launch User Work Profile
elseif ($isCtrl) {
    Write-Warning -Message "LeftCtrl key has been pressed - User Work Profile"

    function Get-PatchTue {
        <#
	.SYNOPSIS
	Get the Patch Tuesday of a month
	.PARAMETER month
	The month to check
	.PARAMETER year
	The year to check
	.EXAMPLE
	Get-PatchTue -month 6 -year 2015
	.EXAMPLE
	Get-PatchTue June 2015
	#>
        param(
            [string]$month = (get-date).month,
            [string]$year = (get-date).year)
        $firstdayofmonth = [datetime] ([string]$month + "/1/" + [string]$year)
        (0..30 | ForEach-Object {
                $firstdayofmonth.adddays($_)
            } |
            Where-Object {
                $_.dayofweek -like "Tue*"
            })[1]
    }

    

}

# If LeftShift key is pressed, start PowerShell without a Profile
elseif ($isShift) {
    Write-Warning -Message "LeftShift key has been pressed - PowerShell without a Profile"

    Start-Process "pwsh.exe" -ArgumentList "-NoNewWindow -noprofile"

}


#--------------------
# Profile Start
#--------------------
# Set-ExecutionPolicy
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process -Force

#--------------------
# Display running as Administrator in WindowTitle
$whoami = whoami /Groups /FO CSV | ConvertFrom-Csv -Delimiter ','
$MSAccount = $whoami."Group Name" | Where-Object { $_ -like 'MicrosoftAccount*' }
$LocalAccount = $whoami."Group Name" | Where-Object { $_ -like 'Local' }
if ((Test-IsAdmin) -eq $true) {
    if (($MSAccount)) {
        $host.UI.RawUI.WindowTitle = "$($MSAccount.Split('\')[1]) - Admin Privileges"
    }
    else {
        $host.UI.RawUI.WindowTitle = "$($LocalAccount) - Admin Privileges"
    }
}	
else {
    if (($LocalAccount)) {
        $host.UI.RawUI.WindowTitle = "$($MSAccount.Split('\')[1]) - User Privileges"
    }
    else {
        $host.UI.RawUI.WindowTitle = "$($LocalAccount) - User Privileges"
    }
}	

#--------------------
# Configure PowerShell Console Window Size/Preferences
Format-Console -WindowHeight 45 -WindowWidth 170 -BufferHeight 9000 -BufferWidth 170

#--------------------
# Aliases
New-Alias -Name 'Notepad++' -Value 'C:\Program Files\Notepad++\notepad++.exe' -Description 'Launch Notepad++'

#--------------------
# Profile Starts here!
Show-IsAdminOrNot
Write-Host ""
New-Greeting
Write-Host ""
Set-Location -Path D:\GitRepos
