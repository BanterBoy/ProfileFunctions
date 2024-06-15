using namespace System.Management.Automation
using namespace System.Management.Automation.Language
using namespace System.Diagnostics.CodeAnalysis
[SuppressMessageAttribute('PSAvoidAssignmentToAutomaticVariable', '', Justification = 'PS7 Polyfill')]
[SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'Profile Script')]
param()

# Path to the script that generates the module
$generateModuleScript = "C:\GitRepos\RDGScripts\GenerateModule.ps1"

# Suppress warnings and informational messages
$WarningPreference = 'SilentlyContinue'
$InformationPreference = 'SilentlyContinue'

# Execute the script to generate/update the module
& $generateModuleScript

# Import the module containing all your functions
Import-Module "C:\GitRepos\RDGScripts\PowerShellProfileModule\ProfileFunctions.psm1" -Force

# Reset warning and informational message preferences to default
$WarningPreference = 'Continue'
$InformationPreference = 'Continue'

# PS7 Polyfill
if ($PSEdition -eq 'Desktop') {
  $isWindows = $true
  $isLinux = $false
  $isMacOS = $false
}

# Force TLS 1.2 for all WinPS 5.1 connections
if ($PSEdition -eq 'Desktop') {
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
}

# Enable concise error view for PS7 and up
if ($psversiontable.psversion.major -ge 7) {
  $ErrorView = 'ConciseView'
}

# VSCodeDefaultDarkTheme Configuration
if ($PSStyle) {
  if ($ENV:WT_SESSION) {
    $PSStyle.Progress.UseOSCIndicator = $true
  }

  & {
    $FG = $PSStyle.Foreground
    $Format = $PSStyle.Formatting
    $PSStyle.FileInfo.Directory = $FG.Blue
    $PSStyle.Progress.View = 'Minimal'
    $PSStyle.Progress.UseOSCIndicator = $true
    $DefaultColor = $FG.White
    $Format.Debug = $FG.Magenta
    $Format.Verbose = $FG.Cyan
    $Format.Error = $FG.BrightRed
    $Format.Warning = $FG.Yellow
    $Format.FormatAccent = $FG.BrightBlack
    $Format.TableHeader = $FG.BrightBlack
    $DarkPlusTypeGreen = "`e[38;2;78;201;176m"
    Set-PSReadLineOption -Colors @{
      Error     = $Format.Error
      Keyword   = $FG.Magenta
      Member    = $FG.BrightCyan
      Parameter = $FG.BrightCyan
      Type      = $DarkPlusTypeGreen
      Variable  = $FG.BrightCyan
      String    = $FG.Yellow
      Operator  = $DefaultColor
      Number    = $FG.BrightGreen
    }
  }
} else {
  $e = [char]0x1b
  $host.PrivateData.DebugBackgroundColor = 'Black'
  $host.PrivateData.DebugForegroundColor = 'Magenta'
  $host.PrivateData.ErrorBackgroundColor = 'Black'
  $host.PrivateData.ErrorForegroundColor = 'Red'
  $host.PrivateData.ProgressBackgroundColor = 'DarkCyan'
  $host.PrivateData.ProgressForegroundColor = 'Yellow'
  $host.PrivateData.VerboseBackgroundColor = 'Black'
  $host.PrivateData.VerboseForegroundColor = 'Cyan'
  $host.PrivateData.WarningBackgroundColor = 'Black'
  $host.PrivateData.WarningForegroundColor = 'DarkYellow'

  Set-PSReadLineOption -Colors @{
    Command            = "$e[93m"
    Comment            = "$e[32m"
    ContinuationPrompt = "$e[37m"
    Default            = "$e[37m"
    Emphasis           = "$e[96m"
    Error              = "$e[31m"
    Keyword            = "$e[35m"
    Member             = "$e[96m"
    Number             = "$e[35m"
    Operator           = "$e[37m"
    Parameter          = "$e[37m"
    Selection          = "$e[37;46m"
    String             = "$e[33m"
    Type               = "$e[34m"
    Variable           = "$e[96m"
  }

  Remove-Variable e
}

# Set-ExecutionPolicy
# Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process -Force

# Basic greeting function, contents to be added to current function
Show-IsAdminOrNot

# Configure PowerShell Console Window
Set-PromptisAdmin

# F1 for help on the command line - naturally
Set-PSReadLineKeyHandler -Key F1 `
                         -BriefDescription CommandHelp `
                         -LongDescription "Open the help window for the current command" `
                         -ScriptBlock {
    param($key, $arg)

    $ast = $null
    $tokens = $null
    $errors = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$ast, [ref]$tokens, [ref]$errors, [ref]$cursor)

    $commandAst = $ast.FindAll( {
        $node = $args[0]
        $node -is [CommandAst] -and
            $node.Extent.StartOffset -le $cursor -and
            $node.Extent.EndOffset -ge $cursor
        }, $true) | Select-Object -Last 1

    if ($commandAst -ne $null)
    {
        $commandName = $commandAst.GetCommandName()
        if ($commandName -ne $null)
        {
            $command = $ExecutionContext.InvokeCommand.GetCommand($commandName, 'All')
            if ($command -is [AliasInfo])
            {
                $commandName = $command.ResolvedCommandName
            }

            if ($commandName -ne $null)
            {
                Get-Help $commandName -ShowWindow
            }
        }
    }
}

# Function to set Location
function Go-Home {
	Set-Location -Path C:\
}

# PSDrives
# New-PSDrive -Name GitRepos -PSProvider FileSystem -Root C:\GitRepos\ -Description "GitHub Repositories" | Out-Null
# New-PSDrive -Name Sysint -PSProvider FileSystem -Root "$env:OneDrive\Software\SysinternalsSuite" -Description "Sysinternals Suite Software" | Out-Null

# Aliases
New-Alias -Name 'Notepad++' -Value 'C:\Program Files\Notepad++\notepad++.exe' -Description 'Launch Notepad++'

# Profile Starts here!
Write-Output ""
New-Greeting

# Import the Chocolatey Profile that contains the necessary code to enable
# tab-completions to function for `choco`.
# Be aware that if you are missing these lines from your profile, tab completion
# for `choco` will not function.
# See https://ch0.co/tab-completion for details.
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}

# PowerToys CommandNotFound module
Import-Module "C:\Users\lukeleigh.admin\AppData\Local\PowerToys\WinGetCommandNotFound.psd1"

# Variables
$ServerList = Get-Content -Path "C:\GitRepos\RDGScripts\PowerShellProfile\resources\ServerList.csv" | ConvertFrom-Csv
