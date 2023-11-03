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
oh-my-posh init pwsh --config "$($profileProcessor.PsPath)\Modules\oh-my-posh\themes\_rob.omp.json" | Invoke-Expression

### posh git import
Import-Module posh-git
$env:POSH_GIT_ENABLED = $true

### Import modules using Profilefunctions/Tools-InstallUpdate.ps1
Import-ModulesOnInit -Modules

### Add .NET assemblies
Add-type -AssemblyName WindowsBase
Add-type -AssemblyName PresentationCore

### Import AWS Tools modules if tab key is pressed using Profilefunctions/Tools-InstallUpdate.ps1
if ([System.Windows.Input.Keyboard]::IsKeyDown([System.Windows.Input.Key]::Tab)) {
	Write-Host "Tab key pressed, importing AWS Tools" -ForegroundColor Magenta
	Write-Host ""
	
	Import-ModulesOnInit -Aws
}

### simple function to open PS history in vs code
function Show-History {
	vscode $History
}

### simple function to open an admin terminal
function Admin-Terminal {
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
function List-ProfileFunctions 
{
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
						Write-Host -ForegroundColor $colours[$i] ($_[$i].PadRight($maxLength, ' '))
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

### Release ephemeral ports because Windows is occassionally a bell-end with port reservation
function Release-Ephemeral-Ports
{
	param (
		[Parameter(Mandatory = $false, HelpMessage = "Port to reserve")]
        [int]$Port = 0,

		[Parameter(Mandatory = $false, HelpMessage = "Port protocol; tcp or udp")]
		[ValidateSet('tcp', 'udp')]
        [string]$Protocol = 'tcp'
    )

    net stop winnat
	# net start winnat

	# netsh int ipv4 show dynamicport tcp

	# netsh int ipv4 show excludedportrange protocol=tcp

	# netsh int ipv4 set dynamic tcp start=49999 num=15537

	# reg add HKLM\SYSTEM\CurrentControlSet\Services\hns\State /v EnableExcludedPortRange /d 0 /f

	if ($Port -gt 0) {
		netsh int ipv4 add excludedportrange protocol=$Protocol startport=$Port numberofports=1
		# netsh int ipv4 delete excludedportrange protocol=$Protocol startport=$Port numberofports=1
	}

	# if this still fails then let the prgram that has the issue run first, winnat should be started automatically
	# net start winnat
}

# Set-ExecutionPolicy
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process -Force

#--------------------
# Aliases

@(
	[pscustomobject]@{Name = 'Notepad++'; Value = 'C:\Program Files\Notepad++\notepad++.exe'; Desc = 'Launch Notepad++'}
	[pscustomobject]@{Name = 'vscode'; Value = 'C:\Users\Rob\AppData\Local\Programs\Microsoft VS Code\Code.exe'; Desc = 'Launch VS Code'}
	[pscustomobject]@{Name = 'vs2019'; Value = 'C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\Common7\IDE\devenv.exe'; Desc = 'Launch VS 2019'}
	[pscustomobject]@{Name = 'vs'; Value = 'C:\Program Files\Microsoft Visual Studio\2022\Enterprise\Common7\IDE\devenv.exe'; Desc = 'Launch VS 2022'}
	[pscustomobject]@{Name = 'vs-preview'; Value = 'C:\Program Files\Microsoft Visual Studio\2022\Preview\Common7\IDE\devenv.exe'; Desc = 'Launch VS 2022 Preview'}
	[pscustomobject]@{Name = 'beanstalk'; Value = 'Get-ElasticBeanstalkConfig'; Desc = 'Get eb config'}
	[pscustomobject]@{Name = 'aws-beanstalk'; Value = 'Get-ElasticBeanstalkConfig'; Desc = 'Get eb config'}
	[pscustomobject]@{Name = 'pf'; Value = 'List-ProfileFunctions'; Desc = 'List profile functions'}
	#[pscustomobject]@{Name = 'gallery-packages'; Value = 'Invoke-PowershellGalleryPackages'; Desc = 'Go to Powershell Gallery my packages web page'}
) | Foreach-Object {
	if (-Not (Test-Path alias:$($_.Name))) {
		New-Alias -Name $($_.Name) -Value $($_.Value) -Description $($_.Desc)
	}
}

### Configure CoPilot, see: https://github.com/leumasme/copilot-cli-powershell
Set-GitHubCopilotAliases

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
	### Variable to store all profile functions, populated from class methods
	[string[]] $ProfileFunctions = @()

	### Static list of profile functions that require admin privileges
	[string[]] $AdminProfileFunctions = @('Stop-ServerDashService', 'Start-ServerDashService', 'Remove-ServerDashService', 'Add-ServerDashService', 
		'ScheduledTask-Create-DownloadEnvironmentUpdate', 'ScheduledTask-Delete-DownloadEnvironmentUpdate',
		'ScheduledTask-Create-JellyfinUpdate', 'ScheduledTask-Delete-JellyfinUpdate')

	### Static list of script files that require admin privileges
	[string[]] $AdminScriptFiles = @('ServerDash-Service.ps1', 'ScheduledTasks.ps1')

	[string] $PsPath = "C:\Users\Rob\OneDrive\Documents\PowerShell"
	[string] $ProfileFunctionsPath = "$($this.psPath)\ProfileFunctions"
	[string] $ProfileFilePath = "$($this.psPath)\Microsoft.PowerShell_profile.ps1"
	[string] $GitPath = "C:\Users\Rob\GitHub\"	
	[string] $ServerDashScriptPath = "$($this.GitPath)\server-dash\Powershell"

	### Class constructor, run when instantiated. 
	### Takes a boolean to determine if the user is an admin.
	ProfileProcessor([bool] $isAdmin) {
		### Get and import all profile functions
		$this.BuildProfileFunctions($isAdmin)

		### GitRepos Path by default, test in case this is not set
		Set-Location ((Test-Path $this.GitPath) ? $this.GitPath : "C:\")

		### Add open ssl to path if not present
		$this.AddOpenSslToPath()
	}

	### Exposed method that writes the greeting when starting a session
	[void] WriteGreeting() {
		$isAdmin = IsAdmin

		$prv = $isAdmin ? "Admin" : "User"
		$frg = $isAdmin ? "Red" :  "Green"
	
		Write-Host -ForegroundColor $frg "$($((get-date).ToLocalTime()).ToString("H:mm:ss on ddd, dd MMM yyyy"))  |  $prv Privileges"
		$WTFismyIP = (Get-WTFismyIP -AsObject -TimeoutSeconds 3)
		Write-Host -ForegroundColor Cyan "$($WTFismyIP.YourFuckingIPAddress) via $($WTFismyIP.YourFuckingISP)"
		Write-Host ""

		Write-Host "Profile functions: " -NoNewline
		Write-Host -ForegroundColor "Yellow" "pf" -NoNewline
		Write-Host " or " -NoNewline
		Write-Host -ForegroundColor "Yellow" "List-ProfileFunctions"
	
		Write-Host ""
	}

	### Get all script locations
	[string[]] ScriptLocations() {
		[string[]] $locations = @($this.ProfileFunctionsPath);

		if (Test-Path $this.ServerDashScriptPath) {
			$locations = $locations + $this.ServerDashScriptPath
		}

		return $locations
	}

	### Hidden method to get required profile functions from all locations and place in the ProfileFunctions class variable
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

	### Hidden method to get function names from a script file
	### Takes a path to a script file and a boolean to determine if non-hyphenated functions should be included
	### Excludes global functions by default
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

				if ($match.Success)	{
					$funcNames += "$($match.Groups[3])"
				}   
			}
		
		return $funcNames
	}

	### Hidden method to add open ssl to path if not present
	hidden [void] AddOpenSslToPath() {
		# add open ssl to path if not present
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