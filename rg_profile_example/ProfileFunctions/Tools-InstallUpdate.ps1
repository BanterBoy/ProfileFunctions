# import all modules and AWS tools on profile load
function Import-ModulesOnInit {
    <#
    .SYNOPSIS
        Import all modules and AWS tools on profile load
    .DESCRIPTION
        Import all modules and AWS tools on profile load
    #>

    [CmdletBinding()]
    
    param (
        [Parameter(Mandatory = $false)]
        [switch] $Modules,

        [Parameter(Mandatory = $false)]
        [switch] $Aws
    )

    Process {
        if ($Modules) {
            foreach ($module in [ModulesConfig]::new().Modules()) {
                Import-Module -Name $module
            }
        }

        if ($Aws) {
            foreach ($tool in [AwsToolsConfig]::new().AwsTools()) {
                Import-Module -Name $tool
            }
        }
    }
}

function InstallUpdate-AllDependencies {
    <#
    .SYNOPSIS
        Installs or updates all predefined nuget sources, dotnet tools, modules and AWS tools.
    .DESCRIPTION
        Installs or updates all predefined nuget sources, dotnet tools, modules and AWS tools.
    #>

    [CmdletBinding()]

    param ()

    Process {
        Write-Verbose "Processing nuget sources..."

        InstallUpdate-NugetSources

        Write-Verbose "Processing dotnet tools..."

        InstallUpdate-DotNetTools

        Write-Verbose "Processing modules..."

        InstallUpdate-Modules

        Write-Verbose "Processing AWS tools..."

        InstallUpdate-AwsTools
    }
}

function InstallUpdate-DotNetTools {
    <#
    .SYNOPSIS
        Installs or updates all predefined dotnet tools, or the supplied pre-defined tool.
    .DESCRIPTION
        Installs or updates all predefined dotnet tools, or the supplied pre-defined tool.
    .PARAMETER SelectedTool
        Only install or update this tool, not all predefined tools.
    #>

    [CmdletBinding()]

    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet([DotNetToolConfigValidator])]
        [string] $SelectedTool
    )

    Begin {
        function InstallUpdate([pscustomobject] $tConfig) {
            if ($tConfig.UseDotnetVersionCommand) {
                $dotnetVersion = dotnet $tConfig.Command --version

                if ($null -eq $dotnetVersion) {
                    dotnet tool install -g $tConfig.Name --no-cache
                } else {
                    dotnet tool update -g $tConfig.Name --no-cache
                }
            }
            else {
                if (-Not (Get-Command $tConfig.Command -errorAction SilentlyContinue)) {
                    dotnet tool install -g $tConfig.Name --no-cache
                } else {
                    dotnet tool update -g $tConfig.Name --no-cache
                }
            }
        }
    }

    Process {
        $toolConfig = [DotNetToolConfig]::new()

        if (-Not [String]::IsNullOrWhiteSpace($SelectedTool)) {
            InstallUpdate($toolConfig.FindName($SelectedTool))

            return
        }

        foreach ($toolConfig in $toolConfig.ToolConfigs) {
            InstallUpdate($toolConfig)
        }        
    }
}

function InstallUpdate-NugetSources {
    <#
    .SYNOPSIS
        Installs or updates all predefined nuget sources, or the supplied pre-defined source.
    .DESCRIPTION
        Installs or updates all predefined nuget sources, or the supplied pre-defined source.
    .PARAMETER SelectedTool
        Only install or update this nuget source, not all predefined sources.
    #>

    [CmdletBinding()]

    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet([NugetSourceConfigValidator])]
        [string] $Source
    )

    Begin {
        $sources = dotnet nuget list source

        function InstallUpdate([pscustomobject] $config) {
            if (-Not [regex]::IsMatch($sources, $config.RegexPattern)) {
                if ([string]::IsNullOrWhiteSpace($config.Username)) {
                    dotnet nuget add source $config.Url -n $config.Name
                } else {
                    dotnet nuget add source $config.Url -n $config.Name -u $config.Username -p $config.Token --store-password-in-clear-text
                }
            } else {
                dotnet nuget update source $config.Name
            }
        }
    }

    Process {
        $nugetSourceConfig = [NugetSourceConfig]::new()

        if (-Not [String]::IsNullOrWhiteSpace($Source)) {
            InstallUpdate($nugetSourceConfig.FindName($Source))

            return
        }

        foreach ($nugetSourceConfig in $nugetSourceConfig.nugetSourceConfigs) {
            InstallUpdate($nugetSourceConfig)
        }
    }
}

function InstallUpdate-Modules {
    <#
    .SYNOPSIS
        Installs or updates all predefined modules, or the supplied pre-defined module.
    .DESCRIPTION
        Installs or updates all predefined modules, or the supplied pre-defined module.
    .PARAMETER SelectedTool
        Only install or update this module, not all predefined modules.
    #>

    [CmdletBinding()]

    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet([ModulesConfigValidator])]
        [string] $SelectedModule
    )

    Begin {
        function InstallUpdate([string] $module) {
            try {
                if ((Get-Module -Name $module -ListAvailable)) {
                    Write-Verbose "Updating and importing $($module)"

                    Update-Module -Name $module -Force -ErrorAction SilentlyContinue
                    Import-Module -Name $module
                }
                Else {
                    Write-Verbose "Installing and importing $($module)"

                    Install-Module -Name $module -Force -ErrorAction Stop
                    Import-Module -Name $module
                }
            }
            catch {
                Write-Error -Message $_.Exception.Message
            }
        }
    }

    Process {
        $moduleConfig = [ModulesConfig]::new()

        if (-Not [String]::IsNullOrWhiteSpace($SelectedModule)) {
            InstallUpdate($SelectedModule)

            return
        }

        foreach ($module in $moduleConfig.Modules()) {
            InstallUpdate($module)
        }        
    }
}

function InstallUpdate-AwsTools {
    <#
    .SYNOPSIS
        Installs or updates all predefined aws tools, or the supplied pre-defined aws tool.
    .DESCRIPTION
        Installs or updates all predefined aws tools, or the supplied pre-defined aws tool.
    .PARAMETER SelectedTool
        Only install or update this aws tool, not all predefined aws tools.
    #>

    [CmdletBinding()]

    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet([AwsToolsConfigValidator])]
        [string] $SelectedTool
    )

    Begin {
        function InstallUpdate([string] $tool) {
            try {
                if (-Not (Get-Module -Name $tool -ListAvailable)) {
                    Write-Verbose "Installing and importing $($tool)"

                    Install-AWSToolsModule -Name $tool -Force -ErrorAction Stop -SkipPublisherCheck
                    Import-Module -Name $tool
                    
                    
                    Import-Module -Name $tool
                }

                Write-Verbose "Running update"

                Update-AWSToolsModule -Force -ErrorAction SilentlyContinue -SkipPublisherCheck
            }
            catch {
                Write-Error -Message $_.Exception.Message
            }
        }
    }

    Process {
        $awsToolsConfig = [AwsToolsConfig]::new()

        if (-Not [String]::IsNullOrWhiteSpace($SelectedTool)) {
            InstallUpdate($SelectedTool)

            return
        }

        foreach ($ttool in $awsToolsConfig.AwsTools()) {
            InstallUpdate($ttool)
        }        
    }
}

class NugetSourceConfig {
    [pscustomobject[]] $nugetSourceConfigs = @(
        [pscustomobject]@{
            Name = "NuGet official package source";
            RegexPattern = "NuGet official";
            Url = "https://api.nuget.org/v3/index.json";
            Username = $null;
            Token = $null;
        },        
        [pscustomobject]@{
            Name = "rob-github";
            RegexPattern = "rob\-github";
            Url = "https://nuget.pkg.github.com/trossr32/index.json";
            Username = "trossr32";
            Token = "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";
        },        
        [pscustomobject]@{
            Name = "Yourkeys-github";
            RegexPattern = "Yourkeys\-github";
            Url = "https://nuget.pkg.github.com/Yourkeys/index.json";
            Username = "Yourkeys";
            Token = "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";
        },        
        [pscustomobject]@{
            Name = "GeckoRisk-github";
            RegexPattern = "GeckoRisk\-github";
            Url = "https://nuget.pkg.github.com/GeckoRisk/index.json";
            Username = "GeckoRisk";
            Token = "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";
        },        
        [pscustomobject]@{
            Name = "txn-network-github";
            RegexPattern = "Transaction-Network\-github";
            Url = "https://nuget.pkg.github.com/Transaction-Network/index.json";
            Username = "zpg-sre-service-account";
            Token = "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";
        }
    )
   
    [String[]] Names() {
        return $this.nugetSourceConfigs | ForEach-Object { "$($_.Name)" }
    }

    [pscustomobject[]] FindName ([string] $command) {
        return $this.nugetSourceConfigs | Where-Object { $_.Name -eq $command }
    }
}

class NugetSourceConfigValidator : System.Management.Automation.IValidateSetValuesGenerator {
    [String[]] GetValidValues() {
        return [NugetSourceConfig]::new().Names()
    }
}

class DotNetToolConfig {
    [pscustomobject[]] $toolConfigs = @(
        [pscustomobject]@{Name = "amazon.elasticbeanstalk.tools";   Command = "dotnet-eb";                   UseDotnetVersionCommand = $false;}, 
        [pscustomobject]@{Name = "amazon.lambda.testtool-3.1";      Command = "dotnet-lambda-test-tool-3.1"; UseDotnetVersionCommand = $false;}, 
        [pscustomobject]@{Name = "amazon.lambda.testtool-6.0";      Command = "dotnet-lambda-test-tool-6.0"; UseDotnetVersionCommand = $false;}, 
        [pscustomobject]@{Name = "amazon.lambda.tools";             Command = "dotnet-lambda";               UseDotnetVersionCommand = $false;}, 
        [pscustomobject]@{Name = "corecli";                         Command = "rg";                          UseDotnetVersionCommand = $false;}, 
        [pscustomobject]@{Name = "csharprepl";                      Command = "csharprepl";                  UseDotnetVersionCommand = $false;}, 
        [pscustomobject]@{Name = "dotnet-aspnet-codegenerator";     Command = "dotnet-aspnet-codegenerator"; UseDotnetVersionCommand = $false;}, 
        [pscustomobject]@{Name = "dotnet-ef";                       Command = "dotnet-ef";                   UseDotnetVersionCommand = $false;}, 
        [pscustomobject]@{Name = "dotnet-script";                   Command = "dotnet-script";               UseDotnetVersionCommand = $false;}, 
        [pscustomobject]@{Name = "dotnet-suggest";                  Command = "dotnet-suggest";              UseDotnetVersionCommand = $false;}, 
        [pscustomobject]@{Name = "microsoft.playwright.cli";        Command = "playwright";                  UseDotnetVersionCommand = $false;}, 
        # [pscustomobject]@{Name = "microsoft.tye";                   Command = "tye";}, # currently pre-release, update when release version available
        [pscustomobject]@{Name = "win-acme";                        Command = "wacs";                        UseDotnetVersionCommand = $false;}, 
        [pscustomobject]@{Name = "yourkeyscli";                     Command = "yourkeys";                    UseDotnetVersionCommand = $false;}, 
        [pscustomobject]@{Name = "dotnet-outdated-tool";            Command = "outdated";                    UseDotnetVersionCommand = $true;}
    )
   
    [String[]] Tools() {
        return $this.toolConfigs | ForEach-Object { "$($_.Name)" }
    }
   
    [String[]] Commands() {
        return $this.toolConfigs | ForEach-Object { "$($_.Command)" }
    }

    [pscustomobject[]] FindCommand ([string] $command) {
        return $this.toolConfigs | Where-Object { $_.Command -eq $command }
    }

    [pscustomobject[]] FindName ([string] $command) {
        return $this.toolConfigs | Where-Object { $_.Name -eq $command }
    }
}

class DotNetToolConfigValidator : System.Management.Automation.IValidateSetValuesGenerator {
    [String[]] GetValidValues() {
        return [DotNetToolConfig]::new().Tools()
    }
}

class ModulesConfig {
    [String[]] $moduleConfigs = @(
        "Transmission",
        "FlattenFolders",
        "GithubRepoSnapshot",
        "ImageDataUriConverter",
        "JsonToPowershellClass",
        "VideoResolution",
        #"oh-my-posh",
        "posh-git",
        "copilot-cli-powershell",
        #"PoShLog",
        "AWS.Tools.Installer"
    )
   
    [String[]] Modules() {
        return $this.moduleConfigs
    }
}

class ModulesConfigValidator : System.Management.Automation.IValidateSetValuesGenerator {
    [String[]] GetValidValues() {
        return [ModulesConfig]::new().Modules()
    }
}

class AwsToolsConfig {
    [String[]] $awsToolsConfigs = @(
        "AWS.Tools.SSO",
        "AWS.Tools.SSOOIDC",
        "AWS.Tools.SimpleSystemsManagement",
        "AWS.Tools.EC2",
        "AWS.Tools.RDS"
    )
   
    [String[]] AwsTools() {
        return $this.awsToolsConfigs
    }
}

class AwsToolsConfigValidator : System.Management.Automation.IValidateSetValuesGenerator {
    [String[]] GetValidValues() {
        return [AwsToolsConfig]::new().AwsTools()
    }
}