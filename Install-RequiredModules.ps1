function Install-RequiredModules {

    <#
    .SYNOPSIS
        Install-RequiredModules - Tests to see if scripts/function required modules are available.
    .DESCRIPTION
        Install-RequiredModules - Tests to see if scripts/function required modules are available. Where module is missing it, the function installs the missing module and then imports all required modules.
    .EXAMPLE
        PS C:\> Install-RequiredModules
        Tests to see if scripts/function required modules are available. Where module is missing it, the function installs the missing module and then imports all required modules.
    .INPUTS
        None.
    .OUTPUTS
        [String] Outputs details of installation, importing and failure.
    .NOTES
        Author	: Luke Leigh
        Website	: https://blog.lukeleigh.com
        Twitter	: https://twitter.com/luke_leighs
        GitHub  : https://github.com/BanterBoy

    #>

    [CmdletBinding(DefaultParameterSetName = 'Default',
        PositionalBinding = $true,
        SupportsShouldProcess = $true)]
    [OutputType([string], ParameterSetName = 'Default')]
    Param
    (
        [Parameter(ParameterSetName = 'Default',
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Enter a computer name or pipe input'
        )]
        [string[]]$PublicModules,

        [Parameter(ParameterSetName = 'Internal',
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Enter a computer name or pipe input'
        )]
        [string[]]$InternalModules,

        [Parameter(ParameterSetName = 'Internal',
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Enter a computer name or pipe input'
        )]
        [string[]]$InternalGalleryName,

        [Parameter(ParameterSetName = 'RSAT',
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Use this switch to install the Microsoft RSAT suite of tools. This includes the Active Directory module which is not available in the PowerShell Gallery.'
        )]
        [switch]$RSATTools
    )
    
    begin {

    }

    process {
        if ($PSCmdlet.ShouldProcess("$_", "Importing/Installing modules...")) {
            if ($PublicModules) {
                # Installing Public Modules
                foreach ($Module in $PublicModules) {
                    try {
                        if ((Get-Module -Name $Module -ListAvailable)) {
                            Write-Verbose "Importing module - $($Module)"
                            Import-Module -Name $Module
                        }
                        Else {
                            Write-Verbose "Installing module - $($Module)"
                            Install-Module -Name $Module -Repository 'PSGallery' -Force -ErrorAction Stop
                            Import-Module -Name $Module
                        }
                    }
                    catch {
                        Write-Error -Message $_.Exception.Message
                    }
                }
            }

            if ($InternalModules) {
                # Installing Internal Modules
                foreach ($Module in $InternalModules) {
                    try {
                        if ((Get-Module -Name $Module -ListAvailable)) {
                            Write-Verbose "Importing module - $($Module)"
                            Import-Module -Name $Module
                        }
                        Else {
                            Write-Verbose "Installing module - $($Module)"
                            Install-Module -Name $Module -Repository $InternalGalleryName -Force -ErrorAction Stop
                            Import-Module -Name $Module
                        }
                    }
                    catch {
                        Write-Error -Message $_.Exception.Message
                    }
                }
            }

            if ($RSATTools) {
                try {
                    if ((Get-Module -Name 'ActiveDirectory' -ListAvailable)) {
                        Write-Verbose "Importing module - ActiveDirectory"
                        Import-Module -Name 'ActiveDirectory'
                    }
                    else {
                        Write-Verbose "Installing module - RSAT Tools"
                        Get-WindowsCapability -Name "Rsat*" -Online | Add-WindowsCapability -Online
                        Import-Module -Name 'ActiveDirectory'
                    }
                }
                catch {
                    Write-Error -Message $_.Exception.Message
                }
            }
        }
    }


    end {
        ForEach-Object -InputObject $PublicModules -Process {
            Get-Module -Name $_
        }
    }
}
