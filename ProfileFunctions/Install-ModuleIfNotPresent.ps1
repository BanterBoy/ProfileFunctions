function Install-ModuleIfNotPresent {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ModuleName,

        [Parameter(Mandatory = $true)]
        [string]$Repository
    )

    try {
        if ((Get-Module -Name $ModuleName -ListAvailable)) {
            Write-Verbose "Importing module - $($ModuleName)"
            Import-Module -Name $ModuleName
        }
        Else {
            Write-Verbose "Installing module - $($ModuleName)"
            Install-Module -Name $ModuleName -Repository $Repository -Force -ErrorAction Stop
            Import-Module -Name $ModuleName
        }
    }
    catch {
        Write-Error -Message $_.Exception.Message
    }
}

# function Install-RequiredModules {
#     [CmdletBinding(DefaultParameterSetName = 'Default',
#         PositionalBinding = $true,
#         SupportsShouldProcess = $true)]
#     [OutputType([string], ParameterSetName = 'Default')]
#     [Alias('instrm')]
#     Param
#     (
#         [Parameter(ParameterSetName = 'Default',
#             Mandatory = $false,
#             ValueFromPipeline = $true,
#             ValueFromPipelineByPropertyName = $true,
#             HelpMessage = 'Enter a computer name or pipe input'
#         )]
#         [Alias('pm')]
#         [string[]]$PublicModules,

#         [Parameter(ParameterSetName = 'Internal',
#             Mandatory = $false,
#             ValueFromPipeline = $true,
#             ValueFromPipelineByPropertyName = $true,
#             HelpMessage = 'Enter a computer name or pipe input'
#         )]
#         [Alias('im')]
#         [string[]]$InternalModules,

#         [Parameter(ParameterSetName = 'Internal',
#             Mandatory = $false,
#             ValueFromPipeline = $true,
#             ValueFromPipelineByPropertyName = $true,
#             HelpMessage = 'Enter a computer name or pipe input'
#         )]
#         [Alias('ign')]
#         [string[]]$InternalGalleryName,

#         [Parameter(ParameterSetName = 'RSAT',
#             Mandatory = $false,
#             ValueFromPipeline = $true,
#             ValueFromPipelineByPropertyName = $true,
#             HelpMessage = 'Use this switch to install the Microsoft RSAT suite of tools. This includes the Active Directory module which is not available in the PowerShell Gallery.'
#         )]
#         [Alias('rsat')]
#         [switch]$RSATTools
#     )
    
#     begin {

#     }

#     process {
#         if ($PSCmdlet.ShouldProcess("$_", "Importing/Installing modules...")) {
#             if ($PublicModules) {
#                 foreach ($Module in $PublicModules) {
#                     Install-ModuleIfNotPresent -ModuleName $Module -Repository 'PSGallery'
#                 }
#             }

#             if ($InternalModules) {
#                 foreach ($Module in $InternalModules) {
#                     Install-ModuleIfNotPresent -ModuleName $Module -Repository $InternalGalleryName
#                 }
#             }

#             if ($RSATTools) {
#                 try {
#                     if ((Get-Module -Name 'ActiveDirectory' -ListAvailable)) {
#                         Write-Verbose "Importing module - ActiveDirectory"
#                         Import-Module -Name 'ActiveDirectory'
#                     }
#                     else {
#                         Write-Verbose "Installing module - RSAT Tools"
#                         Get-WindowsCapability -Name "Rsat*" -Online | Add-WindowsCapability -Online
#                         Import-Module -Name 'ActiveDirectory'
#                     }
#                 }
#                 catch {
#                     Write-Error -Message $_.Exception.Message
#                 }
#             }
#         }
#     }

#     end {
#         ForEach-Object -InputObject $PublicModules -Process {
#             Get-Module -Name $_
#         }
#     }
# }