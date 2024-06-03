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
    Get-ChildItem C:\GitRepos\ProfileFunctions\ProfileFunctions\6Instead\*.ps1 | ForEach-Object { . $_ }
}

#Enable concise errorview for PS7 and up
if ($psversiontable.psversion.major -ge 7) {
    $ErrorView = 'ConciseView'
    Get-ChildItem C:\GitRepos\ProfileFunctions\ProfileFunctions\7Only\*.ps1 | ForEach-Object { . $_ }
}

#--------------------
# Generic Profile Commands
#--------------------
Get-ChildItem C:\GitRepos\ProfileFunctions\ProfileFunctions\*.ps1 | ForEach-Object { . $_ }
Get-ChildItem C:\GitRepos\ProfileFunctions\ProfileFunctions\Personal\*.ps1 | ForEach-Object { . $_ }
Get-ChildItem C:\GitRepos\Windows-Sandbox\Start-WindowsSandbox.ps1 | ForEach-Object { . $_ }

#--------------------
# Set-ExecutionPolicy
# Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process -Force

# basic greeting function, contents to be added to current function
# Write-Output "Type Get-ProfileFunctions to see the available functions"
# Write-Output ""
# Show-IsAdminOrNot

#--------------------
# Configure PowerShell Console Window
# Set-PromptisAdmin

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

    if ($commandAst -ne $null) {
        $commandName = $commandAst.GetCommandName()
        if ($commandName -ne $null) {
            $command = $ExecutionContext.InvokeCommand.GetCommand($commandName, 'All')
            if ($command -is [AliasInfo]) {
                $commandName = $command.ResolvedCommandName
            }

            if ($commandName -ne $null) {
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

# Import the Chocolatey Profile that contains the necessary code to enable
# tab-completions to function for `choco`.
# Be aware that if you are missing these lines from your profile, tab completion
# for `choco` will not function.
# See https://ch0.co/tab-completion for details.
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
    Import-Module "$ChocolateyProfile"
}


### Create an IsAdmin function then store the result in a variable
function IsAdmin {	
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal $identity
    $principal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

$isAdmin = IsAdmin

### Create a new instance of the ProfileProcessor class
$profileProcessor = [ProfileProcessor]::new($isAdmin)

### Set the history file path
$History = "C:\Users\Rob\AppData\Roaming\Microsoft\Windows\PowerShell\History\PSHistory.txt"

### Import external scripts using any script locations defined in the ProfileProcessor class
foreach ($location in $($profileProcessor.ScriptLocations())) {
    Get-ChildItem $location -Recurse -Filter "*.ps1" | 
    ForEach-Object { 
        if (($isAdmin) -Or (-Not $profileProcessor.AdminScriptFiles.Contains($_.Name))) {
            . $_ 
        }
    }
}

### oh my posh terminal theming
# oh-my-posh init pwsh --config "$($profileProcessor.PsPath)\m365princessOhMyPoshConfig.json" | Invoke-Expression
oh-my-posh init pwsh --config "$($profileProcessor.PsPath)\gmay.omp.json" | Invoke-Expression

### posh git import
Import-Module posh-git
$env:POSH_GIT_ENABLED = $true

### Import modules using Profilefunctions/Tools-InstallUpdate.ps1
# Import-ModulesOnInit -Modules

### Add .NET assemblies
Add-type -AssemblyName WindowsBase
Add-type -AssemblyName PresentationCore

### simple function to open PS history in vs code
function Show-History {
    vscode $History
}

### simple function to open an admin terminal
function New-AdminTerminal {
    powershell -Command "Start-Process 'wt' -Verb runAs"
}

### simple function edit or referesh profile
function Profile {
    param (
        [parameter(Mandatory = $true)]
        [string][ValidateSet('Edit', 'Refresh')]
        $Action
    )

    switch ($Action) {
        'Edit' { vscode $profile }
        'Refresh' { . $profile }
    }
}

<#
.SYNOPSIS
Takes an array and breaks down into an array of arrays by a supplied batch size

.EXAMPLE
BatchArray -Arr @(1,2,3,4,5,6,7,8,9) -BatchSize 5 | ForEach-Object { Write-Host $_ }
#>
function BatchArray {
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, HelpMessage = "Array to be batched.")]
        [object[]]$Arr,

        [Parameter(Mandatory = $false, HelpMessage = "Number of objects in each batch.")]
        [int]$BatchSize = 5
    )

    for ($i = 0; $i -lt $Arr.Count; $i += $BatchSize) {
        , ($Arr | Select-Object -Skip $i -First $BatchSize)
    }
}

### List profile function retrieved from the ProfileProcessor class and colour code the output
function Get-ProfileFunctions {
    Write-Host "Profile functions:"
    Write-Host ""

    function BatchAndWrite {
        param (
            [Parameter(Mandatory = $true, ValueFromPipeline = $true, HelpMessage = "Array to be batched")]
            [object[]]$Arr
        )

        $colours = @('Green', 'Yellow', 'Cyan', 'Magenta')

        $maxLength = (($Arr | Measure-Object -Maximum -Property Length).Maximum) + 2

        BatchArray -Arr ($Arr | Sort-Object) -BatchSize 4 | 
        ForEach-Object {
            if ($_.Count -eq 1) {
                continue
            }

            for ($i = 0; $i -lt $_.Count; $i++) {
                if ($i -eq 3) {
                    Write-Host -ForegroundColor $colours[$i] ($_[$i
                        ].PadRight($maxLength, ' '))
                }
                else {
                    Write-Host -ForegroundColor $colours[$i] ($_[$i].PadRight($maxLength, ' ')) -NoNewline
                }
            }
        }
    }

    BatchAndWrite -Arr $profileProcessor.ProfileFunctions

    if (-Not $(IsAdmin)) {
        Write-Host ""
        Write-Host ""
        Write-Host -ForegroundColor "Red" "The following functions require admin permissions: "
        Write-Host ""

        BatchAndWrite -Arr $profileProcessor.AdminProfileFunctions
    }

    Write-Host ""
}

# Set-ExecutionPolicy
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process -Force

#--------------------
# Aliases

@(
    [pscustomobject]@{Name = 'Notepad++'; Value = 'C:\Program Files\Notepad++\notepad++.exe'; Desc = 'Launch Notepad++' }
    [pscustomobject]@{Name = 'pf'; Value = 'Get-ProfileFunctions'; Desc = 'List profile functions' }
) | Foreach-Object {
    if (-Not (Test-Path alias:$($_.Name))) {
        New-Alias -Name $($_.Name) -Value $($_.Value) -Description $($_.Desc)
    }
}

### Configure CoPilot, see: https://github.com/leumasme/copilot-cli-powershell
# Set-GitHubCopilotAliases

### Write greeting using the ProfileProcessor class
$profileProcessor.WriteGreeting()

### I'll be honest, can't remember what this is for  ¯\_(ツ)_/¯
$global:originalPSConsoleHostReadLine = $function:global:PSConsoleHostReadLine
$global:originalPrompt = $function:global:Prompt

$function:global:PSConsoleHostReadLine = {
    $startProgressIndicator = "`e]9;4;3;50`e\"
    $command = $originalPSConsoleHostReadLine.Invoke()
    $startProgressIndicator | Write-Host -NoNewLine
    $command
}

$function:global:Prompt = {
    $stopProgressIndicator = "`e]9;4;0;50`e\"
    $stopProgressIndicator | Write-Host -NoNewLine
    $originalPrompt.Invoke()
}

<# 
	Profile processor class 
#>
class ProfileProcessor {
    [string[]] $ProfileFunctions = @()
    [string[]] $AdminProfileFunctions = @('')
    [string[]] $AdminScriptFiles = @('')
    [string] $PsPath = "C:\GitRepos\ProfileFunctions"
    [string] $ProfileFunctionsPath = "$($this.psPath)\ProfileFunctions"
    [string] $ProfileFilePath = "$($this.psPath)\Microsoft.PowerShell_profile.ps1"
    [string] $GitPath = "C:\GitRepos\"    
    [string] $ServerDashScriptPath = "$($this.GitPath)\server-dash\Powershell"

    ProfileProcessor([bool] $isAdmin) {
        $this.BuildProfileFunctions($isAdmin)
        Set-Location ((Test-Path $this.GitPath) ? $this.GitPath : "C:\")
        $this.AddOpenSslToPath()
    }

    [void] WriteGreeting() {
        $isAdmin = IsAdmin
        $prv = $isAdmin ? "Admin" : "User"
        $frg = $isAdmin ? "Red" :  "Green"
        Write-Host -ForegroundColor $frg "$($((get-date).ToLocalTime()).ToString("H:mm:ss on ddd, dd MMM yyyy"))  |  $prv Privileges"
        $WTFismyIP = (Get-WTFismyIP)
        Write-Host -ForegroundColor Cyan "$($WTFismyIP.YourFuckingIPAddress) via $($WTFismyIP.YourFuckingISP)"
        Write-Host ""
        Write-Host "Profile functions: " -NoNewline
        Write-Host -ForegroundColor "Yellow" "pf" -NoNewline
        Write-Host " or " -NoNewline
        Write-Host -ForegroundColor "Yellow" "Get-ProfileFunctions"
        Write-Host ""
    }

    [string[]] ScriptLocations() {
        [string[]] $locations = @($this.ProfileFunctionsPath);
        if (Test-Path $this.ServerDashScriptPath) {
            $locations = $locations + $this.ServerDashScriptPath
        }
        return $locations
    }

    hidden [void] BuildProfileFunctions([bool] $isAdmin) {
        [string[]] $funcs = @();
        foreach ($location in $this.ScriptLocations()) {
            Get-ChildItem $location -Recurse -Filter "*.ps1" |
            ForEach-Object {
                if ($_.Name -eq "global") {
                    continue
                }
                $includeNonHypenatedFunctions = @('SearchFunctions.ps1')
                if (($isAdmin) -Or (-Not $this.AdminScriptFiles.Contains($_.Name))) {
                    $funcs = $funcs + ($this.GetScriptFunctionNames($_, ($includeNonHypenatedFunctions.Contains($_.Name))))
                }
            }
        }
        if (Test-Path "$($this.GitPath)\Windows-Sandbox") {
            $funcs = $funcs += 'New-WindowsSandbox'
        }
        $this.ProfileFunctions = $funcs
    }

    hidden [string[]] GetScriptFunctionNames([string]$path, [bool]$includeNonHyphenatedFunctions) {
        [string[]]$funcNames = @()
        if (([System.String]::IsNullOrWhiteSpace($path))) {
            return $funcNames
        }
        $pattern = $includeNonHyphenatedFunctions ? "^[F|f]unction.*[A-Za-z0-9+]" : "^[F|f]unction.*[A-Za-z0-9+]-[A-Za-z0-9+]"
        Select-String -Path "$path" -Pattern $pattern | 
        ForEach-Object {
            [System.Text.RegularExpressions.Regex] $regexp = New-Object Regex("([F|f]unction)( +)(?>global:)?([\w-]+)")
            [System.Text.RegularExpressions.Match] $match = $regexp.Match("$_")
            if ($match.Success) {
                $funcNames += "$($match.Groups[3])"
            }   
        }
        return $funcNames
    }

    hidden [void] AddOpenSslToPath() {
        $openSslBin = "C:\Program Files\OpenSSL\bin"
        $openSslCnf = "C:\certs\openssl.cnf"
        if ((Test-Path $openSslBin) -and (-Not $env:path.Contains($openSslBin))) {
            $env:path = "$env:path;$openSslBin"
        }
        if ((Test-Path $openSslCnf) -and ($env:OPENSSL_CONF -ne $openSslCnf)) {
            $env:OPENSSL_CONF = $openSslCnf
        }
    }
}




#f45873b3-b655-43a6-b217-97c00aa0db58 PowerToys CommandNotFound module

Import-Module -Name Microsoft.WinGet.CommandNotFound
#f45873b3-b655-43a6-b217-97c00aa0db58

