using namespace System.Management.Automation
using namespace System.Management.Automation.Language
using namespace System.Diagnostics.CodeAnalysis
#requires -version 5
[SuppressMessageAttribute('PSAvoidAssignmentToAutomaticVariable', '', Justification = 'PS7 Polyfill')]
[SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'Profile Script')]
param()

#PS7 Polyfill
if ($PSEdition -eq 'Desktop') {
  $isWindows = $true
  $isLinux = $false
  $isMacOS = $false
}

#Force TLS 1.2 for all WinPS 5.1 connections
if ($PSEdition -eq 'Desktop') {
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  oh-my-posh init powershell --config C:\GitRepos\ProfileFunctions\BanterBoyOhMyPoshConfig.json | Invoke-Expression
  Get-ChildItem C:\GitRepos\ProfileFunctions\ProfileFunctions\6Instead\*.ps1 | ForEach-Object {. $_ }
}

#Enable concise errorview for PS7 and up
if ($psversiontable.psversion.major -ge 7) {
  $ErrorView = 'ConciseView'
  # oh-my-posh print primary --config C:\GitRepos\ProfileFunctions\BanterBoyOhMyPoshTheme.json --shell uni
  oh-my-posh init pwsh --config C:\GitRepos\ProfileFunctions\BanterBoyOhMyPoshConfig.json | Invoke-Expression
  Get-ChildItem C:\GitRepos\ProfileFunctions\ProfileFunctions\7Only\*.ps1 | ForEach-Object {. $_ }
}

#--------------------
# Generic Profile Commands
#--------------------
Get-ChildItem C:\GitRepos\ProfileFunctions\ProfileFunctions\*.ps1 | ForEach-Object {. $_ }
Get-ChildItem C:\GitRepos\Windows-Sandbox\Start-WindowsSandbox.ps1 | ForEach-Object {. $_ }


# #region VSCodeDefaultDarkTheme
# #Matches colors to the VSCode Default Dark Theme
if ($PSStyle) {
  #Enable new fancy progress bar for Windows Terminal
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
    $DarkPlusTypeGreen = "`e[38;2;78;201;176m" #4EC9B0 Dark Plus Type color
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

      # These colors should be standard
      # Command            = "$e[93m"
      # Comment            = "$e[32m"
      # ContinuationPrompt = "$e[37m"
      # Default            = "$e[37m"
      # Emphasis           = "$e[96m"
      # Number             = "$e[35m"
      # Operator           = "$e[37m"
      # Selection          = "$e[37;46m"
    }
  }

} else {
  #Legacy PS5.1 Configuration
  #ANSI Escape Character
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
#endregion Theme


#--------------------
# Set-ExecutionPolicy
# Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process -Force

# basic greeting function, contents to be added to current function
Write-Output "Type Get-ProfileFunctions to see the available functions"
Write-Output ""
Show-IsAdminOrNot

#--------------------
# Configure PowerShell Console Window
# Set-DisplayIsAdmin

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

#--------------------
# PSDrives
# New-PSDrive -Name GitRepos -PSProvider FileSystem -Root C:\GitRepos\ -Description "GitHub Repositories" | Out-Null
# New-PSDrive -Name Sysint -PSProvider FileSystem -Root "$env:OneDrive\Software\SysinternalsSuite" -Description "Sysinternals Suite Software" | Out-Null

#--------------------
# Aliases
New-Alias -Name 'Notepad++' -Value 'C:\Program Files\Notepad++\notepad++.exe' -Description 'Launch Notepad++'

#--------------------
# Profile Starts here!
Write-Output ""
New-Greeting
Set-Location -Path C:\

# Import the Chocolatey Profile that contains the necessary code to enable
# tab-completions to function for `choco`.
# Be aware that if you are missing these lines from your profile, tab completion
# for `choco` will not function.
# See https://ch0.co/tab-completion for details.
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}
