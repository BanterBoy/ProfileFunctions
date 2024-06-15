function ArgumentCompleterExamples {
[Parameter(ParameterSetName = 'Default',
	Mandatory = $true,
	ValueFromPipeline = $true,
	ValueFromPipelineByPropertyName = $true,
	HelpMessage = 'Select the Exchange Server to connect to. This is a random server from the site you are in. If you want to connect to a specific server, you can tab complete the server name and cycle through the list of servers in your site. This is a mandatory parameter.')]
[ArgumentCompleter( {
		$Exchange = Get-ExchangeServerInSite
		$Servers = Get-Random -InputObject $Exchange -Shuffle:$true
		foreach ($Server in $Servers) {
			$Server.FQDN
		}
	}) ]
[Alias('server')]
[string]$ComputerName

}
function ChatGet-SpoolerService {
function Get-SpoolerService {
    Get-Service -Name Spooler
}

function Set-SpoolerServiceStatus {
    [CmdletBinding(DefaultParameterSetName = 'Default',
        HelpUri = 'https://github.com/BanterBoy',
        SupportsShouldProcess = $true)]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Computer,
        [Parameter(Mandatory = $true)]
        [string]$Status,
        [Parameter(Mandatory = $true)]
        [System.ServiceProcess.ServiceController]$SpoolerService
    )

    switch ($Status) {
        'Running' {
            if ($SpoolerService.Status -ne 'Running') {
                if ($PSCmdlet.ShouldProcess("$Computer", "Start Spooler service")) {
                    $SpoolerService | Start-Service
                    Write-Output "Started Spooler service on $Computer"
                }
            }
        }
        'Stopped' {
            if ($SpoolerService.Status -ne 'Stopped') {
                if ($PSCmdlet.ShouldProcess("$Computer", "Stop Spooler service")) {
                    $SpoolerService | Stop-Service
                    Write-Output "Stopped Spooler service on $Computer"
                }
            }
        }
        'Disabled' {
            if ($SpoolerService.StartType -ne 'Disabled') {
                if ($PSCmdlet.ShouldProcess("$Computer", "Disable Spooler service")) {
                    $SpoolerService | Set-Service -StartupType Disabled
                    Write-Output "Disabled Spooler service on $Computer"
                }
            }
        }
        'Enabled' {
            if ($SpoolerService.StartType -eq 'Disabled') {
                if ($PSCmdlet.ShouldProcess("$Computer", "Enable Spooler service")) {
                    $SpoolerService | Set-Service -StartupType Automatic
                    Write-Output "Enabled Spooler service on $Computer"
                }
            }
        }
    }
}

function Set-PrintSpoolerConfig {
    [CmdletBinding(DefaultParameterSetName = 'Default',
        HelpUri = 'https://github.com/BanterBoy',
        SupportsShouldProcess = $true)]
    [OutputType([string])]
    param
    (
        [Parameter(ParameterSetName = 'Default',
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Enter computer name or pipe input')]
        [Alias('cn')]
        [string[]]$ComputerName,

        [Parameter(ParameterSetName = 'Default',
            Mandatory = $true,
            HelpMessage = 'Enter desired status of the Print Spooler service')]
        [ValidateSet('Running', 'Stopped', 'Disabled', 'Enabled')]
        [string]$Status
    )

    PROCESS {

        foreach ($Computer in $ComputerName) {
            try {
                $localComputerName = [System.Environment]::MachineName
                if ($localComputerName -eq $Computer) {
                    # Run the command locally
                    $spoolerService = Get-SpoolerService
                    Set-SpoolerServiceStatus -Computer $Computer -Status $Status -SpoolerService $spoolerService
                }
                else {
                    # Run the command remotely
                    Invoke-Command -ComputerName $Computer -ScriptBlock {
                        $spoolerService = Get-SpoolerService
                        Set-SpoolerServiceStatus -Computer $using:Computer -Status $using:Status -SpoolerService $spoolerService
                    }
                }
            }
            catch {
                Write-Error "Failed to set Print Spooler service status on ${Computer}: $_"
            }
        }
    }
}
}
function Connect-Office365Services {
<#
    .SYNOPSIS
    Connect-Office365Services

    PowerShell script defining functions to connect to Office 365 online services
    or Exchange On-Premises. Call manually or alternatively embed or call from $profile
    (Shell or ISE) to make functions available in your session. If loaded from
    PowerShell_ISE, menu items are defined for the functions. To surpress creation of
    menu items, hold 'Shift' while Powershell ISE loads.

    Michel de Rooij
    michel@eightwone.com
    http://eightwone.com

    THIS CODE IS MADE AVAILABLE AS IS, WITHOUT WARRANTY OF ANY KIND. THE ENTIRE
    RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER.

    Version 3.15, August 16th 2023

    Get latest version from GitHub:
    https://github.com/michelderooij/Connect-Office365Services

    KNOWN LIMITATIONS:
    - When specifying PSSessionOptions for Modern Authentication, authentication fails (OAuth).
      Therefor, no PSSessionOptions are used for Modern Authentication.
           
    .DESCRIPTION
    The functions are listed below. Note that functions may call eachother, for example to
    connect to Exchange Online the Office 365 Credentials the user is prompted to enter these credentials.
    Also, the credentials are persistent in the current session, there is no need to re-enter credentials
    when connecting to Exchange Online Protection for example. Should different credentials be required,
    call Get-Office365Credentials or Get-OnPremisesCredentials again. 

    Helper Functions:
    =================
    - Connect-AzureActiveDirectory  Connects to Azure Active Directory
    - Connect-AzureRMS              Connects to Azure Rights Management
    - Connect-ExchangeOnline        Connects to Exchange Online (Graph module)
    - Connect-SkypeOnline           Connects to Skype for Business Online
    - Connect-AIP                   Connects to Azure Information Protection
    - Connect-PowerApps             Connects to PowerApps
    - Connect-ComplianceCenter      Connects to Compliance Center
    - Connect-SharePointOnline      Connects to SharePoint Online
    - Connect-MSTeams               Connects to Microsoft Teams
    - Get-Office365Credentials      Gets Office 365 credentials
    - Connect-ExchangeOnPremises    Connects to Exchange On-Premises
    - Get-OnPremisesCredentials     Gets On-Premises credentials
    - Get-ExchangeOnPremisesFQDN    Gets FQDN for Exchange On-Premises
    - Get-Office365Tenant           Gets Office 365 tenant name
    - Set-Office365Environment	    Configures Uri's and region to use
    - Update-Office365Modules       Updates supported Office 365 modules
    - Report-Office365Modules       Report on known vs online module versions

    Functions to connect to other services provided by the module, e.g. Connect-MSGraph or Connect-MSTeams.

    To register the PowerShell Test Gallery and install modules from there, use:
    Register-PSRepository -Name PSGalleryInt -SourceLocation https://www.poshtestgallery.com/ -InstallationPolicy Trusted
    Install-Module -Name MicrosoftTeams -Repository PSGalleryInt -Force -Scope AllUsers

    To load the helper functions from your PowerShell profile, put Connect-Office365Services.ps1 in the same location
    as your $profile file, and edit $profile as follows:
    & (Join-Path $PSScriptRoot "Connect-Office365Services.ps1")

    .HISTORY
    1.2     Community release
    1.3     Updated required version of Online Sign-In Assistant
    1.4     Added (in-code) AzureEnvironment (Connect-AzureAD)
            Added version reporting for modules
    1.5     Added support for Exchange Online PowerShell module w/MFA
            Added IE proxy config support
            Small cosmetic changes in output
    1.51    Fixed PSSession for non-MFA EXO logons
            Changed credential entering logic for MFA
    1.6     Added support for the Skype for Business PowerShell module w/MFA
            Added support for the SharePoint Online PowerShell module w/MFA
    1.61    Fixed MFA choice bug
    1.7     Added AzureAD PowerShell Module support
            For disambiguation, renamed Connect-AzureAD to Connect-AzureActiveDirectory
    1.71    Added AzureADPreview PowerShell Module Support
    1.72    Changed credential non-prompting condition for AzureAD
    1.75    Added support for MFA-enabled Security & Compliance Center
            Added module version checks (online when possible) setting OnlineModuleVersionChecks
            Switched AzureADv1 to PS gallery version
            Removed Sign-In Assistant checks
            Added Set-Office365Environment to switch to other region, e.g. Germany, China etc.
    1.76    Fixed version number checks for SfB & SP
    1.77    Fixed version number checks for determining MFA status
            Changed default for online version checks to $false
    1.78    Added usage of most recently dated ExO MFA module found (in case multiple are found)
            Changed connecting to SCC with MFA to using the underlying New-ExO cmdlet
    1.80    Added Microsoft Teams PowerShell Module support
            Added Connect-MSTeams function
            Cleared default PSSessionOptions
            Some code rewrite (splatting)
    1.81    Added support for ExO module 16.00.2020.000 w/MFA -Credential support
    1.82    Bug fix SharePoint module version check
    1.83    Removed Credentials option for ExO/MFA connect
    1.84    Added Exchange ADAL loading support
    1.85    Fixed menu creation in ISE
    1.86    Updated version check for AzureADPreview (2.0.0.154)
            Added automatic module updating (Admin mode, OnlineModuleAutoUpdate & OnlineModuleVersionChecks)
    1.87    Small bug fixes in outdated logic
            Added showing OnlineChecks/AutoUpdate/IsAdmin info
    1.88    Updated module updating routine
            Updated SkypeOnlineConnector reference (PSGallery)
            Updated versions for Teams
    1.89    Reverted back to installable SkypeOnlineConnector
    1.90    Updated info for Azure Active Directory Preview module
            Updated info for Exchange Online Modern Authentication module
            Renamed 'Multi-Factor Authentication' to 'Modern Authentication'
    1.91    Updated info for SharePoint Online module
            Fixed removal of old module(s) when updating
    1.92    Updated AzureAD module 2.0.1.6
    1.93    Updated Teams module 0.9.3
            Fixed typo in uninstall of old module when upgrading
    1.94    Moved all global vars into one global hashtable (myOffice365Services)
            Updated AzureAD preview info (v2.0.1.11)
            Updated AzureAD info (v2.0.1.10)
    1.95    Fixed version checking issue in Get-Office365Credentials
    1.96    Updated AzureADv1 (MSOnline) info (v1.1.183.8)
            Fixed Skype & SharePoint Module version checking in Get-Office365Credentials()
    1.97    Updated AzureAD Preview info (v2.0.1.17)
    1.98    Updated Exchange Online info (16.0.2440.0)
            Updated AzureAD Preview info (v2.0.1.18)
            Updated AzureAD info (v2.0.1.16)
            Fixed Azure RMS location + info (v2.13.1.0)
            Added SharePointPnP Online (detection only)
    1.98.1  Fixed Connect-ComplianceCenter function
    1.98.2  Updated Exchange Online info (16.0.2433.0 - 2440 seems pulled)
            Added x86 notice (not all modules available for x86 platform)
    1.98.3  Updated Exchange Online info (16.00.2528.000)
            Updated SharePoint Online info (v16.0.8029.0)
            Updated Microsoft Online info (1.1.183.17)
    1.98.4  Updated AzureAD Preview info (2.0.2.3)
            Updated SharePoint Online info (16.0.8119.0)
            Updated Exchange Online info (16.00.2603.000)
            Updated MSOnline info (1.1.183.17)
            Updated AzureAD info (2.2.2.2)
            Updated SharePointPnP Online info (3.1.1809.0)
    1.98.5  Added display of Tenant ID after providing credentials
    1.98.6  Updated Teams info (0.9.5)
            Updated AzureAD Preview info (2.0.2.5)
            Updated SharePointPnP Online info (3.2.1810.0)
    1.98.7  Modified Module Updating routing
    1.98.8  Updated SharePoint Online info (16.0.8212.0)
            Added changing console title to Tenant info
            Rewrite initializing to make it manageable from profile
    1.98.81 Updated Exchange Online info (16.0.2642.0)
    1.98.82 Updated AzureAD info (2.0.2.4)
            Updated MicrosoftTeams info (0.9.6)
            Updated SharePoint Online info (16.0.8525.1200)
            Revised module auto-updating
    1.98.83 Updated Teams info (1.0.0)
            Updated AzureAD v2 Preview info (2.0.2.17)
            Updated SharePoint Online info (16.0.8715.1200)
    1.98.84 Updated Skype for Business Online info (7.0.1994.0)
    1.98.85 Updated SharePoint Online info (16.0.8924.1200)
            Fixed setting Tenant Name for Connect-SharePointOnline
    1.99.86 Updated Exchange Online info (16.0.3054.0)
    1.99.87 Replaced 'not detected' with 'not found' for esthetics
    1.99.88 Replaced AADRM module functionality with AIPModule
            Updated AzureAD v2 info (2.0.2.31)
            Added PowerApps modules (preview)
            Fixed handling when ExoPS module isn't installed
    1.99.89 Updated AzureAD v2 Preview info (2.0.2.32)
            Updated SPO Online info (16.0.9119.1200)
            Updated Teams info (1.0.1)
    1.99.90 Added Microsoft.Intune.Graph module
            Updated AzureAD v2 info (2.0.2.50)
            Updated AzureAD v2 Preview info (2.0.2.51)
            Updated SharePoint Online info (16.0.19223.12000)
            Updated MSTeams info (1.0.2)
    1.99.91 Updated Exchange Online info (16.0.3346.0)
            Updated AzureAD v2 info (2.0.2.52)
            Updated AzureAD v2 Preview info (2.0.2.53)
            Updated SharePoint Online info (16.0.19404.12000)
    1.99.92 Updated SharePoint Online info (16.0.19418.12000)
    2.00    Added Exchange Online Management v2 (0.3374.4)
    2.10    Added Update-Office365Modules 
            Updated MSOnline info (1.1.183.57)
            Updated AzureAD v2 info (2.0.2.61)
            Updated AzureAD v2 Preview info (2.0.2.62)
            Updated PowerApps-Admin-PowerShell info (2.0.21)
    2.11    Added MSTeams info from Test Gallery (1.0.18)
            Updated MSTeams info (1.0.3)
            Updated PowerApps-Admin-PowerShell info (2.0.24)
    2.12    Fixed module processing bug
            Added module upgrading with 'AcceptLicense' switch
    2.13    Removed OnlineAutoUpdate option
            Added notice to use Update-Office365Modules
            Fixed updating of binary modules
            Updated ExchangeOnlineManagement v2 info (0.3374.9)
            Splash header cosmetics
    2.14    Fixed bug in Update-Office365Modules
    2.15    Fixed module detection installed side-by-side
    2.20    Updated ExchangeOnlineManagement v2 info (0.3374.10)
            Updated Azure AD v2 info (2.0.2.76)
            Updated Azure AD v2 Preview info (2.0.2.77)
            Updated SharePoiunt Online info (16.0.19515.12000)
            Updated Update-Office365Modules detection logic
            Updated Update-Office365Modules to skip non-repo installed modules
    2.21    Updated ExchangeOnlineManagement v2 info (0.3374.11)
            Updated PowerApps-Admin-PowerShell info (2.0.34)
            Updated SharePoint PnP Online info (3.17.2001.2)
    2.22    Updated ExchangeOnlineManagement v2 info (0.3555.1)
            Updated MSTeams (Test) info (1.0.19)
    2.23    Added PowerShell Graph module (0.1.1) 
            Updated Exchange Online info (16.00.3527.000)
            Updated SharePoint Online info (16.0.19724.12000)
    2.24    Updated ExchangeOnlineManagement v2 info (0.3582.0)
            Updated Microsoft Teams (Test) info (1.0.20)
            Added Report-Office365Modules to report on known vs online versions
    2.25    Updated Microsoft Teams info (1.0.5)
            Updated Azure AD v2 Preview info (2.0.2.85)
            Updated SharePoint Online info (16.0.19814.12000)
            Updated MSTeams (Test) info (1.0.21)
            Updated SharePointPnP Online (3.19.2003.0)
            Updated PowerApps-Admin-PowerShell (2.0.45)
            Updated PowerApps-PowerShell (1.0.9)
            Updated Report-Office365Modules (cosmetic, repository checks)
            Improved loading speed a bit (for repository checks)
    2.26    Added setting Window title to include current account
    2.27    Updated ExchangeOnlineManagement to v0.4578.0
            Updated Azure AD v2 Preview info (2.0.2.89)
            Updated Azure Information Protection info (1.0.0.2)
            Updated SharePoint Online info (16.0.20017.12000)
            Updated MSTeams (Test) info (1.0.22)
            Updated SharePointPnP Online info (3.20.2004.0)
            Updated PowerApps-Admin-PowerShell info (2.0.60)
    2.28    Updated Azure AD v2 Preview info (2.0.2.102)
            Updated SharePointPnP Online info (3.21.2005.1)
            Updated PowerApps-Admin-PowerShell info (2.0.63)
    2.29    Updated Exchange Online Management v2 (1.0.1)
            Updated SharePoint Online (16.0.20122.12000)
            Updated SharePointPnP Online (3.21.2005.2)
            Updated PowerApps-Admin-PowerShell (2.0.64)
            Updated PowerApps-PowerShell (1.0.13)
    2.30    Updated Exchange Online Management Pre-release (2.0.3)
            Updated Azure Active Directory (v2) (2.0.2.104)
            Updated SharePoint Online updated to (16.0.20212.12000)
            Updated Microsoft Teams (Test) (1.0.25)
            Updated Microsoft Teams (2.0.7)
            Updated SharePointPnP Online (3.22.2006.2)
            Updated PowerApps-Admin-PowerShell (2.0.66)
            Updated Microsoft.Graph (0.7.0)
            Added pre-release modules support
    2.31    Added Microsoft.Graph.Teams.Team module
            Updated Azure Active Directory (v2 Preview) (2.0.2.105)
            Updated PowerApps-Admin-PowerShell (2.0.67)
    2.32    Updated Exchange Online info (16.0.3724.0)
            Updated Azure AD (v2) (2.0.2.106)
            Updated SharePoint PnP Online (2.0.72)
            Updated Microsoft Teams (GA) (1.1.4)
            Updated SharePoint PnP Online (3.23.2007.1)
            Updated PowerApps-Admin-PowerShell (2.0.72)
    2.40    Added code to detect Exchange Online module version
            Added code to update Exchange Online module
            Speedup loading by skipping version checks (use Report-Office365Modules & Update-Office365Modules)
            Only online version checks are performed (removes 'offline' version data)
            Some visual cosmetics and simplifications
    2.41    Made Elevated check language-independent
    2.42    Fixed bugs in reporting on and updating modules 
            Cosmetics when reporting
    2.43    Added support for MSCommerce
    2.44    Fixed unneeded update of module in Update-Office365Modules
            Slightly speed up updating and reporting routine
    2.45    Improved loading speed by collecting Module information once
            Added AllowPrerelease to uninstall-module operation
    2.5     Switched to using PowerShellGet 2.x cmdlets (Get-InstalledModule) for performance
            Added mention of PowerShell, PowerShellGet and PackageManagement version in header
            Removed InternetAccess mention in header
    2.51    Added ConvertTo-SystemVersion helper function to deal with N.N-PreviewN
    2.52    Added NoClobber and AcceptLicense to update
    2.53    Fixed reporting of installed verion during update
    2.54    Improved module updating
    2.55    Fixed updating updating module when it's loaded
            Fixed removal of old modules logic (.100 is newer than .81)
            Set default response of MFA question to Yes
    2.56    Added PowerShell 7.x support (rewrite of some module management calls)
    2.57    Corrected SessionOption to PSSessionOption for Connect-ExchangeOnline (@ladewig)
    2.58    Replaced web call to retrieve tenant ID with much quicker REST call 
    2.60    Changes due to Skype Online Connector retirement per 15Feb2021 (use MSTeams instead)
            Changes due to deprecation of ExoPowershellModule (use EXOPSv2 instead)
            Connect-ExchangeOnline will use ExchangeOnlineManagement
            Removed obsolete Connect-ExchangeOnlinev2 helper function
            Replaced variable-substitution strings "$(..)" with -f formatted versions
            Replaced aliases with full verbs. Happy PSScriptAnalyzer :)
            Due to removal of non-repository module checks, significant loading speed reduction.
    2.61    Updated connecting to EOP and S&C center using EXOPSv2 module
            Removed needless passing of AzureADAuthorizationEndpointUri when specifying UserPrincipalName
    2.62    Added -ProxyAccessType AutoDetect to default SessionOptions
    2.63    Changed default ProxyAccessType to None
    2.64    Structured Connect-MsTeams
    2.65    Fixed connecting to AzureAD using MFA not using provided Username
    2.66    Reporting change in #cmdlets after updating
    2.70    Added support for all overloaded Connect-ExchangeOnline parameters from ExchangeOnlineManagement module 
            Added PnP.PowerShell module support
            Removed SharePointPnPPowerShellOnline support
            Removed obsolete code for MFA module presence check
            Updated AzureADAuthorizationEndpointUri for Common/GCC
    2.71    Revised module updating using Install-Package when available
    2.80    Improved version handling to properly evaluate Preview modules
            Fixed updating module using install-package when existing package comes from different repo
            Versions reported are now showing their textual representation, including tags like PreviewX
            Report-Office365Modules output is now more condense
    2.90    Added MSCommerce module
            Added MicrosoftPowerBIMgmt module
            Added Az module
    2.91    Removed Microsoft.Graph.Teams.Team module (unlisted at PSGallery)
    2.92    Removed duplicate MSCommerce checking
    2.93    Added cleaning up of module dependencies (e.g. Az)
            Updating will use same scope of installed module
            Showing warning during update when running multiple PowerShell sessions
    2.94    Added AllowClubber to ignore existing cmdlet conflicts when updating modules
    2.95    Added UseRPSSession switch for Connect-ExchangeOnline
    2.96    Added Microsoft36DSC module
            Fixed determing current module scope (CurrentUser/AllUsers)
    2.97    Fixed title for admin roles
    2.98    Fixed ConnectionUri in EXO connection method
    2.99    Added 2 connect helper functions to description
    3.00    Fixed wrongly detecting old modules because mixed native PS module and PSGet cmdlets
            Back to using native PS module management cmdlets
            Some cosmetics
            Startup only reports installed modules, not "not installed"
            Report now also reports not installed modules
            Removed PSGet check 
    3.01    Added Preview info when reporting local module info
    3.10    Removed Microsoft Teams (Test) support (from poshtestgallery)
            Renamed Azure AD v1 to MSOnline to prevent confusion
            Added support for WhiteboardAdmin
            Added support for MSIdentityTools
    3.11    Fixed header not displaying correction script version
    3.12    Replaced 'Prerelease' questions with switch - specify if you want, otherwise default is unspecified (=GA)
    3.13    Added ORCA to set of supported modules
    3.14    Added O365CentralizedAddInDeployment to set of supported modules
    3.15    Fixed creating ISE menu options for local functions
            Removed Connect-EOP
#>

#Requires -Version 3.0
$local:ScriptVersion = '3.15'

function global:Set-WindowTitle {
    If ( $host.ui.RawUI.WindowTitle -and $global:myOffice365Services['TenantID']) {
        $local:PromptPrefix = ''
        $ThisPrincipal = new-object System.Security.principal.windowsprincipal( [System.Security.Principal.WindowsIdentity]::GetCurrent())
        if ( $ThisPrincipal.IsInRole( [Security.Principal.WindowsBuiltInRole]::Administrator)) { 
            $local:PromptPrefix = 'Administrator:'
        }
        $local:Title = '{0}{1} connected to Tenant ID {2}' -f $local:PromptPrefix, $myOffice365Services['Office365Credentials'].UserName, $global:myOffice365Services['TenantID']
        $host.ui.RawUI.WindowTitle = $local:Title
    }
}

function global:Get-TenantIDfromMail {
    param(
        [string]$mail
    )
    $domainPart = ($mail -split '@')[1]
    If ( $domainPart) {
        $res = (Invoke-RestMethod -Uri ('https://login.microsoftonline.com/{0}/v2.0/.well-known/openid-configuration' -f $domainPart)).jwks_uri.split('/')[3]
        If (!( $res)) {
            Write-Warning 'Could not determine Tenant ID using e-mail address'
            $res = $null
        }
    }
    Else {
        Write-Warning 'E-mail address invalid, cannot determine Tenant ID'
        $res = $null
    }
    return $res
}

function global:Get-TenantID {
    $global:myOffice365Services['TenantID'] = Get-TenantIDfromMail $myOffice365Services['Office365Credentials'].UserName
    If ( $global:myOffice365Services['TenantID']) {
        Write-Host ('TenantID: {0}' -f $global:myOffice365Services['TenantID'])
    }
}

function global:Get-Office365ModuleInfo {
    # Menu | Submenu | Menu ScriptBlock | ModuleName | Description | (Repo)Link 
    @(
        'Connect|Exchange Online|Connect-ExchangeOnline|ExchangeOnlineManagement|Exchange Online Management|https://www.powershellgallery.com/packages/ExchangeOnlineManagement',
        'Connect|Exchange Security & Compliance Center|Connect-ComplianceCenter|ExchangeOnlineManagement|Exchange Online Management|https://www.powershellgallery.com/packages/ExchangeOnlineManagement',
        'Connect|MSOnline|Connect-MSOnline|MSOnline|MSOnline|https://www.powershellgallery.com/packages/MSOnline',
        'Connect|Azure AD (v2)|Connect-AzureAD|AzureAD|Azure Active Directory (v2)|https://www.powershellgallery.com/packages/azuread',
        'Connect|Azure AD (v2 Preview)|Connect-AzureAD|AzureADPreview|Azure Active Directory (v2 Preview)|https://www.powershellgallery.com/packages/AzureADPreview',
        'Connect|Azure Information Protection|Connect-AIP|AIPService|Azure Information Protection|https://www.powershellgallery.com/packages/AIPService',
        'Connect|SharePoint Online|Connect-SharePointOnline|Microsoft.Online.Sharepoint.PowerShell|SharePoint Online|https://www.powershellgallery.com/packages/Microsoft.Online.SharePoint.PowerShell',
        'Connect|Microsoft Teams|Connect-MSTeams|MicrosoftTeams|Microsoft Teams|https://www.powershellgallery.com/packages/MicrosoftTeams',
        'Connect|Microsoft Commerce|Connect-MSCommerce|MSCommerce|Microsoft Commerce|https://www.powershellgallery.com/packages/MSCommerce',
        'Connect|PnP.PowerShell|Connect-PnPOnline|PnP.PowerShell|PnP.PowerShell|https://www.powershellgallery.com/packages/PnP.PowerShell',
        'Connect|PowerApps-Admin-PowerShell|Connect-PowerApps|Microsoft.PowerApps.Administration.PowerShell|PowerApps-Admin-PowerShell|https://www.powershellgallery.com/packages/Microsoft.PowerApps.Administration.PowerShell',
        'Connect|PowerApps-PowerShell|Connect-PowerApps|Microsoft.PowerApps.PowerShell|PowerApps-PowerShell|https://www.powershellgallery.com/packages/Microsoft.PowerApps.PowerShell',
        'Connect|MSGraph-Intune|Connect-MSGraph|Microsoft.Graph.Intune|MSGraph-Intune|https://www.powershellgallery.com/packages/Microsoft.Graph.Intune',
        'Connect|Microsoft.Graph|Connect-MSGraph|Microsoft.Graph|Microsoft.Graph|https://www.powershellgallery.com/packages/Microsoft.Graph',
        'Connect|MicrosoftPowerBIMgmt|Connect-PowerBIServiceAccount|MicrosoftPowerBIMgmt|MicrosoftPowerBIMgmt|https://www.powershellgallery.com/packages/MicrosoftPowerBIMgmt',
        'Connect|Az|Connect-AzAccount|Az|Az|https://www.powershellgallery.com/packages/Az',
        'Connect|Microsoft365DSC|New-M365DSCConnection|Microsoft365DSC|Microsoft365DSC|https://www.powershellgallery.com/packages/Microsoft36DSC',
        'Connect|Whiteboard|Get-Whiteboard|WhiteboardAdmin|WhiteboardAdmin|https://www.powershellgallery.com/packages/WhiteboardAdmin',
        'Connect|Microsoft Identity|Connect-MgGraph|MSIdentityTools|MSIdentityTools|https://www.powershellgallery.com/packages/MSIdentityTools',
        'Connect|Microsoft Identity|Connect-OrganizationAddInService|O365CentralizedAddInDeployment|O365 Centralized Add-In Deployment Module|https://www.powershellgallery.com/packages/O365CentralizedAddInDeployment',
        'Report|ORCA|Get-ORCAReport|ORCA|Office 365 Recommended Configuration Analyzer (ORCA)|https://www.powershellgallery.com/packages/ORCA',
        'Settings|Office 365 Credentials|Get-Office365Credentials',
        'Connect|Exchange On-Premises|Connect-ExchangeOnPremises',
        'Settings|On-Premises Credentials|Get-OnPremisesCredentials',
        'Settings|Exchange On-Premises FQDN|Get-ExchangeOnPremisesFQDN'
    )
}

function global:Set-Office365Environment {
    param(
        [ValidateSet('Germany', 'China', 'AzurePPE', 'USGovernment', 'Default')]
        [string]$Environment
    )
    Switch ( $Environment) {
        'Germany' {
            $global:myOffice365Services['ConnectionEndpointUri'] = 'https://outlook.office.de/PowerShell-LiveID'
            $global:myOffice365Services['SCCConnectionEndpointUri'] = 'https://ps.compliance.protection.outlook.de/PowerShell-LiveId'
            $global:myOffice365Services['EOPConnectionEndpointUri'] = 'https://ps.protection.protection.outlook.de/PowerShell-LiveId'
            $global:myOffice365Services['AzureADAuthorizationEndpointUri'] = 'https://login.microsoftonline.de/common'
            $global:myOffice365Services['SharePointRegion'] = 'Germany'
            $global:myOffice365Services['AzureEnvironment'] = 'AzureGermanyCloud'
            $global:myOffice365Services['TeamsEnvironment'] = ''
        }
        'China' {
            $global:myOffice365Services['ConnectionEndpointUri'] = 'https://partner.outlook.cn/PowerShell-LiveID'
            $global:myOffice365Services['SCCConnectionEndpointUri'] = 'https://ps.compliance.protection.outlook.com/PowerShell-LiveId'
            $global:myOffice365Services['EOPConnectionEndpointUri'] = 'https://ps.protection.protection.outlook.com/PowerShell-LiveId'
            $global:myOffice365Services['AzureADAuthorizationEndpointUri'] = 'https://login.chinacloudapi.cn/common'
            $global:myOffice365Services['SharePointRegion'] = 'China'
            $global:myOffice365Services['AzureEnvironment'] = 'AzureChinaCloud'
            $global:myOffice365Services['TeamsEnvironment'] = ''
        }
        'AzurePPE' {
            $global:myOffice365Services['ConnectionEndpointUri'] = ''
            $global:myOffice365Services['SCCConnectionEndpointUri'] = 'https://ps.compliance.protection.outlook.com/PowerShell-LiveId'
            $global:myOffice365Services['EOPConnectionEndpointUri'] = 'https://ps.protection.protection.outlook.com/PowerShell-LiveId'
            $global:myOffice365Services['AzureADAuthorizationEndpointUri'] = ''
            $global:myOffice365Services['SharePointRegion'] = ''
            $global:myOffice365Services['AzureEnvironment'] = 'AzurePPE'
        }
        'USGovernment' {
            $global:myOffice365Services['ConnectionEndpointUri'] = 'https://outlook.office365.com/PowerShell-LiveId'
            $global:myOffice365Services['SCCConnectionEndpointUri'] = 'https://ps.compliance.protection.outlook.com/PowerShell-LiveId'
            $global:myOffice365Services['EOPConnectionEndpointUri'] = 'https://ps.protection.protection.outlook.com/PowerShell-LiveId'
            $global:myOffice365Services['AzureADAuthorizationEndpointUri'] = 'https://login.microsoftonline.com/common'
            $global:myOffice365Services['SharePointRegion'] = 'ITAR'
            $global:myOffice365Services['AzureEnvironment'] = 'AzureUSGovernment'
        }
        default {
            $global:myOffice365Services['ConnectionEndpointUri'] = 'https://outlook.office365.com/PowerShell-LiveId'
            $global:myOffice365Services['SCCConnectionEndpointUri'] = 'https://ps.compliance.protection.outlook.com/PowerShell-LiveId'
            $global:myOffice365Services['EOPConnectionEndpointUri'] = 'https://ps.protection.protection.outlook.com/PowerShell-LiveId'
            $global:myOffice365Services['AzureADAuthorizationEndpointUri'] = 'https://login.microsoftonline.com/common'
            $global:myOffice365Services['SharePointRegion'] = 'Default'
            $global:myOffice365Services['AzureEnvironment'] = 'AzureCloud'
        }
    }
}

function global:Get-MultiFactorAuthenticationUsage {
    $Answer = Read-host  -Prompt 'Would you like to use Modern Authentication? (Y/n) '
    Switch ($Answer.ToUpper()) {
        'N' { $rval = $false }
        Default { $rval = $true }
    }
    return $rval
}

function global:Get-ExchangeOnlineClickOnceVersion {
    Try {
        $ManifestURI = 'https://cmdletpswmodule.blob.core.windows.net/exopsmodule/Microsoft.Online.CSE.PSModule.Client.application'
        $res = Invoke-WebRequest -Uri $ManifestURI -UseBasicParsing
        $xml = [xml]($res.rawContent.substring( $res.rawContent.indexOf('<?xml')))
        $xml.assembly.assemblyIdentity.version
    }
    Catch {
        Write-Error 'Cannot access or determine version of Microsoft.Online.CSE.PSModule.Client.application'
    }
}

function global:Connect-ExchangeOnline {
    [CmdletBinding()]
    Param(
        [string]$ConnectionUri,
        [string]$AzureADAuthorizationEndpointUri,
        [System.Management.Automation.Remoting.PSSessionOption]$PSSessionOption,
        [switch]$BypassMailboxAnchoring = $false,
        [string]$DelegatedOrganization,
        [string]$Prefix,
        [switch]$ShowBanner = $False,
        [string]$UserPrincipalName,
        [System.Management.Automation.PSCredential]$Credential,
        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate,
        [string]$CertificateFilePath,
        [System.Security.SecureString]$CertificatePassword,
        [string]$CertificateThumbprint,
        [string]$AppId,
        [string]$Organization,
        [switch]$EnableErrorReporting,
        [string]$LogDirectoryPath,
        $LogLevel,
        [bool]$TrackPerformance,
        [bool]$ShowProgress = $True,
        [bool]$UseMultithreading,
        [uint32]$PageSize,
        [switch]$Device,
        [switch]$InlineCredential,
        [string[]]$CommandName = @("*"),
        [string[]]$FormatTypeName = @("*"),
        [switch]$UseRPSSession = $false
    )
    if (!( $PSBoundParameters.ContainsKey('ConnectionUri'))) {
        $PSBoundParameters['ConnectionUri'] = $global:myOffice365Services['ConnectionEndpointUri']
    }
    if (!( $PSBoundParameters.ContainsKey('AzureADAuthorizationEndpointUri'))) {
        $PSBoundParameters['AzureADAuthorizationEndpointUri'] = $global:myOffice365Services['AzureADAuthorizationEndpointUri']
    }
    if (!( $PSBoundParameters.ContainsKey('PSSessionOption'))) {
        $PSBoundParameters['PSSessionOption'] = $global:myOffice365Services['SessionExchangeOptions']
    }
    If ( $PSBoundParameters.ContainsKey('UserPrincipalName') -or $PSBoundParameters.ContainsKey('Certificate') -or $PSBoundParameters.ContainsKey('CertificateFilePath') -or $PSBoundParameters.ContainsKey('CertificateThumbprint') -or $PSBoundParameters.ContainsKey('AppId')) {
        $global:myOffice365Services['Office365CredentialsMFA'] = $True
        Write-Host ('Connecting to Exchange Online with specified Modern Authentication method ..')
    }
    Else {
        If ( $PSBoundParameters.ContainsKey('Credential')) {
            If ( !($global:myOffice365Services['Office365Credentials'])) { Get-Office365Credentials }
            If ( $global:myOffice365Services['Office365CredentialsMFA']) {
                Write-Host ('Connecting to Exchange Online with {0} using Modern Authentication ..' -f $global:myOffice365Services['Office365Credentials'].UserName)
                $PSBoundParameters['UserPrincipalName'] = ($global:myOffice365Services['Office365Credentials']).UserName
            }
            Else {
                Write-Host ('Connecting to Exchange Online with {0} ..' -f $global:myOffice365Services['Office365Credentials'].username)
                $PSBoundParameters['Credential'] = $global:myOffice365Services['Office365Credentials'] 
            }
        }
        Else {
            Write-Host ('Connecting to Exchange Online with {0} using Legacy Authentication..' -f $PSBoundParameters['Credential'].UserName)
            $global:myOffice365Services['Office365CredentialsMFA'] = $False
            $global:myOffice365Services['Office365Credentials'] = $PSBoundParameters['Credential']
        }
    }
    $global:myOffice365Services['Session365'] = ExchangeOnlineManagement\Connect-ExchangeOnline @PSBoundParameters
    If ( $global:myOffice365Services['Session365'] ) {
        Import-PSSession -Session $global:myOffice365Services['Session365'] -AllowClobber
    }
}

function global:Connect-ExchangeOnPremises {
    If ( !($global:myOffice365Services['OnPremisesCredentials'])) { Get-OnPremisesCredentials }
    If ( !($global:myOffice365Services['ExchangeOnPremisesFQDN'])) { Get-ExchangeOnPremisesFQDN }
    Write-Host ('Connecting to Exchange On-Premises {0} using {1} ..' -f $global:myOffice365Services['ExchangeOnPremisesFQDN'], $global:myOffice365Services['OnPremisesCredentials'].username)
    $global:myOffice365Services['SessionExchange'] = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri "http://$($global:myOffice365Services['ExchangeOnPremisesFQDN'])/PowerShell" -Credential $global:myOffice365Services['OnPremisesCredentials'] -Authentication Kerberos -AllowRedirection -SessionOption $global:myOffice365Services['SessionExchangeOptions']
    If ( $global:myOffice365Services['SessionExchange']) { Import-PSSession -Session $global:myOffice365Services['SessionExchange'] -AllowClobber }
}

Function global:Get-ExchangeOnPremisesFQDN {
    $global:myOffice365Services['ExchangeOnPremisesFQDN'] = Read-Host -Prompt 'Enter Exchange On-Premises endpoint, e.g. exchange1.contoso.com'
}

function global:Connect-IPPSession {
    If ( !($global:myOffice365Services['Office365Credentials'])) { Get-Office365Credentials }
    If ( $global:myOffice365Services['Office365CredentialsMFA']) {
        Write-Host ('Connecting to Security & Compliance Center using {0} with Modern Authentication ..' -f $global:myOffice365Services['Office365Credentials'].username)
        $global:myOffice365Services['SessionCC'] = ExchangeOnlineManagement\Connect-IPPSSession -ConnectionUri $global:myOffice365Services['SCCConnectionEndpointUri'] -UserPrincipalName ($global:myOffice365Services['Office365Credentials']).UserName -PSSessionOption $global:myOffice365Services['SessionExchangeOptions']
    }
    Else {
        Write-Host ('Connecting to Security & Compliance Center using {0} ..' -f $global:myOffice365Services['Office365Credentials'].username)
        $global:myOffice365Services['SessionCC'] = ExchangeOnlineManagement\Connect-IPPSSession -ConnectionUrl $global:myOffice365Services['SCCConnectionEndpointUri'] -Credential $global:myOffice365Services['Office365Credentials'] -PSSessionOption $global:myOffice365Services['SessionExchangeOptions']
    }
    If ( $global:myOffice365Services['SessionCC'] ) {
        Import-PSSession -Session $global:myOffice365Services['SessionCC'] -AllowClobber
    }
}


function global:Connect-MSTeams {
    If ( !($global:myOffice365Services['Office365Credentials'])) { Get-Office365Credentials }
    If ( $global:myOffice365Services['Office365CredentialsMFA']) {
        Write-Host ('Connecting to Microsoft Teams using {0} with Modern Authentication ..' -f $global:myOffice365Services['Office365Credentials'].username)
        Connect-MicrosoftTeams -AccountId ($global:myOffice365Services['Office365Credentials']).UserName -TenantId $myOffice365Services['TenantId']
    }
    Else {
        Write-Host ('Connecting to Exchange Online Protection using {0} ..' -f $global:myOffice365Services['Office365Credentials'].username)
        Connect-MicrosoftTeams -Credential $global:myOffice365Services['Office365Credentials']
    }
}

function global:Connect-SkypeOnline {
    If ( !($global:myOffice365Services['Office365Credentials'])) { Get-Office365Credentials }
    Write-Host ('Connecting to Skype Online using {0}' -f $global:myOffice365Services['Office365Credentials'].username)
    $global:myOffice365Services['SessionSFBO'] = New-CsOnlineSession -Credential $global:myOffice365Services['Office365Credentials']
    If ( $global:myOffice365Services['SessionSFBO'] ) {
        Import-PSSession -Session $global:myOffice365Services['SessionSFBO'] -AllowClobber
    }    
}

function global:Connect-AzureActiveDirectory {
    If ( !(Get-Module -Name AzureAD)) { Import-Module -Name AzureAD -ErrorAction SilentlyContinue }
    If ( !(Get-Module -Name AzureADPreview)) { Import-Module -Name AzureADPreview -ErrorAction SilentlyContinue }
    If ( (Get-Module -Name AzureAD) -or (Get-Module -Name AzureADPreview)) {
        If ( !($global:myOffice365Services['Office365Credentials'])) { Get-Office365Credentials }
        If ( $global:myOffice365Services['Office365CredentialsMFA']) {
            Write-Host 'Connecting to Azure Active Directory with Modern Authentication ..'
            $Parms = @{AccountId = $global:myOffice365Services['Office365Credentials'].UserName; AzureEnvironment = $global:myOffice365Services['AzureEnvironment'] }
        }
        Else {
            Write-Host ('Connecting to Azure Active Directory using {0} ..' -f $global:myOffice365Services['Office365Credentials'].username)
            $Parms = @{'Credential' = $global:myOffice365Services['Office365Credentials']; 'AzureEnvironment' = $global:myOffice365Services['AzureEnvironment'] }
        }
        Connect-AzureAD @Parms
    }
    Else {
        If ( !(Get-Module -Name MSOnline)) { Import-Module -Name MSOnline -ErrorAction SilentlyContinue }
        If ( Get-Module -Name MSOnline) {
            If ( !($global:myOffice365Services['Office365Credentials'])) { Get-Office365Credentials }
            Write-Host ('Connecting to Azure Active Directory using {0} ..' -f $global:myOffice365Services['Office365Credentials'].username)
            Connect-MsolService -Credential $global:myOffice365Services['Office365Credentials'] -AzureEnvironment $global:myOffice365Services['AzureEnvironment']
        }
        Else { Write-Error -Message 'Cannot connect to Azure Active Directory - problem loading module.' }
    }
}

function global:Connect-AIP {
    If ( !(Get-Module -Name AIPService)) { Import-Module -Name AIPService -ErrorAction SilentlyContinue }
    If ( Get-Module -Name AIPService) {
        If ( !($global:myOffice365Services['Office365Credentials'])) { Get-Office365Credentials }
        Write-Host ('Connecting to Azure Information Protection using {0}' -f $global:myOffice365Services['Office365Credentials'].username)
        Connect-AipService -Credential $global:myOffice365Services['Office365Credentials'] 
    }
    Else { Write-Error -Message 'Cannot connect to Azure Information Protection - problem loading module.' }
}

function global:Connect-SharePointOnline {
    If ( !(Get-Module -Name Microsoft.Online.Sharepoint.PowerShell)) { Import-Module -Name Microsoft.Online.Sharepoint.PowerShell -ErrorAction SilentlyContinue }
    If ( Get-Module -Name Microsoft.Online.Sharepoint.PowerShell) {
        If ( !($global:myOffice365Services['Office365Credentials'])) { Get-Office365Credentials }
        If (($global:myOffice365Services['Office365Credentials']).username -like '*.onmicrosoft.com') {
            $global:myOffice365Services['Office365Tenant'] = ($global:myOffice365Services['Office365Credentials']).username.Substring(($global:myOffice365Services['Office365Credentials']).username.IndexOf('@') + 1).Replace('.onmicrosoft.com', '')
        }
        Else {
            If ( !($global:myOffice365Services['Office365Tenant'])) { Get-Office365Tenant }
        }
        If ( $global:myOffice365Services['Office365CredentialsMFA']) {
            Write-Host 'Connecting to SharePoint Online with Modern Authentication ..'
            $Parms = @{
                url    = 'https://{0}-admin.sharepoint.com' -f $($global:myOffice365Services['Office365Tenant'])
                region = $global:myOffice365Services['SharePointRegion']
            }
        }
        Else {
            Write-Host "Connecting to SharePoint Online using $($global:myOffice365Services['Office365Credentials'].username) .."
            $Parms = @{
                url        = 'https://{0}-admin.sharepoint.com' -f $global:myOffice365Services['Office365Tenant']
                credential = $global:myOffice365Services['Office365Credentials']
                region     = $global:myOffice365Services['SharePointRegion']
            }
        }
        Connect-SPOService @Parms
    }
    Else {
        Write-Error -Message 'Cannot connect to SharePoint Online - problem loading module.'
    }
}
function global:Connect-PowerApps {
    If ( !(Get-Module -Name Microsoft.PowerApps.PowerShell)) { Import-Module -Name Microsoft.PowerApps.PowerShell -ErrorAction SilentlyContinue }
    If ( !(Get-Module -Name Microsoft.PowerApps.Administration.PowerShell)) { Import-Module -Name Microsoft.PowerApps.Administration.PowerShell -ErrorAction SilentlyContinue }
    If ( Get-Module -Name Microsoft.PowerApps.PowerShell) {
        If ( !($global:myOffice365Services['Office365Credentials'])) { Get-Office365Credentials }
        Write-Host "Connecting to PowerApps using $($global:myOffice365Services['Office365Credentials'].username) .."
        If ( $global:myOffice365Services['Office365CredentialsMFA']) {
            $Parms = @{'Username' = $global:myOffice365Services['Office365Credentials'].UserName }
        }
        Else {
            $Parms = @{'Username' = $global:myOffice365Services['Office365Credentials'].UserName; 'Password' = $global:myOffice365Services['Office365Credentials'].Password }
        }
        Add-PowerAppsAccount @Parms
    }
    Else {
        Write-Error -Message 'Cannot connect to SharePoint Online - problem loading module.'
    }
}

Function global:Get-Office365Credentials {

    $global:myOffice365Services['Office365Credentials'] = $host.ui.PromptForCredential('Office 365 Credentials', 'Please enter your Office 365 credentials', $global:myOffice365Services['Office365Credentials'].UserName, '')
    $local:MFAenabledModulePresence = $true
    $global:myOffice365Services['Office365CredentialsMFA'] = Get-MultiFactorAuthenticationUsage
    Get-TenantID
    Set-WindowTitle
}

Function global:Get-OnPremisesCredentials {
    $global:myOffice365Services['OnPremisesCredentials'] = $host.ui.PromptForCredential('On-Premises Credentials', 'Please Enter Your On-Premises Credentials', '', '')
}

Function global:Get-Office365Tenant {
    $global:myOffice365Services['Office365Tenant'] = Read-Host -Prompt 'Enter tenant ID, e.g. contoso for contoso.onmicrosoft.com'
}

Function global:Get-ModuleScope {
    param(
        $Module
    )
    If ( $Module.ModuleBase -ilike ('{0}*' -f (Join-Path -Path $ENV:HOMEDRIVE -ChildPath $ENV:HOMEPATH))) { 
        'CurrentUser' 
    } 
    Else { 
        'AllUsers' 
    }
}

function global:Get-ModuleVersionInfo {
    param( 
        $Module
    )
    $ModuleManifestPath = $Module.Path
    $isModuleManifestPathValid = Test-Path -Path $ModuleManifestPath
    If (!( $isModuleManifestPathValid)) {
        # Module manifest path invalid, skipping extracting prerelease info
        $ModuleVersion = $Module.Version.ToString()
    }
    Else {
        $ModuleManifestContent = Get-Content -Path $ModuleManifestPath
        $preReleaseInfo = $ModuleManifestContent -match "Prerelease = '(.*)'"
        If ( $preReleaseInfo) {
            $preReleaseVersion = $preReleaseInfo[0].Split('=')[1].Trim().Trim("'")
            If ( $preReleaseVersion) {
                $ModuleVersion = ('{0}-{1}' -f $Module.Version.ToString(), $preReleaseVersion)
            }
            Else {
                $ModuleVersion = $Module.Version.ToString()
            }
        }
        Else {
            $ModuleVersion = $Module.Version.ToString()
        }
    }
    $ModuleVersion
}

Function global:Update-Office365Modules {
    param (
        [switch]$AllowPrerelease
    )

    $local:Functions = Get-Office365ModuleInfo

    $local:IsAdmin = [System.Security.principal.windowsprincipal]::new([System.Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    If ( $local:IsAdmin) {
        If ( (Get-Process -Name powershell, pwsh -ErrorAction SilentlyContinue | Measure-Object).Count -gt 1) {
            Write-Warning ('Running multiple PowerShell sessions, successful updating might be problematic.') 
        }
        ForEach ( $local:Function in $local:Functions) {
            $local:Item = ($local:Function).split('|')
            If ( $local:Item[3]) {

                $local:Module = Get-Module -Name ('{0}' -f $local:Item[3]) -ListAvailable | Sort-Object -Property Version -Descending 

                $local:CheckThisModule = $false

                If ( ([System.Uri]($local:Module | Select-Object -First 1).RepositorySourceLocation).Authority -eq (([System.Uri]$local:Item[5])).Authority) {
                    $local:CheckThisModule = $true
                }

                If ( $local:CheckThisModule) {

                    If ( $local:Item[5]) {
                        $local:Module = $local:Module | Where-Object { ([System.Uri]($_.RepositorySourceLocation)).Authority -ieq ([System.Uri]($local:Item[5])).Authority } | Select-Object -First 1
                    }
                    Else {
                        $local:Module = $local:Module | Select-Object -First 1
                    }

                    If ( ($local:Module).RepositorySourceLocation) {

                        $local:Version = Get-ModuleVersionInfo -Module $local:Module
                        Write-Host ('Checking {0}' -f $local:Item[4]) -NoNewLine

                        $local:NewerAvailable = $false
                        If ( $local:Item[5]) {
                            $local:Repo = $local:Repos | Where-Object { ([System.Uri]($_.SourceLocation)).Authority -eq (([System.Uri]$local:Item[5])).Authority }            
                        }
                        If ( [string]::IsNullOrEmpty( $local:Repo )) { 
                            $local:Repo = 'PSGallery'
                        }
                        Else {
                            $local:Repo = ($local:Repo).Name
                        }
                        $OnlineModule = Find-Module -Name $local:Item[3] -Repository $local:Repo -AllowPrerelease:$AllowPrerelease -ErrorAction SilentlyContinue
                        If ( $OnlineModule) {
                            Write-Host (': Local:{0}, Online:{1}' -f $local:Version, $OnlineModule.version)
                            If ( (Compare-TextVersionNumber -Version $local:Version -CompareTo $OnlineModule.version) -eq 1) {
                                $local:NewerAvailable = $true
                            }
                            Else {
                                # Local module up to date or newer
                            }
                        }
                        Else {
                            # Not installed from online or cannot determine
                            Write-Host ('Local:{0} Online:N/A' -f $local:Version)
                        }

                        If ( $local:NewerAvailable) {

                            $local:UpdateSuccess = $false
                            Try {
                                $Parm = @{
                                    AllowPrerelease = $AllowPrerelease
                                    Force           = $True
                                    Confirm         = $False
                                    Scope           = Get-ModuleScope -Module $local:Module
                                    AllowClobber    = $True
                                }
                                # Pass AcceptLicense if current version of UpdateModule supports it
                                If ( ( Get-Command -name Update-Module).Parameters['AcceptLicense']) {
                                    $Parm.AcceptLicense = $True
                                }
                                If ( Get-Command Install-Package -ErrorAction SilentlyContinue) {
                                    If ( ( Get-Command -name Install-Package).Parameters['SkipPublisherCheck']) {
                                        $Parm.SkipPublisherCheck = $True
                                    }
                                    Install-Package -Name $local:Item[3] -Source $local:Repo @Parm | Out-Null
                                }
                                Else {
                                    Update-Module -Name $local:Item[3] @Parm
                                }
                                $local:UpdateSuccess = $true
                            }
                            Catch {
                                Write-Error ('Problem updating module {0}:{1}' -f $local:Item[3], $Error[0].Message)
                            }

                            If ( $local:UpdateSuccess) {

                                If ( Get-Command -Name Get-InstalledModule -ErrorAction SilentlyContinue) {
                                    $local:ModuleVersions = Get-InstalledModule -Name $local:Item[3] -AllVersions 
                                }
                                Else {
                                    $local:ModuleVersions = Get-Module -Name $local:Item[3] -ListAvailable -All
                                }

                                $local:Module = $local:ModuleVersions | Sort-Object -Property @{e = { [System.Version]($_.Version -replace '[^\d\.]', '') } } -Descending | Select-Object -First 1
                                $local:LatestVersion = ($local:Module).Version
                                Write-Host ('Updated {0} to version {1}' -f $local:Item[4], $local:LatestVersion) -ForegroundColor Green

                                # Uninstall all old versions of dependencies
                                If ( $OnlineModule) {
                                    ForEach ( $DependencyModule in $OnlineModule.Dependencies) {

                                        # Unload
                                        Remove-Module -Name $DependencyModule.Name -Force -Confirm:$False -ErrorAction SilentlyContinue

                                        $local:DepModuleVersions = Get-Module -Name $DependencyModule.Name -ListAvailable
                                        $local:DepModule = $local:DepModuleVersions | Sort-Object -Property @{e = { [System.Version]($_.Version -replace '[^\d\.]', '') } } -Descending | Select-Object -First 1
                                        $local:DepLatestVersion = ($local:DepModule).Version
                                        $local:OldDepModules = $local:DepModuleVersions | Where-Object { $_.Version -ne $local:DepLatestVersion }
                                        ForEach ( $DepModule in $local:OldDepModules) {
                                            Write-Host ('Uninstalling dependency module {0} version {1}' -f $DepModule.Name, $DepModule.Version)
                                            Try {
                                                $DepModule | Uninstall-Module -Confirm:$false -Force
                                            }
                                            Catch {
                                                Write-Error ('Problem uninstalling module {0} version {1}' -f $DepModule.Name, $DepModule.Version) 
                                            }
                                        }
                                    }
                                }

                                # Uninstall all old versions of the module
                                $local:OldModules = $local:ModuleVersions | Where-Object { $_.Version -ne $local:LatestVersion }
                                If ( $local:OldModules) {

                                    # Unload module when currently loaded
                                    Remove-Module -Name $local:Item[3] -Force -Confirm:$False -ErrorAction SilentlyContinue

                                    ForEach ( $OldModule in $local:OldModules) {
                                        Write-Host ('Uninstalling {0} version {1}' -f $local:Item[4], $OldModule.Version) -ForegroundColor White
                                        Try {
                                            $OldModule | Uninstall-Module -Confirm:$false -Force
                                        }
                                        Catch {
                                            Write-Error ('Problem uninstalling module {0} version {1}' -f $OldModule.Name, $OldModule.Version) 
                                        }
                                    }
                                }
                            }
                            Else {
                                # Problem during update
                            }
                        }
                        Else {
                            # No update available
                        }

                    }
                    Else {
                        Write-Host ('Skipping {0}: Not installed using PowerShellGet/Install-Module' -f $local:Item[4]) -ForegroundColor Yellow
                    }
                }
            }
        }
    }
    Else {
        Write-Host ('Script not running with elevated privileges; cannot update modules') -ForegroundColor Yellow
    }
}

# Compare-TextVersionNumber to handle (rich) version comparison, similar to [System.Version]'s CompareTo method
# 1=CompareTo is newer, 0 = Equal, -1 = Version is Newer
Function global:Compare-TextVersionNumber {
    param(
        [string]$Version,
        [string]$CompareTo
    )
    $res = 0
    $null = $Version -match '^(?<version>[\d\.]+)(\-)?([a-zA-Z]*(?<preview>[\d]*))?$'
    $VersionVer = [System.Version]($matches.Version)
    If ( $matches.Preview) {
        # Suffix .0 to satisfy SystemVersion as '#' won't initialize
        $VersionPreviewVer = [System.Version]('{0}.0' -f $matches.Preview)
    }
    Else {
        $VersionPreviewVer = [System.Version]'99999.99999'
    }
    $null = $CompareTo -match '^(?<version>[\d\.]+)(\-)?([a-zA-Z]*(?<preview>[\d]*))?$'
    $CompareToVer = [System.Version]($matches.Version)
    If ( $matches.Preview) {
        $CompareToPreviewVer = [System.Version]('{0}.0' -f $matches.Preview)
    }
    Else {
        $CompareToPreviewVer = [System.Version]'99999.99999'
    }
    
    If ( $VersionVer -gt $CompareToVer) {
        $res = -1
    }
    Else {
        If ( $VersionVer -lt $CompareToVer) {
            $res = 1
        }
        Else {
            # Equal - Check Preview Tag
            If ( $VersionPreviewVer -gt $CompareToPreviewVer) {
                $res = -1
            }
            Else {
                If ( $VersionPreviewVer -lt $CompareToPreviewVer) {
                    $res = 1
                }
                Else {
                    # Really Equal
                    $res = 0
                }
            }
        
        }
    }
    $res
}

Function global:Report-Office365Modules {

    param(
        [switch]$AllowPrerelease
    )

    $local:Functions = Get-Office365ModuleInfo
    $local:Repos = Get-PSRepository

    ForEach ( $local:Function in $local:Functions) {

        $local:Item = ($local:Function).split('|')
        If ( $local:Item[3]) {
            $local:Module = Get-Module -Name ('{0}' -f $local:Item[3]) -ListAvailable | Sort-Object -Property Version -Descending

            # Use specific or default repository
            If ( $local:Item[5]) {
                $local:Repo = $local:Repos | Where-Object { ([System.Uri]($_.SourceLocation)).Authority -eq (([System.Uri]$local:Item[5])).Authority }
            }
            If ( [string]::IsNullOrEmpty( $local:Repo )) { 
                $local:Repo = 'PSGallery'
            }
            Else {
                $local:Repo = ($local:Repo).Name
            }

            If ( $local:Item[5]) {
                $local:Module = $local:Module | Where-Object { ([System.Uri]($_.RepositorySourceLocation)).Authority -ieq ([System.Uri]($local:Item[5])).Authority } | Select-Object -First 1
            }
            Else {
                $local:Module = $local:Module | Select-Object -First 1
            }

            If ( $local:Module) {

                $local:Version = Get-ModuleVersionInfo -Module $local:Module

                Write-Host ('Module {0}: Local v{1}' -f $local:Item[4], $Local:Version) -NoNewline
   
                $OnlineModule = Find-Module -Name $local:Item[3] -Repository $local:Repo -AllowPrerelease:$AllowPrerelease -ErrorAction SilentlyContinue
                If ( $OnlineModule) {
                    Write-Host (', Online v{0}' -f $OnlineModule.version) -NoNewline
                }
                Else {
                    Write-Host (', Online N/A') -NoNewline
                }
                Write-Host (', Scope:{0} Status:' -f (Get-ModuleScope -Module $local:Module)) -NoNewline

                If ( [string]::IsNullOrEmpty( $local:Version) -or [string]::IsNullOrEmpty( $OnlineModule.version)) {
                    Write-Host ('Unknown')
                }
                Else {
                    If ( (Compare-TextVersionNumber -Version $local:Version -CompareTo $OnlineModule.version) -eq 1) {
                        Write-Host ('Outdated') -ForegroundColor Red
                    }
                    Else {
                        Write-Host ('OK') -ForegroundColor Green
                    }
                }
            }
            Else {
                Write-Host ('{0} module not found ({1})' -f $local:Item[4], $local:Item[5])
            }
        }
    }
}

function global:Connect-Office365 {
    Connect-AzureActiveDirectory
    Connect-AzureRMS
    Connect-ExchangeOnline
    Connect-MSTeams
    Connect-SkypeOnline
    Connect-ComplianceCenter
    Connect-SharePointOnline
}

$PSGetModule = Get-Module -Name PowerShellGet -ListAvailable -ErrorAction SilentlyContinue | Sort-Object -Property Version -Descending | Select-Object -First 1
If (! $PSGetModule) {
    $PSGetVer = 'N/A'
}
Else {
    $PSGetVer = $PSGetModule.Version
}
$PackageManagementModule = Get-Module -Name PackageManagement -ListAvailable -ErrorAction SilentlyContinue | Sort-Object -Property Version -Descending | Select-Object -First 1
If (! $PackageManagementModule) {
    $PMMVer = 'N/A'
}
Else {
    $PMMVer = $PackageManagementModule.Version
}

Write-Host ('*' * 78)
Write-Host ('Connect-Office365Services v{0}' -f $local:ScriptVersion)

# See if the Administator built-in role is part of your role
$local:IsAdmin = [System.Security.principal.windowsprincipal]::new([System.Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)

$local:CreateISEMenu = $psISE -and -not [System.Windows.Input.Keyboard]::IsKeyDown( [System.Windows.Input.Key]::LeftShift)
If ( $local:CreateISEMenu) { Write-Host 'ISE detected, adding ISE menu options' }

# Initialize global state variable when needed
If ( -not( Get-Variable myOffice365Services -ErrorAction SilentlyContinue )) { $global:myOffice365Services = @{} }

# Local Exchange session options
$global:myOffice365Services['SessionExchangeOptions'] = New-PSSessionOption -ProxyAccessType None

# Initialize environment & endpoints
Set-Office365Environment -AzureEnvironment 'Default'

Write-Host ('Environment:{0}, Administrator:{1}' -f $global:myOffice365Services['AzureEnvironment'], $local:IsAdmin)
Write-Host ('Architecture:{0}, PS:{1}, PSGet:{2}, PackageManagement:{3}' -f ($ENV:PROCESSOR_ARCHITECTURE), ($PSVersionTable).PSVersion, $PSGetVer, $PMMVer )
Write-Host ('*' * 78)

$local:Functions = Get-Office365ModuleInfo
$local:Repos = Get-PSRepository

Write-Host ('Collecting Module information ..')

If ( Get-Module -Name 'SkypeOnlineConnector' -ListAvailable) {
    Write-Warning 'Notice: The Skype for Business Online Connector PowerShell module functionality has moved to the Microsoft Teams module. Module retired February 15th, 2021.'
}
If ( Get-Module -Name 'Microsoft.Exchange.Management.ExoPowershellModule' -ListAvailable) {
    Write-Warning 'Notice: The Exchange Online PowerShell module has been replaced by the Exchange Online Management module.'
}

ForEach ( $local:Function in $local:Functions) {

    $local:Item = ($local:Function).split('|')
    $local:CreateMenuItem = $False
    If ( $local:Item[3]) {
        $local:Module = Get-Module -Name ('{0}' -f $local:Item[3]) -ListAvailable | Sort-Object -Property Version -Descending
        $local:ModuleMatch = ([System.Uri]($local:Module | Select-Object -First 1).RepositorySourceLocation).Authority -eq ([System.Uri]$local:Item[5]).Authority
        If ( $local:ModuleMatch) {
            $local:Module = $local:Module | Sort-Object -Property @{e = { [System.Version]($_.Version -replace '[^\d\.]', '') } } -Descending
            If ( $local:Item[5]) {
                $local:Module = $local:Module | Where-Object { ([System.Uri]($_.RepositorySourceLocation)).Authority -ieq ([System.Uri]($local:Item[5])).Authority } | Select-Object -First 1
            }
            Else {
                $local:Module = $local:Module | Select-Object -First 1
            }
            $local:Version = Get-ModuleVersionInfo -Module $local:Module
            Write-Host ('Found {0} module (v{1})' -f $local:Item[4], $local:Version) -ForegroundColor Green
            $local:CreateMenuItem = $True
        }
        Else {
            # Module not found
        }
    }
    Else {
        # Local function
        $local:CreateMenuItem = $True
    }

    If ( $local:CreateMenuItem -and $local:CreateISEMenu) {
        # Create menu item when module found or local function 
        $local:MenuObj = $psISE.CurrentPowerShellTab.AddOnsMenu.SubMenus | Where-Object -FilterScript { $_.DisplayName -eq $local:Item[0] }
        If ( !( $local:MenuObj)) {
            Try { $local:MenuObj = $psISE.CurrentPowerShellTab.AddOnsMenu.SubMenus.Add( $local:Item[0], $null, $null) }
            Catch { Write-Warning -Message $_ }
        }
        Try {
            $local:RemoveItems = $local:MenuObj.Submenus |  Where-Object -FilterScript { $_.DisplayName -eq $local:Item[1] -or $_.Action -eq $local:Item[2] }
            $null = $local:RemoveItems | ForEach-Object -Process { $local:MenuObj.Submenus.Remove( $_) }
            $null = $local:MenuObj.SubMenus.Add( $local:Item[1], [ScriptBlock]::Create( $local:Item[2]), $null)
        }
        Catch {
            Write-Warning -Message $_
        }
    }
}
}
function Convert-AzuretoOnPremOther {
<#
.SYNOPSIS
Converts an Azure AD user to an on-premises Active Directory user.

.DESCRIPTION
The Convert-AzuretoOnPrem function retrieves an Azure AD user's information and creates a corresponding on-premises Active Directory user using the New-ADUser cmdlet. The function requires the Azure AD user's Object ID as input.

.PARAMETER AzureADUser
Specifies the Object ID of the Azure AD user to convert.
Mandatory: Yes

.PARAMETER AccountPassword
Specifies the password for the converted user account. If not provided, the function will use the default password "ThisIsMyPassword.1234".
Mandatory: No
Default: "ThisIsMyPassword.1234"

.EXAMPLE
Convert-AzuretoOnPrem -AzureADUser "12345678-90ab-cdef-ghij-klmnopqrstuv" -AccountPassword "MyNewPassword123"
Converts the Azure AD user with the specified Object ID to an on-premises Active Directory user with the specified password.

.INPUTS
None

.OUTPUTS
None

#>

function Convert-AzuretoOnPrem {
    <#
.SYNOPSIS
Converts an Azure AD user to an on-premises Active Directory user.

.DESCRIPTION
The Convert-AzuretoOnPrem function retrieves an Azure AD user's information and creates a corresponding on-premises Active Directory user using the New-ADUser cmdlet. The function requires the Azure AD user's Object ID as input.

.PARAMETER AzureADUser
Specifies the Object ID of the Azure AD user to convert.
Mandatory: Yes

.PARAMETER AccountPassword
Specifies the password for the converted user account as a PSCredential object. If not provided, the function will use the default password "ThisIsMyPassword.1234".
Mandatory: No
Default: "ThisIsMyPassword.1234"

.EXAMPLE
$creds = Get-Credential
Convert-AzuretoOnPrem -AzureADUser "12345678-90ab-cdef-ghij-klmnopqrstuv" -AccountPassword $creds
Converts the Azure AD user with the specified Object ID to an on-premises Active Directory user with the specified password.

.INPUTS
None

.OUTPUTS
None

#>

    function Convert-AzuretoOnPrem {
        [CmdletBinding(SupportsShouldProcess = $true)]
        param (
            [Parameter(
                Mandatory = $true,
                ValueFromPipeline = $true,
                ValueFromPipelineByPropertyName = $true,
                HelpMessage = 'Enter the UserPrincipalName for the Azure Account to be converted.'
            )]
            [string]$AzureADUser,

            [Parameter(
                Mandatory = $false,
                ValueFromPipeline = $true,
                ValueFromPipelineByPropertyName = $true,
                HelpMessage = 'Enter a password for the converted Azure Account or pipe input. This is not a mandatory field and defaults to ThisIsMyPassword.1234'
            )]
            [Alias('cred')]
            [ValidateNotNull()]
            [System.Management.Automation.PSCredential]
            [System.Management.Automation.Credential()]
            $AccountPassword = (New-Object System.Management.Automation.PSCredential 'dummy', (ConvertTo-SecureString -String 'ThisIsMyPassword.1234' -AsPlainText -Force))
        )

        begin {
            Import-Module AzureAD
        }

        process {
            $UserTest = Get-AzureADUser -ObjectId $AzureADUser | Select-Object City, Country, Department, DisplayName, Fax, GivenName, Surname, Mobile, OfficeLocation, PhoneNumber, PostalCode, State, StreetAddress, JobTitle, UserPrincipalName

            foreach ($User in $UserTest) {
                $samAccountName = $User.GivenName + "." + $User.Surname

                $params = @{
                    Name                 = $samAccountName
                    SamAccountName       = $samAccountName
                    GivenName            = $User.GivenName
                    Surname              = $User.Surname
                    City                 = $User.City
                    Department           = $User.Department
                    DisplayName          = $User.DisplayName
                    Fax                  = $User.Fax
                    MobilePhone          = $User.Mobile
                    Office               = $User.OfficeLocation
                    PasswordNeverExpires = [bool]$User.PasswordNeverExpires
                    OfficePhone          = $User.PhoneNumber
                    PostalCode           = $User.PostalCode
                    EmailAddress         = $User.UserPrincipalName
                    State                = $User.State
                    StreetAddress        = $User.StreetAddress
                    Title                = $User.JobTitle
                    UserPrincipalName    = $User.UserPrincipalName
                    AccountPassword      = $AccountPassword
                    Enabled              = $true
                }

                if ($PSCmdlet.ShouldProcess($User.UserPrincipalName, "Create on-premises AD user")) {
                    Write-Verbose "Creating on-premises AD user: $samAccountName"
                    New-ADUser @params
                }

                $ldifdeCommand = "ldifde.exe -f C:\Temp\ExportAllUser.txt -r ""(UserPrincipalname=$User.UserPrincipalName)"" -l ""ObjectGuid, userPrincipalName"""
                Start-Process -FilePath $ldifdeCommand -Wait -NoNewWindow
                Set-AzureADUser -ImmutableId $User.ObjectGuid
            }
        }

        end {
            Write-Output "Script completed."
        }
    }

}
}
function CreateModuleScriptFile {
$Scripts = Get-ChildItem C:\GitRepos\Carpetright\CarpetrightToolkit\Functions\ -File | Select-Object -Property FullName
foreach ( $Script in $Scripts) {
    $Content = Get-Content -Path $Script.fullname
    Add-Content -Path C:\GitRepos\Carpetright\CarpetrightToolkit\CarpetrightToolkit\CarpetrightToolkit.psm1 -Value $Content
}
}
function credentialsSnippet {
[Parameter(ParameterSetName = 'Default',
	Mandatory = $false,
	ValueFromPipeline = $true,
	ValueFromPipelineByPropertyName = $true,
	HelpMessage = 'Enter computer name or pipe input'
)]
[Alias('cn')]
[string[]]$ComputerName = $env:COMPUTERNAME,

[Parameter(ParameterSetName = 'Default',
	Mandatory = $false,
	ValueFromPipeline = $true,
	ValueFromPipelineByPropertyName = $true,
	HelpMessage = 'Enter computer name or pipe input'
)]
[Alias('cred')]
[ValidateNotNull()]
[System.Management.Automation.PSCredential]
[System.Management.Automation.Credential()]
$Credential
}
function CredParamsInScript {
[CmdletBinding(DefaultParameterSetName = 'Default',
	PositionalBinding = $true,
	SupportsShouldProcess = $true)]
[OutputType([string], ParameterSetName = 'Default')]
[Alias('something')]
Param
(
	[Parameter(ParameterSetName = 'Default',
		Mandatory = $true,
		ValueFromPipeline = $true,
		ValueFromPipelineByPropertyName = $true,
		ValueFromRemainingArguments = $true,
		Position = 0,
		HelpMessage = 'Enter the Name of the computer you would like to connect to.')]
	[Alias('cn')]
	[string[]]
	$ComputerName = $env:COMPUTERNAME,

	[Parameter(ParameterSetName = 'Default',
		Mandatory = $false,
		ValueFromPipeline = $true,
		ValueFromPipelineByPropertyName = $true,
		HelpMessage = 'Enter computer name or pipe input'
	)]
	[Alias('cred')]
	[ValidateNotNull()]
	[System.Management.Automation.PSCredential]
	[System.Management.Automation.Credential()]
	$Credential

)

}
function dateString {
$FileDate = [datetime]::Now.ToString("dd-MM-yyyy-HH-mm-ss")
$FileDate
}
function DoSomething {
<#
.SYNOPSIS
    A script that does something.
.DESCRIPTION
    This script does something. The something that it does is entered as a string by the user.
.NOTES
    This is an example of a script.
.LINK
    - [something.com](http://something.com)
.EXAMPLE
    This is an example that will do the thing you want to do at the time you want to do it.
    .\DoSomething.ps1 -Whattodo "Do something" -WhenToDoIt (Get-Date).addHours(1)
#>
[CmdletBinding(DefaultParameterSetName = 'Default')]
[OutputType([object], ParameterSetName = 'Default')]
[OutputType([object])]
Param
(
    [Parameter(ParameterSetName = 'Default',
        Mandatory = $true,
        ValueFromPipelineByPropertyName = $true,
        HelpMessage = 'The something that you want to do.')]
    [string]$WhatToDo,
    [Parameter(ParameterSetName = 'Default',
        Mandatory = $true,
        ValueFromPipelineByPropertyName = $true,
        HelpMessage = 'The something that you want to do with the something.')]
    [datetime]$WhenToDoIt
)
Start-process $WhatToDo -ArgumentList $WhenToDoIt

}
function Example-profile {
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
    Get-ChildItem C:\GitRepos\ProfileFunctions\ProfileFunctions\6Instead\*.ps1 | ForEach-Object { . $_ }
}

#Enable concise errorview for PS7 and up
if ($psversiontable.psversion.major -ge 7) {
    $ErrorView = 'ConciseView'
    # oh-my-posh print primary --config C:\GitRepos\ProfileFunctions\BanterBoyOhMyPoshTheme.json --shell uni
    oh-my-posh init pwsh --config C:\GitRepos\ProfileFunctions\BanterBoyOhMyPoshConfig.json | Invoke-Expression
    Get-ChildItem C:\GitRepos\ProfileFunctions\ProfileFunctions\7Only\*.ps1 | ForEach-Object { . $_ }
}

#--------------------
# Generic Profile Commands
#--------------------
Get-ChildItem C:\GitRepos\ProfileFunctions\ProfileFunctions\*.ps1 | ForEach-Object { . $_ }
Get-ChildItem C:\GitRepos\Windows-Sandbox\Start-WindowsSandbox.ps1 | ForEach-Object { . $_ }

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

}
else {
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
}
function ExampleParamsInScript {
[CmdletBinding(SupportsShouldProcess = $true)]
param (
	[Parameter(ParameterSetName = 'Default',
		Mandatory = $false,
		ValueFromPipeline = $true,
		ValueFromPipelineByPropertyName = $true,
		HelpMessage = 'Enter computer name or pipe input'
	)]
	[Alias('cn')]
	[string[]]$ComputerName = $env:COMPUTERNAME,
	[Parameter(ParameterSetName = 'Default',
		Mandatory = $false,
		ValueFromPipeline = $true,
		ValueFromPipelineByPropertyName = $true,
		HelpMessage = 'Enter computer name or pipe input'
	)]
	[Alias('cred')]
	[ValidateNotNull()]
	[System.Management.Automation.PSCredential]
	[System.Management.Automation.Credential()]
	$Credential,
	[Parameter(ParameterSetName = 'Default',
		Mandatory = $false,
		ValueFromPipeline = $true,
		ValueFromPipelineByPropertyName = $true,
		HelpMessage = 'Enter computer name or pipe input'
	)]
	[Alias('sam')]
	[string[]]$SamAccountName
)
Process {
	if ($PSCmdlet.ShouldProcess("$ComputerName / $SamAccountName", "ExampleParamsInScript")) {
		# Script content goes here
		
	}
}
}
function Expand-WinEvent {
function Expand-WinEvent {
    <#
    .SYNOPSIS
    Configured EventLogRecords into EventLogExpandedRecords that are easier to parse
    .DESCRIPTION
    Convert eventRecords into a more parseable object format, including custom event properties
    By expanding the Event XML data into individual properties, this makes WinEvents easier to work with and parse
     
    .NOTES
    Inspired by http://blogs.technet.com/b/ashleymcglone/archive/2013/08/28/powershell-get-winevent-xml-madness-getting-details-from-event-logs.aspx
    .EXAMPLE
    PS C:\> Get-Winevent -LogName Application | Expand-WinEvent
    Takes all application logs and expands their properties.
    #>

    param (
        #Specifies an event generated by Get-WinEvent. WARNING: DOES NOT WORK WITH GET-EVENTLOG
        [Parameter(Mandatory, ValueFromPipeline)]
        [System.Diagnostics.Eventing.Reader.EventLogRecord]$EventLogRecord,
        #If specified, outputs a hashtable of object properties rather than the object itself. Useful for creating a subtype.
        [Switch]$OutHashTable
    )

    begin {
        #Define the event type and default display properties
        $CustomEventRecordType = "System.Diagnostics.Eventing.Reader.EventLogRecordExpanded"
        Update-TypeData -TypeName $CustomEventRecordType -DefaultDisplayPropertySet TimeCreated, ID, ProviderName, TaskDisplayName -Force
    } #Begin

    process {
        $EventLogRecord | ForEach-Object {

            $EventProperties = [ordered]@{
                TimeCreated      = $PSItem.TimeCreated
                ID               = $PSItem.ID
                LevelDisplayName = $PSItem.LevelDisplayName
                ProviderName     = $PSItem.ProviderName
                TaskDisplayName  = if ($PSItem.TaskDisplayName) { $PSItem.TaskDisplayName } else { $null }
                MachineName      = $PSItem.MachineName
                Message          = $PSItem.Message
                RawEvent         = $PSItem
            }


            #Add all the attribute properties of the event object. This is dynamic and works for all events.
            $i = 1
            ([xml]$PSItem.toxml()).Event.EventData.Data |  ForEach-Object {
                #Skip in the event this is a classic log with no attribute properties
                if ($PSItem) {

                    #If the data is unstructured, just create as "Property1","Property2", etc.
                    if ($PSItem -isnot [System.XML.XMLElement]) {
                        $PropertyName = "Property" + $i
                        $EventProperties.Add($PropertyName, $PSItem)
                        $i++
                    } 
                    
                    else {
                        if ($EventProperties.Contains($PSItem.Name)) {
                            $PropertyName = "property" + $PSItem.Name
                        }
                        else { $PropertyName = $PSItem.Name }
                        $EventProperties.Add($PropertyName, $PSItem."#text")
                    }
                } #If ($PSItem)
            } #ForEach
            
            if ($OutHashTable) {
                $EventProperties
            } 
            else {
                $result = [PSCustomObject]$EventProperties
                #Assign custom type so it shows properly in Get-Member
                $result.PSTypeNames.Insert(0, $customEventRecordType)
                $result
            }
        } # ForEach
    } # Process
} # Expand-WinEvent
}
function FileWatcher {
# -------File Watcher-------
### SET FOLDER TO WATCH + FILES TO WATCH + SUBFOLDERS YES/NO
$filewatcher = New-Object System.IO.FileSystemWatcher
#Mention the folder to monitor
$filewatcher.Path = "C:\D_EMS Drive\Personal\LBLOG\"
$filewatcher.Filter = "*.*"
#include subdirectories $true/$false
$filewatcher.IncludeSubdirectories = $true
$filewatcher.EnableRaisingEvents = $true  
### DEFINE ACTIONS AFTER AN EVENT IS DETECTED
$writeaction = { $path = $Event.SourceEventArgs.FullPath
    $changeType = $Event.SourceEventArgs.ChangeType
    $logline = "$(Get-Date), $changeType, $path"
    Add-Content "C:\D_EMS Drive\Personal\LBLOG\FileWatcher_log.txt" -value $logline
}    
### DECIDE WHICH EVENTS SHOULD BE WATCHED 
#The Register-ObjectEvent cmdlet subscribes to events that are generated by .NET objects on the local computer or on a remote computer.
#When the subscribed event is raised, it is added to the event queue in your session. To get events in the event queue, use the Get-Event cmdlet.
Register-ObjectEvent $filewatcher "Created" -Action $writeaction
Register-ObjectEvent $filewatcher "Changed" -Action $writeaction
Register-ObjectEvent $filewatcher "Deleted" -Action $writeaction
Register-ObjectEvent $filewatcher "Renamed" -Action $writeaction
while ($true) { Start-Sleep 5 }
}
function Force-HappyState {
<#

This PowerShell script defines a function called "Get-Happy". The function takes a single parameter called "When", which is of type "datetime". The parameter is optional, and can be passed in via the pipeline or by property name. The function also has a "CmdletBinding" attribute, which allows it to be used as a cmdlet.

The "begin" block of the function initializes a variable called "$State" by calling the "Get-HappyState" function. This function is not defined in the code snippet, but it is likely that it retrieves some sort of state information related to happiness.

The "process" block of the function filters the "$State" variable using a "Where-Object" cmdlet. The filter script checks if the "Unhappy" property of each object in "$State" contains the strings "miserable" or "unhappy", or if the "Smile" property contains the string "grimace". If any of these conditions are true, the object is passed down the pipeline to the "Set-HappyState" function.

The "Set-HappyState" function is not defined in the code snippet, but it is likely that it sets some sort of state information related to happiness. It takes several parameters, including "-Happy", "-Smile", and "-When", which are set to "$true", ""Grin"", and "$When", respectively.

The "end" block of the function is empty, so it does not perform any actions.

Overall, this function seems to be designed to filter a list of happiness-related state information and update the state of any unhappy items to be happy. However, without more context about the "Get-HappyState" and "Set-HappyState" functions, it is difficult to say exactly what this code is doing.

To improve the readability of this code, it would be helpful to add comments explaining the purpose of each block of the function, as well as the purpose of the "Get-HappyState" and "Set-HappyState" functions. Additionally, the variable names could be made more descriptive to make the code easier to understand. Finally, it would be helpful to add error handling to the function to ensure that it behaves correctly in all situations.

#>

function Get-Happy {
    [CmdletBinding()]
    param (
        [Parameter(ParameterSetName = 'Default',
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Enter computer name or pipe input'
        )]
        [Alias('wn')]
        [datetime]$When
    )
    
    begin {
        $State = Get-HappyState
    }
    
    process {
        $State |
        Where-Object -FilterScript {
            ( $_.Unhappy -like '*miserable*' ) -or 
            ( $_.Unhappy -like '*unhappy*' ) -or 
            ( $_.Smile -like '*grimace*' )
        } | Set-HappyState -Happy:$true -Smile:Grin -When $When -Force
    }
    
    end {
        
    }
}
}
function functions {
Get-ServerInventory {
    <#
    
    .SYNOPSIS
    Retrieves the inventory data for a server.
    
    .DESCRIPTION
    Retrieves the inventory data for a server.
    
    .ROLE
    Readers
    
    #>
    
    Set-StrictMode -Version 5.0
    
    Import-Module CimCmdlets
    
    <#
    
    .SYNOPSIS
    Converts an arbitrary version string into just 'Major.Minor'
    
    .DESCRIPTION
    To make OS version comparisons we only want to compare the major and 
    minor version.  Build number and/os CSD are not interesting.
    
    #>
    
    function convertOsVersion([string]$osVersion) {
        [Ref]$parsedVersion = $null
        if (![Version]::TryParse($osVersion, $parsedVersion)) {
            return $null
        }
    
        $version = [Version]$parsedVersion.Value
        return New-Object Version -ArgumentList $version.Major, $version.Minor
    }
    
    <#
    
    .SYNOPSIS
    Determines if CredSSP is enabled for the current server or client.
    
    .DESCRIPTION
    Check the registry value for the CredSSP enabled state.
    
    #>
    
    function isCredSSPEnabled() {
        Set-Variable credSSPServicePath -Option Constant -Value "WSMan:\localhost\Service\Auth\CredSSP"
        Set-Variable credSSPClientPath -Option Constant -Value "WSMan:\localhost\Client\Auth\CredSSP"
    
        $credSSPServerEnabled = $false;
        $credSSPClientEnabled = $false;
    
        $credSSPServerService = Get-Item $credSSPServicePath -ErrorAction SilentlyContinue
        if ($credSSPServerService) {
            $credSSPServerEnabled = [System.Convert]::ToBoolean($credSSPServerService.Value)
        }
    
        $credSSPClientService = Get-Item $credSSPClientPath -ErrorAction SilentlyContinue
        if ($credSSPClientService) {
            $credSSPClientEnabled = [System.Convert]::ToBoolean($credSSPClientService.Value)
        }
    
        return ($credSSPServerEnabled -or $credSSPClientEnabled)
    }
    
    <#
    
    .SYNOPSIS
    Determines if the Hyper-V role is installed for the current server or client.
    
    .DESCRIPTION
    The Hyper-V role is installed when the VMMS service is available.  This is much
    faster then checking Get-WindowsFeature and works on Windows Client SKUs.
    
    #>
    
    function isHyperVRoleInstalled() {
        $vmmsService = Get-Service -Name "VMMS" -ErrorAction SilentlyContinue
    
        return $vmmsService -and $vmmsService.Name -eq "VMMS"
    }
    
    <#
    
    .SYNOPSIS
    Determines if the Hyper-V PowerShell support module is installed for the current server or client.
    
    .DESCRIPTION
    The Hyper-V PowerShell support module is installed when the modules cmdlets are available.  This is much
    faster then checking Get-WindowsFeature and works on Windows Client SKUs.
    
    #>
    function isHyperVPowerShellSupportInstalled() {
        # quicker way to find the module existence. it doesn't load the module.
        return !!(Get-Module -ListAvailable Hyper-V -ErrorAction SilentlyContinue)
    }
    
    <#
    
    .SYNOPSIS
    Determines if Windows Management Framework (WMF) 5.0, or higher, is installed for the current server or client.
    
    .DESCRIPTION
    Windows Admin Center requires WMF 5 so check the registey for WMF version on Windows versions that are less than
    Windows Server 2016.
    
    #>
    function isWMF5Installed([string] $operatingSystemVersion) {
        Set-Variable Server2016 -Option Constant -Value (New-Object Version '10.0')   # And Windows 10 client SKUs
        Set-Variable Server2012 -Option Constant -Value (New-Object Version '6.2')
    
        $version = convertOsVersion $operatingSystemVersion
        if (-not $version) {
            # Since the OS version string is not properly formatted we cannot know the true installed state.
            return $false
        }
    
        if ($version -ge $Server2016) {
            # It's okay to assume that 2016 and up comes with WMF 5 or higher installed
            return $true
        }
        else {
            if ($version -ge $Server2012) {
                # Windows 2012/2012R2 are supported as long as WMF 5 or higher is installed
                $registryKey = 'HKLM:\SOFTWARE\Microsoft\PowerShell\3\PowerShellEngine'
                $registryKeyValue = Get-ItemProperty -Path $registryKey -Name PowerShellVersion -ErrorAction SilentlyContinue
    
                if ($registryKeyValue -and ($registryKeyValue.PowerShellVersion.Length -ne 0)) {
                    $installedWmfVersion = [Version]$registryKeyValue.PowerShellVersion
    
                    if ($installedWmfVersion -ge [Version]'5.0') {
                        return $true
                    }
                }
            }
        }
    
        return $false
    }
    
    <#
    
    .SYNOPSIS
    Determines if the current usser is a system administrator of the current server or client.
    
    .DESCRIPTION
    Determines if the current usser is a system administrator of the current server or client.
    
    #>
    function isUserAnAdministrator() {
        return ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    }
    
    <#
    
    .SYNOPSIS
    Get some basic information about the Failover Cluster that is running on this server.
    
    .DESCRIPTION
    Create a basic inventory of the Failover Cluster that may be running in this server.
    
    #>
    function getClusterInformation() {
        $returnValues = @{}
    
        $returnValues.IsS2dEnabled = $false
        $returnValues.IsCluster = $false
        $returnValues.ClusterFqdn = $null
    
        $namespace = Get-CimInstance -Namespace root/MSCluster -ClassName __NAMESPACE -ErrorAction SilentlyContinue
        if ($namespace) {
            $cluster = Get-CimInstance -Namespace root/MSCluster -ClassName MSCluster_Cluster -ErrorAction SilentlyContinue
            if ($cluster) {
                $returnValues.IsCluster = $true
                $returnValues.ClusterFqdn = $cluster.Fqdn
                $returnValues.IsS2dEnabled = !!(Get-Member -InputObject $cluster -Name "S2DEnabled") -and ($cluster.S2DEnabled -gt 0)
            }
        }
    
        return $returnValues
    }
    
    <#
    
    .SYNOPSIS
    Get the Fully Qaulified Domain (DNS domain) Name (FQDN) of the passed in computer name.
    
    .DESCRIPTION
    Get the Fully Qaulified Domain (DNS domain) Name (FQDN) of the passed in computer name.
    
    #>
    function getComputerFqdnAndAddress($computerName) {
        $hostEntry = [System.Net.Dns]::GetHostEntry($computerName)
        $addressList = @()
        foreach ($item in $hostEntry.AddressList) {
            $address = New-Object PSObject
            $address | Add-Member -MemberType NoteProperty -Name 'IpAddress' -Value $item.ToString()
            $address | Add-Member -MemberType NoteProperty -Name 'AddressFamily' -Value $item.AddressFamily.ToString()
            $addressList += $address
        }
    
        $result = New-Object PSObject
        $result | Add-Member -MemberType NoteProperty -Name 'Fqdn' -Value $hostEntry.HostName
        $result | Add-Member -MemberType NoteProperty -Name 'AddressList' -Value $addressList
        return $result
    }
    
    <#
    
    .SYNOPSIS
    Get the Fully Qaulified Domain (DNS domain) Name (FQDN) of the current server or client.
    
    .DESCRIPTION
    Get the Fully Qaulified Domain (DNS domain) Name (FQDN) of the current server or client.
    
    #>
    function getHostFqdnAndAddress($computerSystem) {
        $computerName = $computerSystem.DNSHostName
        if (!$computerName) {
            $computerName = $computerSystem.Name
        }
    
        return getComputerFqdnAndAddress $computerName
    }
    
    <#
    
    .SYNOPSIS
    Are the needed management CIM interfaces available on the current server or client.
    
    .DESCRIPTION
    Check for the presence of the required server management CIM interfaces.
    
    #>
    function getManagementToolsSupportInformation() {
        $returnValues = @{}
    
        $returnValues.ManagementToolsAvailable = $false
        $returnValues.ServerManagerAvailable = $false
    
        $namespaces = Get-CimInstance -Namespace root/microsoft/windows -ClassName __NAMESPACE -ErrorAction SilentlyContinue
    
        if ($namespaces) {
            $returnValues.ManagementToolsAvailable = !!($namespaces | Where-Object { $_.Name -ieq "ManagementTools" })
            $returnValues.ServerManagerAvailable = !!($namespaces | Where-Object { $_.Name -ieq "ServerManager" })
        }
    
        return $returnValues
    }
    
    <#
    
    .SYNOPSIS
    Check the remote app enabled or not.
    
    .DESCRIPTION
    Check the remote app enabled or not.
    
    #>
    function isRemoteAppEnabled() {
        Set-Variable key -Option Constant -Value "HKLM:\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Terminal Server\\TSAppAllowList"
    
        $registryKeyValue = Get-ItemProperty -Path $key -Name fDisabledAllowList -ErrorAction SilentlyContinue
    
        if (-not $registryKeyValue) {
            return $false
        }
        return $registryKeyValue.fDisabledAllowList -eq 1
    }
    
    <#
    
    .SYNOPSIS
    Check the remote app enabled or not.
    
    .DESCRIPTION
    Check the remote app enabled or not.
    
    #>
    
    <#
    c
    .SYNOPSIS
    Get the Win32_OperatingSystem information
    
    .DESCRIPTION
    Get the Win32_OperatingSystem instance and filter the results to just the required properties.
    This filtering will make the response payload much smaller.
    
    #>
    function getOperatingSystemInfo() {
        return Get-CimInstance Win32_OperatingSystem | Microsoft.PowerShell.Utility\Select-Object csName, Caption, OperatingSystemSKU, Version, ProductType
    }
    
    <#
    
    .SYNOPSIS
    Get the Win32_ComputerSystem information
    
    .DESCRIPTION
    Get the Win32_ComputerSystem instance and filter the results to just the required properties.
    This filtering will make the response payload much smaller.
    
    #>
    function getComputerSystemInfo() {
        return Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue | `
            Microsoft.PowerShell.Utility\Select-Object TotalPhysicalMemory, DomainRole, Manufacturer, Model, NumberOfLogicalProcessors, Domain, Workgroup, DNSHostName, Name, PartOfDomain
    }
    
    ###########################################################################
    # main()
    ###########################################################################
    
    $operatingSystem = getOperatingSystemInfo
    $computerSystem = getComputerSystemInfo
    $isAdministrator = isUserAnAdministrator
    $fqdnAndAddress = getHostFqdnAndAddress $computerSystem
    $hostname = hostname
    $netbios = $env:ComputerName
    $managementToolsInformation = getManagementToolsSupportInformation
    $isWmfInstalled = isWMF5Installed $operatingSystem.Version
    $clusterInformation = getClusterInformation -ErrorAction SilentlyContinue
    $isHyperVPowershellInstalled = isHyperVPowerShellSupportInstalled
    $isHyperVRoleInstalled = isHyperVRoleInstalled
    $isCredSSPEnabled = isCredSSPEnabled
    $isRemoteAppEnabled = isRemoteAppEnabled
    
    $result = New-Object PSObject
    $result | Add-Member -MemberType NoteProperty -Name 'IsAdministrator' -Value $isAdministrator
    $result | Add-Member -MemberType NoteProperty -Name 'OperatingSystem' -Value $operatingSystem
    $result | Add-Member -MemberType NoteProperty -Name 'ComputerSystem' -Value $computerSystem
    $result | Add-Member -MemberType NoteProperty -Name 'Fqdn' -Value $fqdnAndAddress.Fqdn
    $result | Add-Member -MemberType NoteProperty -Name 'AddressList' -Value $fqdnAndAddress.AddressList
    $result | Add-Member -MemberType NoteProperty -Name 'Hostname' -Value $hostname
    $result | Add-Member -MemberType NoteProperty -Name 'NetBios' -Value $netbios
    $result | Add-Member -MemberType NoteProperty -Name 'IsManagementToolsAvailable' -Value $managementToolsInformation.ManagementToolsAvailable
    $result | Add-Member -MemberType NoteProperty -Name 'IsServerManagerAvailable' -Value $managementToolsInformation.ServerManagerAvailable
    $result | Add-Member -MemberType NoteProperty -Name 'IsWmfInstalled' -Value $isWmfInstalled
    $result | Add-Member -MemberType NoteProperty -Name 'IsCluster' -Value $clusterInformation.IsCluster
    $result | Add-Member -MemberType NoteProperty -Name 'ClusterFqdn' -Value $clusterInformation.ClusterFqdn
    $result | Add-Member -MemberType NoteProperty -Name 'IsS2dEnabled' -Value $clusterInformation.IsS2dEnabled
    $result | Add-Member -MemberType NoteProperty -Name 'IsHyperVRoleInstalled' -Value $isHyperVRoleInstalled
    $result | Add-Member -MemberType NoteProperty -Name 'IsHyperVPowershellInstalled' -Value $isHyperVPowershellInstalled
    $result | Add-Member -MemberType NoteProperty -Name 'IsCredSSPEnabled' -Value $isCredSSPEnabled
    $result | Add-Member -MemberType NoteProperty -Name 'IsRemoteAppEnabled' -Value $isRemoteAppEnabled
    
    $result
    
    }
    ## [END] Get-ServerInventory ##
}
function Get-ADChangeEvent {
#requires -version 3.0

#region IncludePrivate

#endregion IncludePrivate

#region Functions

function Expand-WinEvent {
    <#
    .SYNOPSIS
    Configured EventLogRecords into EventLogExpandedRecords that are easier to parse
    .DESCRIPTION
    Convert eventRecords into a more parseable object format, including custom event properties
    By expanding the Event XML data into individual properties, this makes WinEvents easier to work with and parse
     
    .NOTES
    Inspired by http://blogs.technet.com/b/ashleymcglone/archive/2013/08/28/powershell-get-winevent-xml-madness-getting-details-from-event-logs.aspx
    .EXAMPLE
    PS C:\> Get-Winevent -LogName Application | Expand-WinEvent
    Takes all application logs and expands their properties.
    #>

    param (
        #Specifies an event generated by Get-WinEvent. WARNING: DOES NOT WORK WITH GET-EVENTLOG
        [Parameter(Mandatory, ValueFromPipeline)]
        [System.Diagnostics.Eventing.Reader.EventLogRecord]$EventLogRecord,
        #If specified, outputs a hashtable of object properties rather than the object itself. Useful for creating a subtype.
        [Switch]$OutHashTable
    )

    begin {
        #Define the event type and default display properties
        $CustomEventRecordType = "System.Diagnostics.Eventing.Reader.EventLogRecordExpanded"
        Update-TypeData -TypeName $CustomEventRecordType -DefaultDisplayPropertySet TimeCreated, ID, ProviderName, TaskDisplayName -Force
    } #Begin

    process {
        $EventLogRecord | ForEach-Object {

            $EventProperties = [ordered]@{
                TimeCreated      = $PSItem.TimeCreated
                ID               = $PSItem.ID
                LevelDisplayName = $PSItem.LevelDisplayName
                ProviderName     = $PSItem.ProviderName
                TaskDisplayName  = if ($PSItem.TaskDisplayName) { $PSItem.TaskDisplayName } else { $null }
                MachineName      = $PSItem.MachineName
                Message          = $PSItem.Message
                RawEvent         = $PSItem
            }


            #Add all the attribute properties of the event object. This is dynamic and works for all events.
            $i = 1
            ([xml]$PSItem.toxml()).Event.EventData.Data |  ForEach-Object {
                #Skip in the event this is a classic log with no attribute properties
                if ($PSItem) {

                    #If the data is unstructured, just create as "Property1","Property2", etc.
                    if ($PSItem -isnot [System.XML.XMLElement]) {
                        $PropertyName = "Property" + $i
                        $EventProperties.Add($PropertyName, $PSItem)
                        $i++
                    } 
                    
                    else {
                        if ($EventProperties.Contains($PSItem.Name)) {
                            $PropertyName = "property" + $PSItem.Name
                        }
                        else { $PropertyName = $PSItem.Name }
                        $EventProperties.Add($PropertyName, $PSItem."#text")
                    }
                } #If ($PSItem)
            } #ForEach
            
            if ($OutHashTable) {
                $EventProperties
            } 
            else {
                $result = [PSCustomObject]$EventProperties
                #Assign custom type so it shows properly in Get-Member
                $result.PSTypeNames.Insert(0, $customEventRecordType)
                $result
            }
        } #ForEach
    } #Process
} #Expand-WinEvent

function Format-ADChangeWinEvent {
    <#
       .SYNOPSIS
       Configured EventLogRecords into easier to parse entries 
    #>
    param(
        #Specifies an event generated by Get-WinEvent. WARNING: DOES NOT WORK WITH GET-EVENTLOG
        [Parameter(Mandatory, ValueFromPipeline)]
        [System.Diagnostics.Eventing.Reader.EventLogRecord]$EventLogRecord
    )

    begin {
        #Define the base event record type
        $defaultCustomEventRecordType = "System.Diagnostics.Eventing.Reader.EventLogRecordExpanded"
        Update-TypeData -TypeName $defaultCustomEventRecordType -DefaultDisplayPropertySet TimeCreated, ID, ProviderName, TaskDisplayName -Force
    }
    
    process {
        $EventLogRecord | Expand-WinEvent -OutHashTable | ForEach-Object {
            $EventProperties = $PSItem
            
            #Add additional properties based on the Event type
            switch ($PSItem.ID) {
                5136 {
                    #Directory Object Modified
                    $customEventRecordType = $defaultCustomEventRecordType + ".DSObjectModified"
                    #Make the output easier to read without affecting structure
                    Update-TypeData -TypeName $customEventRecordType -DefaultDisplayPropertySet TimeCreated, MachineName, ID, TaskDisplayName, Requestor, Action, Target, AttributeLDAPDisplayName, AttributeValue, Location -Force

                    $EventProperties.Requestor = $EventProperties.SubjectDomainName + "\" + $EventProperties.SubjectUserName
                    $EventProperties.Target = $EventProperties.objectdn -replace "(\w\w\=)(.*?),(.*)", '$2'
                    $EventProperties.Location = $EventProperties.objectdn -replace "(\w\w\=)(.*?),(.*)", '$3'

                    #Do some text replacement for the Operation
                    #TODO: This should use a .NET function rather than script-hardcoded values. No idea what the function would be though.
                    $EventAction = switch ($EventProperties.OperationType) {
                        '%%14674' { "DSAttributeAdd" }
                        '%%14675' { "DSAttributeDelete" }
                        default { $EventAction = $null }
                    }
                    $EventProperties.Action = $EventAction
                }

                5137 {
                    #Directory Object Created
                    $customEventRecordType = $defaultCustomEventRecordType + ".DSObjectCreate"
                    
                    #Make the output easier to read without affecting structure
                    Update-TypeData -TypeName $customEventRecordType -DefaultDisplayPropertySet TimeCreated, MachineName, ID, TaskDisplayName, Requestor, Action, Target, AttributeLDAPDisplayName, AttributeValue, Location -Force

                    $EventProperties.Requestor = $EventProperties.SubjectDomainName + "\" + $EventProperties.SubjectUserName
                    $EventProperties.Target = $EventProperties.objectdn -replace "(\w\w\=)(.*?),(.*)", '$2'
                    $EventProperties.Location = $EventProperties.objectdn -replace "(\w\w\=)(.*?),(.*)", '$3'
                    $EventProperties.Action = "DSObjectCreate"
                }

                5139 {
                    #Directory Object Moved
                    $customEventRecordType = $defaultCustomEventRecordType + ".DSObjectMove"
                    
                    #Make the output easier to read without affecting structure
                    Update-TypeData -TypeName $customEventRecordType -DefaultDisplayPropertySet TimeCreated, MachineName, ID, TaskDisplayName, Requestor, Action, OldObjectDN, NewObjectDN -Force

                    $EventProperties.Requestor = $EventProperties.SubjectDomainName + "\" + $EventProperties.SubjectUserName
                    $EventProperties.Target = $EventProperties.objectdn -replace "(\w\w\=)(.*?),(.*)", '$2'
                    $EventProperties.Location = $EventProperties.objectdn -replace "(\w\w\=)(.*?),(.*)", '$3'
                    $EventProperties.Action = "DSObjectCreate"
                }

                5141 {
                    #Directory Object Deleted
                    $customEventRecordType = $defaultCustomEventRecordType + ".DSObjectDelete"
                    
                    #Make the output easier to read without affecting structure
                    Update-TypeData -TypeName $customEventRecordType -DefaultDisplayPropertySet TimeCreated, MachineName, ID, TaskDisplayName, Requestor, Action, Target, AttributeLDAPDisplayName, AttributeValue, Location -Force

                    $EventProperties.Requestor = $EventProperties.SubjectDomainName + "\" + $EventProperties.SubjectUserName
                    $EventProperties.Target = $EventProperties.objectdn -replace "(\w\w\=)(.*?),(.*)", '$2'
                    $EventProperties.Location = $EventProperties.objectdn -replace "(\w\w\=)(.*?),(.*)", '$3'
                    $EventProperties.Action = "DSObjectDelete"
                }

                default { $customEventRecordType = $defaultCustomEventRecordType }
                
            } #Switch


            $result = [PSCustomObject]$EventProperties
            $result.PSTypeNames.Insert(0, $customEventRecordType)
            $result
        } #Foreach
    } #Process

} #Format-ADChangeEvent
#endregion Functions


#region Main
$filterHashTable = @{
    StartTime = (Get-Date).addhours(-200)
    EndTime   = (Get-Date)
    ID        = 5136, 5137, 5139, 5141
    LogName   = "Microsoft-Windows-DirectoryServices-Deployment/Operational"
}
Get-WinEvent -ComputerName DANTOOINE -filterhashtable $filterHashTable -maxevents 30 | Format-ADChangeWinEvent | Format-Table requestor, target
#endregion Main
}
function Get-ADUserAccount {
<#
.SYNOPSIS
    Retrieves Active Directory user account details based on different parameters.

.DESCRIPTION
    The Get-ADUserAccount function retrieves Active Directory user account details based on the provided parameters. 
    It supports searching by SamAccountName, Surname, and GivenName. The function can also filter results based on 
    whether the account is enabled or disabled. Additionally, it provides the option to retrieve only password-related 
    details for the user accounts.

.PARAMETER SamAccountName
    Specifies the logon account detail of the users. This parameter accepts wildcards and is used to filter user accounts 
    based on the SamAccountName property.

.PARAMETER Surname
    Specifies the surname of the users. This parameter accepts wildcards and is used to filter user accounts based on the 
    Surname property.

.PARAMETER GivenName
    Specifies the given name of the users. This parameter accepts wildcards and is used to filter user accounts based on the 
    GivenName property.

.PARAMETER PasswordDetailsOnly
    Specifies whether to retrieve only password-related details for the user accounts. If this switch is used, the function 
    will only return the Name, SamAccountName, Enabled, PasswordNeverExpires, PasswordLastSet, and AccountExpirationDate 
    properties.

.PARAMETER IsEnabled
    Specifies whether to retrieve only enabled user accounts. If this switch is used, the function will only return user 
    accounts that are enabled.

.OUTPUTS
    System.String
    The function outputs a string representing the user account details. The properties included in the output can vary 
    depending on the parameters used.

.EXAMPLE
    Get-ADUserAccount -SamAccountName "john.doe"
    Retrieves the user account details for the user with the SamAccountName "john.doe".

.EXAMPLE
    Get-ADUserAccount -Surname "Doe" -IsEnabled
    Retrieves the enabled user account details for all users with the surname "Doe".

.EXAMPLE
    Get-ADUserAccount -GivenName "John" -PasswordDetailsOnly
    Retrieves only the password-related details for all users with the given name "John".

#>
function Get-ADUserAccount {
    [CmdletBinding(DefaultParameterSetName = 'Default',
        SupportsShouldProcess = $true)]
    [OutputType([string])]
    param
    (
        [Parameter(ParameterSetName = 'Identity',
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Enter the Users logon account detail. This will likely be the same as the EmployeeID. Wildcards are supported.')]
        [SupportsWildcards()]
        [ValidateNotNullOrEmpty()]
        [Alias('sam')]
        [string[]]$SamAccountName,

        [Parameter(ParameterSetName = 'Surname',
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Enter the Users Surname. This will return all accounts that match the entered value. Wildcards are supported.')]
        [SupportsWildcards()]
        [ValidateNotNullOrEmpty()]
        [Alias('sn')]
        [string[]]$Surname,
        
        [Parameter(ParameterSetName = 'GivenName',
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Enter the Users GivenName. This will return all accounts that match the entered value. Wildcards are supported.')]
        [SupportsWildcards()]
        [ValidateNotNullOrEmpty()]
        [Alias('gn')]
        [string[]]$GivenName,

        [Parameter()]
        [switch]$PasswordDetailsOnly,

        [Parameter()]
        [switch]$IsEnabled
    )
    
    BEGIN { }
    
    PROCESS {
        if ($PasswordDetailsOnly) {
            $propertiesToSelect = 'Name', 'SamAccountName', 'Enabled', 'PasswordNeverExpires', 'PasswordLastSet', 'AccountExpirationDate'
        }
        else {
            $propertiesToSelect = 'Name', 'SamAccountName', 'GivenName', 'Surname', 'DisplayName', 'EmployeeID', 'Description', 'Title', 'Company', 'Department', 'departmentNumber', 'Office', 'physicalDeliveryOfficeName', 'StreetAddress', 'City', 'State', 'Country', 'PostalCode', 'extensionAttribute*', 'Manager', 'distinguishedName', 'HomePhone', 'OfficePhone', 'MobilePhone', 'Fax', 'mail', 'mailNickname', 'EmailAddress', 'UserPrincipalName', 'proxyAddresses', 'HomePage', 'ProfilePath', 'HomeDirectory', 'HomeDrive', 'ScriptPath', 'AccountExpirationDate', 'PasswordNeverExpires', 'Enabled', 'CannotChangePassword', 'ChangePasswordAtLogon', 'PasswordNotRequired', 'PasswordLastSet', 'LastLogonDate', 'LastBadPasswordAttempt', 'whenChanged', 'whenCreated', 'directReports', 'MemberOf'
        }

        # Add password age to the properties to select
        $propertiesToSelect += @{Name = 'PasswordAge'; Expression = { if ($_.PasswordLastSet) { ((Get-Date) - $_.PasswordLastSet).Days } } }

        if ($SamAccountName) {
            if ($PSCmdlet.ShouldProcess("$($SamAccountName)", "searching AD for user details.")) {
                try {
                    Get-ADUser -Filter "SamAccountName -like '$($SamAccountName)' -and Enabled -eq '$($IsEnabled.IsPresent)'" -Properties * | Select-Object -Property $propertiesToSelect
                }
                catch {
                    Write-Error -Message "$_"
                }
            }
        }

        if ($Surname) {
            if ($PSCmdlet.ShouldProcess("$($Surname)", "searching AD for user details.")) {
                try {
                    Get-ADUser -Filter "Surname -like '$Surname' -and Enabled -eq '$($IsEnabled.IsPresent)'" -Properties * | Select-Object -Property $propertiesToSelect
                }
                catch {
                    Write-Error -Message "$_"
                }
            }
        }

        if ($GivenName) {
            if ($PSCmdlet.ShouldProcess("$($GivenName)", "searching AD for user details.")) {
                try {
                    Get-ADUser -Filter "GivenName -like '$GivenName' -and Enabled -eq '$($IsEnabled.IsPresent)'" -Properties * | Select-Object -Property $propertiesToSelect
                }
                catch {
                    Write-Error -Message "$_"
                }
            }
        }
    }
            
    END { }
}
}
function Get-ADUserEmailAddress {
<#
.SYNOPSIS
Searches all attributes of an Active Directory (AD) User or Contact object for an email address and returns the object properties if found.

.DESCRIPTION
This function allows you to search for an email address or a SamAccountName in Active Directory. It accepts pipeline input and supports wildcards for both parameters. If a match is found, it returns the object properties of the matched user or contact.

.PARAMETER SamAccountName
Specifies the SamAccountName of the AD object to search for. This parameter supports wildcards and can accept multiple values.

.PARAMETER EmailAddress
Specifies the email address of the AD object to search for. This parameter supports wildcards and can accept multiple values.

.EXAMPLE
Get-ADUserEmailAddress -SamAccountName "john.doe"
Searches for the AD object with the SamAccountName "john.doe" and returns the object properties if found.

.EXAMPLE
Get-ADUserEmailAddress -EmailAddress "*@example.com"
Searches for the AD objects with email addresses ending with "@example.com" and returns the object properties if found.

.INPUTS
System.String

.OUTPUTS
System.Management.Automation.PSCustomObject

.NOTES
Author: Your Name
Date: Today's Date
Version: 1.0
#>

function Get-ADUserEmailAddress {
    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = 'Medium'
    )]
    param (
        [Parameter(Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Enter the AD object SamAccountName. This will return all accounts that match the entered value. Wildcards are supported.')]
        [SupportsWildcards()]
        [ValidateNotNullOrEmpty()]
        [Alias('sa')]
        [string[]]$SamAccountName,

        [Parameter(Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Enter the AD object EmailAddress. This will return all accounts that match the entered value. Wildcards are supported.')]
        [SupportsWildcards()]
        [ValidateNotNullOrEmpty()]
        [Alias('mail')]
        [string[]]$EmailAddress
    )
    BEGIN { }

    PROCESS {
        if ($SamAccountName) {
            if ($PSCmdlet.ShouldProcess("$($SamAccountName)", "searching AD for user details.")) {
                try {
                    Get-ADUser -Filter "SamAccountName -like '$($SamAccountName)' " -Properties * | Select-Object -Property SamAccountName, GivenName, Surname, DisplayName, EmployeeID, Description, Title, Company, Department, departmentNumber, Office, physicalDeliveryOfficeName, StreetAddress, City, State, Country, PostalCode, extensionAttribute*, Manager, distinguishedName, HomePhone, OfficePhone, MobilePhone, Fax, mail, mailNickname, EmailAddress, UserPrincipalName, proxyAddresses, HomePage, ProfilePath, HomeDirectory, HomeDrive, ScriptPath, AccountExpirationDate, PasswordNeverExpires, Enabled, CannotChangePassword, ChangePasswordAtLogon, PasswordNotRequired, PasswordLastSet, LastLogonDate, LastBadPasswordAttempt, whenChanged, whenCreated, directReports, MemberOf
                }
                catch {
                    Write-Error -Message "$_"
                }
            }
        }

        if ($EmailAddress) {
            if ($PSCmdlet.ShouldProcess("$($EmailAddress)", "searching AD for user details.")) {
                try {
                    Get-ADUser -Filter " EmailAddress -like '$EmailAddress' " -Properties * | Select-Object -Property SamAccountName, GivenName, Surname, DisplayName, EmployeeID, Description, Title, Company, Department, departmentNumber, Office, physicalDeliveryOfficeName, StreetAddress, City, State, Country, PostalCode, extensionAttribute*, Manager, distinguishedName, HomePhone, OfficePhone, MobilePhone, Fax, mail, mailNickname, EmailAddress, UserPrincipalName, proxyAddresses, HomePage, ProfilePath, HomeDirectory, HomeDrive, ScriptPath, AccountExpirationDate, PasswordNeverExpires, Enabled, CannotChangePassword, ChangePasswordAtLogon, PasswordNotRequired, PasswordLastSet, LastLogonDate, LastBadPasswordAttempt, whenChanged, whenCreated, directReports, MemberOf
                }
                catch {
                    Write-Error -Message "$_"
                }
            }
        }
    }
}
}
function Get-ADUserPasswordStatus {
function Get-ADUserPasswordStatus {
    <#
    .SYNOPSIS
        Gets the password status of an Active Directory user account.

    .DESCRIPTION
        Gets the password status of an Active Directory user account.

    .PARAMETER SamAccountName
        The SamAccountName of the user account.

    .PARAMETER Identity
        The Identity of the user account.

    .PARAMETER Domain
        The domain of the user account.

    .EXAMPLE
        Get-ADUserPasswordStatus -SamAccountName 'jsmith'

    .EXAMPLE
        Get-ADUserPasswordStatus -SamAccountName 'jsmith' -Domain 'contoso.com'

    .NOTES
        This function retrieves the password status of an Active Directory user account.
        It requires the SamAccountName parameter to specify the user account.
        The Identity parameter can also be used instead of SamAccountName.
        The Domain parameter is optional and defaults to the current user's domain.

    .LINK
        https://docs.microsoft.com/en-us/powershell/module/activedirectory/get-aduser

    #>
    [CmdletBinding( DefaultParameterSetName = 'Identity', SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]

    Param(
        [Parameter( Mandatory = $true, Position = 0, ParameterSetName = 'Identity' )]
        [string]$SamAccountName,

        [Parameter( Mandatory = $false, Position = 1, ParameterSetName = 'Identity' )]
        [string]$Domain = $env:USERDOMAIN
    )

    Process {
        if ($PSCmdlet.ShouldProcess("Target", "Operation")) {
            
            try {
                $ADUser = Get-ADUser -Identity $SamAccountName -Server $Domain -Properties PasswordExpired, PasswordNeverExpires, PasswordLastSet, PasswordNotRequired, AccountExpirationDate, LockedOut, Enabled

                $PasswordStatus = [ordered]@{
                    SamAccountName        = $ADUser.SamAccountName
                    PasswordAgeDays       = [math]::Round((New-TimeSpan -Start $ADUser.PasswordLastSet -End (Get-Date)).TotalDays, 2)
                    Enabled               = $ADUser.Enabled
                    AccountExpirationDate = $ADUser.AccountExpirationDate
                    PasswordLastSet       = $ADUser.PasswordLastSet
                    LockedOut             = $ADUser.LockedOut
                    PasswordExpired       = $ADUser.PasswordExpired
                    PasswordNeverExpires  = $ADUser.PasswordNeverExpires
                    PasswordNotRequired   = $ADUser.PasswordNotRequired
                }
                New-Object -TypeName psobject -Property $PasswordStatus
            }
            catch {
                Write-Error -Message "Failed to get password status for user '$SamAccountName' in domain '$Domain'."
            }
        }
    }
}
}
function Get-DuckDuckGoSearch {
function Get-DuckDuckGoSearch {
    Start-Process "https://duckduckgo.com/?q=$args"
}
}
function Get-GoogleDirections {
function Get-GoogleDirections {
    param([string] $From, [String] $To)

    process {
        Start-Process "https://www.google.com/maps/dir/$From/$To/"
    }
}
}
function Get-GoogleSearch {
function Get-GoogleSearch {
    Start-Process "https://www.google.co.uk/search?q=$args"
}
}
function Get-MgMFAStatus {
function Get-MgMFAStatus {
  <#
.Synopsis
  Get the MFA status for all users or a single user with Microsoft Graph

.DESCRIPTION
  This script will get the Azure MFA Status for your users. You can query all the users, admins only or a single user.
   
	It will return the MFA Status, MFA type and registered devices.

  Note: Default MFA device is currently not supported https://docs.microsoft.com/en-us/graph/api/resources/authenticationmethods-overview?view=graph-rest-beta
        Hardwaretoken is not yet supported

.NOTES
  Name: Get-MgMFAStatus
  Author: R. Mens - LazyAdmin.nl
  Version: 1.1
  DateCreated: Jun 2022
  Purpose/Change: Add Directory.Read.All scope

.LINK
  https://lazyadmin.nl

.EXAMPLE
  Get-MgMFAStatus

  Get the MFA Status of all enabled and licensed users and check if there are an admin or not

.EXAMPLE
  Get-MgMFAStatus -UserPrincipalName 'johndoe@contoso.com','janedoe@contoso.com'

  Get the MFA Status for the users John Doe and Jane Doe

.EXAMPLE
  Get-MgMFAStatus -withOutMFAOnly

  Get only the licensed and enabled users that don't have MFA enabled

.EXAMPLE
  Get-MgMFAStatus -adminsOnly

  Get the MFA Status of the admins only

.EXAMPLE
  Get-MgUser -Filter "country eq 'Netherlands'" | ForEach-Object { Get-MgMFAStatus -UserPrincipalName $_.UserPrincipalName }

  Get the MFA status for all users in the Country The Netherlands. You can use a similar approach to run this
  for a department only.

.EXAMPLE
  Get-MgMFAStatus -withOutMFAOnly| Export-CSV c:\temp\userwithoutmfa.csv -noTypeInformation

  Get all users without MFA and export them to a CSV file
#>

  [CmdletBinding(DefaultParameterSetName = "Default")]
  param(
    [Parameter(
      Mandatory = $false,
      ParameterSetName = "UserPrincipalName",
      HelpMessage = "Enter a single UserPrincipalName or a comma separted list of UserPrincipalNames",
      Position = 0
    )]
    [string[]]$UserPrincipalName,

    [Parameter(
      Mandatory = $false,
      ValueFromPipeline = $false,
      ParameterSetName = "AdminsOnly"
    )]
    # Get only the users that are an admin
    [switch]$adminsOnly = $false,

    [Parameter(
      Mandatory = $false,
      ValueFromPipeline = $false,
      ParameterSetName = "Licensed"
    )]
    # Check only the MFA status of users that have license
    [switch]$IsLicensed = $false,

    [Parameter(
      Mandatory = $false,
      ValueFromPipeline = $true,
      ValueFromPipelineByPropertyName = $true,
      ParameterSetName = "withOutMFAOnly"
    )]
    # Get only the users that don't have MFA enabled
    [switch]$withOutMFAOnly = $false,

    [Parameter(
      Mandatory = $false,
      ValueFromPipeline = $false
    )]
    # Check if a user is an admin. Set to $false to skip the check
    [switch]$listAdmins = $false,

    [Parameter(
      Mandatory = $false,
      HelpMessage = "Enter path to save the CSV file"
    )]
    [string]$path = ".\MFAStatus-$((Get-Date -format "MMM-dd-yyyy").ToString()).csv"
  )

  Function Get-MgAdmins {
    <#
  .SYNOPSIS
    Get all user with an Admin role
  #>
    process {
      $admins = Get-MgDirectoryRole | Select-Object DisplayName, Id | 
      ForEach-Object -Process { $role = $_.DisplayName; Get-MgDirectoryRoleMember -DirectoryRoleId $_.id | 
        Where-Object -FilterScript { $_.AdditionalProperties."@odata.type" -eq "#microsoft.graph.user" } | 
        ForEach-Object -Process { Get-MgUser -userid $_.id }
      } | 
      Select-Object -Property @{Name = "Role"; Expression = { $role } }, DisplayName, UserPrincipalName, Mail, Id | Sort-Object -Property Mail -Unique
    
      return $admins
    }
  }

  Function Get-Users {
    <#
  .SYNOPSIS
    Get users from the requested DN
  #>
    process {
      # Set the properties to retrieve
      $select = @(
        'id',
        'DisplayName',
        'userprincipalname',
        'mail'
      )

      $properties = $select + "AssignedLicenses"

      # Get enabled, disabled or both users
      switch ($enabled) {
        "true" { $filter = "AccountEnabled eq true and UserType eq 'member'" }
        "false" { $filter = "AccountEnabled eq false and UserType eq 'member'" }
        "both" { $filter = "UserType eq 'member'" }
      }
    
      # Check if UserPrincipalName(s) are given
      if ($UserPrincipalName) {
        Write-Output "Get users by name"

        $users = @()
        foreach ($user in $UserPrincipalName) {
          try {
            $users += Get-MgUser -UserId $user -Property $properties | Select-Object -Property $select -ErrorAction Stop
          }
          catch {
            [PSCustomObject]@{
              DisplayName       = " - Not found"
              UserPrincipalName = $User
              isAdmin           = $null
              MFAEnabled        = $null
            }
          }
        }
      }
      elseif ($adminsOnly) {
        Write-Output "Get admins only"

        $users = @()
        foreach ($admin in $admins) {
          $users += Get-MgUser -UserId $admin.UserPrincipalName -Property $properties | Select-Object $select
        }
      }
      else {
        if ($IsLicensed) {
          # Get only licensed users
          $users = Get-MgUser -Filter $filter -Property $properties -all | Where-Object { ($_.AssignedLicenses).count -gt 0 } | Select-Object $select
        }
        else {
          $users = Get-MgUser -Filter $filter -Property $properties -all | Select-Object $select
        }
      }
      return $users
    }
  }

  Function Get-MFAMethods {
    <#
      .SYNOPSIS
        Get the MFA status of the user
    #>
    param(
      [Parameter(Mandatory = $true)] $userId
    )
    process {
      # Get MFA details for each user
      [array]$mfaData = Get-MgUserAuthenticationMethod -UserId $userId
  
      # Create MFA details object
      $mfaMethods = [PSCustomObject][Ordered]@{
        status                  = "-"
        authApp                 = "-"
        phoneAuth               = "-"
        fido                    = "-"
        helloForBusiness        = "-"
        emailAuth               = "-"
        tempPass                = "-"
        passwordLess            = "-"
        softwareAuth            = "-"
        authDevice              = "-"
        authPhoneNr             = "-"
        SSPREmail               = "-"
        fidoDetails             = "-"
        helloForBusinessDetails = "-"
        tempPassDetails         = "-"
        passwordLessDetails     = "-"
      }
  
      ForEach ($method in $mfaData) {
        Switch ($method.AdditionalProperties["@odata.type"]) {
          "#microsoft.graph.microsoftAuthenticatorAuthenticationMethod" { 
            # Microsoft Authenticator App
            $mfaMethods.authApp = $true
            $mfaMethods.authDevice = $method.AdditionalProperties["displayName"] 
            $mfaMethods.status = "enabled"
          } 
          "#microsoft.graph.phoneAuthenticationMethod" { 
            # Phone authentication
            $mfaMethods.phoneAuth = $true
            $mfaMethods.authPhoneNr = $method.AdditionalProperties["phoneType", "phoneNumber"] -join ' '
            $mfaMethods.status = "enabled"
          } 
          "#microsoft.graph.fido2AuthenticationMethod" { 
            # FIDO2 key
            $mfaMethods.fido = $true
            $fifoDetails = $method.AdditionalProperties["model"]
            $mfaMethods.fidoDetails = $fifoDetails
            $mfaMethods.status = "enabled"
          } 
          "#microsoft.graph.passwordAuthenticationMethod" { 
            # Password
            # When only the password is set, then MFA is disabled.
            if ($mfaMethods.status -ne "enabled") { $mfaMethods.status = "disabled" }
          }
          "#microsoft.graph.windowsHelloForBusinessAuthenticationMethod" { 
            # Windows Hello
            $mfaMethods.helloForBusiness = $true
            $helloForBusinessDetails = $method.AdditionalProperties["displayName"]
            $mfaMethods.helloForBusinessDetails = $helloForBusinessDetails
            $mfaMethods.status = "enabled"
          } 
          "#microsoft.graph.emailAuthenticationMethod" { 
            # Email Authentication
            $mfaMethods.emailAuth = $true
            $mfaMethods.SSPREmail = $method.AdditionalProperties["emailAddress"] 
            $mfaMethods.status = "enabled"
          }               
          "microsoft.graph.temporaryAccessPassAuthenticationMethod" { 
            # Temporary Access pass
            $mfaMethods.tempPass = $true
            $tempPassDetails = $method.AdditionalProperties["lifetimeInMinutes"]
            $mfaMethods.tempPassDetails = $tempPassDetails
            $mfaMethods.status = "enabled"
          }
          "#microsoft.graph.passwordlessMicrosoftAuthenticatorAuthenticationMethod" { 
            # Passwordless
            $mfaMethods.passwordLess = $true
            $passwordLessDetails = $method.AdditionalProperties["displayName"]
            $mfaMethods.passwordLessDetails = $passwordLessDetails
            $mfaMethods.status = "enabled"
          }
          "#microsoft.graph.softwareOathAuthenticationMethod" { 
            # ThirdPartyAuthenticator
            $mfaMethods.softwareAuth = $true
            $mfaMethods.status = "enabled"
          }
        }
      }
      Return $mfaMethods
    }
  }

  Function Get-Manager {
    <#
    .SYNOPSIS
      Get the manager users
  #>
    param(
      [Parameter(Mandatory = $true)] $userId
    )
    process {
      $manager = Get-MgUser -UserId $userId -ExpandProperty manager | Select-Object @{Name = 'name'; Expression = { $_.Manager.AdditionalProperties.displayName } }
      return $manager.name
    }
  }

  Function Get-MFAStatusUsers {
    <#
    .SYNOPSIS
      Get all AD users
  #>
    process {

      # Collect users
      $users = Get-Users
    
      # Collect and loop through all users
      $users | ForEach-Object {
      
        $mfaMethods = Get-MFAMethods -userId $_.id
        $manager = Get-Manager -userId $_.id

        if ($withOutMFAOnly) {
          if ($mfaMethods.status -eq "disabled") {
            [PSCustomObject]@{
              "Name"            = $_.DisplayName
              Emailaddress      = $_.mail
              UserPrincipalName = $_.UserPrincipalName
              isAdmin           = if ($listAdmins -and ($admins.UserPrincipalName -match $_.UserPrincipalName)) { $true } else { "-" }
              MFAEnabled        = $false
              "Phone number"    = $mfaMethods.authPhoneNr
              "Email for SSPR"  = $mfaMethods.SSPREmail
            }
          }
        }
        else {
          [pscustomobject]@{
            "Name"                  = $_.DisplayName
            Emailaddress            = $_.mail
            UserPrincipalName       = $_.UserPrincipalName
            isAdmin                 = if ($listAdmins -and ($admins.UserPrincipalName -match $_.UserPrincipalName)) { $true } else { "-" }
            "MFA Status"            = $mfaMethods.status
            # "MFA Default type" = ""  - Not yet supported by MgGraph
            "Phone Authentication"  = $mfaMethods.phoneAuth
            "Authenticator App"     = $mfaMethods.authApp
            "Passwordless"          = $mfaMethods.passwordLess
            "Hello for Business"    = $mfaMethods.helloForBusiness
            "FIDO2 Security Key"    = $mfaMethods.fido
            "Temporary Access Pass" = $mfaMethods.tempPass
            "Authenticator device"  = $mfaMethods.authDevice
            "Phone number"          = $mfaMethods.authPhoneNr
            "Email for SSPR"        = $mfaMethods.SSPREmail
            "Manager"               = $manager
          }
        }
      }
    }
  }

  # Get Admins
  # Get all users with admin role
  $admins = $null

  if (($listAdmins) -or ($adminsOnly)) {
    $admins = Get-MgAdmins
  } 

  # Get MFA Status
  Get-MFAStatusUsers | Sort-Object Name | Export-CSV -Path $path -NoTypeInformation

}
}
function Get-MGUsers-Script {
<#
.SYNOPSIS
  Get all Azure AD Users using Microsoft Graph with properties and export to CSV
.DESCRIPTION
  This script collects all Azure Active Directory users with the most important properties. By default it will only
  get the enabled users, manager of the user and searches the whole domain.
.OUTPUTS
  CSV with Azure Active Directory Users
.NOTES
  Version:        1.0
  Author:         R. Mens - LazyAdmin.nl
  Creation Date:  15 feb 2022
  Purpose/Change: Initial script development
.EXAMPLE
  Get all AzureAD users from the whole Domain
   .\Get-MgUsers.ps1 -path c:\temp\users.csv
.EXAMPLE
  Get enabled and disabled users
   .\Get-MgUsers.ps1 -enabled both -path c:\temp\users.csv
   Other options are : true or false
.EXAMPLE
  Don't lookup the managers display name
  .\Get-MgUsers -getManager:$false -path c:\temp\users.csv
#>

param(
  [Parameter(
    Mandatory = $false,
    HelpMessage = "Get the users manager"
  )]
  [switch]$getManager = $true,

  [Parameter(
    Mandatory = $false,
    HelpMessage = "Get accounts that are enabled, disabled or both"
  )]
    [ValidateSet("true", "false", "both")]
  [string]$enabled = "true",

  [Parameter(
    Mandatory = $false,
    HelpMessage = "Enter path to save the CSV file"
  )]
  [string]$path = ".\ADUsers-$((Get-Date -format "MMM-dd-yyyy").ToString()).csv"
)


Function Get-Users {
    <#
    .SYNOPSIS
      Get users from the requested DN
    #>
    process{
      # Set the properties to retrieve
      $properties = @(
        'id',
        'DisplayName',
        'userprincipalname',
        'mail',
        'jobtitle',
        'department',
        'OfficeLocation',
        'MobilePhone',
        'BusinessPhones',
        'streetAddress',
        'city',
        'postalcode',
        'state',
        'country',
        'AccountEnabled',
        'CreatedDateTime'
      )

      If (($getManager.IsPresent)) {
        # Adding additional properties for the manager
        $select = $properties += @{Name = 'Manager'; Expression = {$_.Manager.AdditionalProperties.displayName}}
        $select += @{Name ="Phone"; Expression = {$_.BusinessPhones}} 
      }else{
        $select = $properties
      }

      # Get enabled, disabled or both users
      switch ($enabled)
      {
        "true" {$filter = "AccountEnabled eq true and UserType eq 'member'"}
        "false" {$filter = "AccountEnabled eq false and UserType eq 'member'"}
        "both" {$filter = "UserType eq 'member'"}
      }

      # Get the users
      Get-MgUser -Filter $filter -All -Property $properties -ExpandProperty Manager | Select-Object $select
    }
}


Function Get-AllMgUsers {
  <#
    .SYNOPSIS
      Get all AD users
  #>
  process {
    Write-Host "Collecting users" -ForegroundColor Cyan

    # Collect and loop through all users
    Get-Users | ForEach {

      [pscustomobject]@{
        "Name" = $_.DisplayName
        "UserPrincipalName" = $_.UserPrincipalName
        "Emailaddress" = $_.mail
        "Job title" = $_.JobTitle
        "Manager" = $_.Manager
        "Department" = $_.Department
        "Office" = $_.OfficeLocation
        "Phone" = $_.Phone
        "Mobile" = $_.MobilePhone
        "Enabled" = if ($_.AccountEnabled) {"enabled"} else {"disabled"}
        "Street" = $_.StreetAddress
        "City" = $_.City
        "Postal code" = $_.PostalCode
        "State" = $_.State
        "Country" = $_.Country
        "Account Created on" = $_.CreatedDateTime
      }
    }
  }
}

# Check if MS Graph module is installed
if (Get-InstalledModule Microsoft.Graph) {
  # Connect to MS Graph
  Connect-MgGraph -Scopes "User.Read.All"
}else{
  Write-Host "Microsoft Graph module not found - please install it" -ForegroundColor Black -BackgroundColor Yellow
  exit
}

Get-AllMgUsers | Sort-Object Name | Export-CSV -Path $path -NoTypeInformation

if ((Get-Item $path).Length -gt 0) {
  Write-Host "Report finished and saved in $path" -ForegroundColor Green

  # Open the CSV file
  Invoke-Item $path

}else{
  Write-Host "Failed to create report" -ForegroundColor Red
}
}
function GetPaydaySample {
# Write-Host "Next Pay Day:"
# Get-PayDay
# Write-Host "Mortgage End Date:"
# Get-PayDay -Day 28 -Month February -Year 2022
# Write-Host "Robs Mortgage Payment Calculator" -ForegroundColor Cyan -NoNewline:$false
# Write-Host "Mortgage End Date : " -ForegroundColor Yellow -NoNewline:$true
# Write-Host "$((Get-PayDay -Day 28 -Month February -Year 2030).Longdate)" -ForegroundColor Red
# $DaysLeft = (New-TimeSpan -Start (Get-Date) -End (Get-PayDay -Day 28 -Month February -Year 2030).Date).TotalDays.ToString('.00')
# if ($DaysLeft -gt ($DaysLeft / 3 * 2) ) {
# 	Write-Host "Mortgage Complete : " -ForegroundColor Yellow -NoNewline:$true
# 	Write-Host "$($DaysLeft)" -ForegroundColor Red -NoNewline:$true
# 	Write-Host " - Days Left" -ForegroundColor Red
# }
# elseif ($DaysLeft -lt ($DaysLeft / 2) ) {
# 	Write-Host "Mortgage Complete : " -ForegroundColor Yellow -NoNewline:$true
# 	Write-Host "Mortgage Complete = $($DaysLeft)" -ForegroundColor DarkGreen -NoNewline:$true
# 	Write-Host " - Days Left" -ForegroundColor DarkGreen
# }
# else { 
# 	Write-Host "Mortgage Complete : " -ForegroundColor Yellow -NoNewline:$true
# 	Write-Host "Mortgage Complete = $($DaysLeft)" -ForegroundColor Green -NoNewline:$true
# 	Write-Host " - Days Left" -ForegroundColor Green
# }


# $DaysLeft = (New-TimeSpan -Start (Get-Date) -End ((Get-Date).AddMonths("1").Date)).Days
# $properties = [ordered]@{
# 	PayDay   = (Get-PayDay).DayofWeek
# 	PayDate  = (Get-PayDay).LongDate
# 	DaysLeft = $DaysLeft
# }

# if ($DaysLeft -gt ($DaysLeft / 3 * 2) ) {
# 	Write-Host "Next PayDay Date   : $($properties.PayDay) $($properties.PayDate)" -ForegroundColor Blue -NoNewline:$false
# 	Write-Host "Days until Pay Day : $($DaysLeft) Days Left" -ForegroundColor Blue
# }
# elseif ($DaysLeft -lt ($DaysLeft / 2) ) {
# 	Write-Host "Next PayDay Date   : $($properties.PayDay) $($properties.PayDate)" -ForegroundColor Gray -NoNewline:$false
# 	Write-Host "Days until Pay Day : $($DaysLeft) Days Left" -ForegroundColor Gray
# }
# else { 
# 	Write-Host "Next PayDay Date   : $($properties.PayDay) $($properties.PayDate)" -ForegroundColor Green -NoNewline:$false
# 	Write-Host "Days until Pay Day : $($DaysLeft) Days Left" -ForegroundColor Green
# }

# $DaysLeft = (New-TimeSpan -Start (Get-Date) -End ((Get-Date).AddMonths("1").Date)).Days
# $properties = [ordered]@{
# 	PayDay = (Get-PayDay).DayofWeek
# 	PayDate = (Get-PayDay).LongDate
# 	DaysLeft = $DaysLeft
# }
# if ($DaysLeft -gt ($DaysLeft / 3 * 2) ) {
# 	Write-Host "Next PayDay Date   : $($properties.PayDay) $($properties.PayDate)" -ForegroundColor Blue -NoNewline:$false
# 	Write-Host "Days until Pay Day : $($DaysLeft) Days Left" -ForegroundColor Blue
# }
# elseif ($DaysLeft -lt ($DaysLeft / 2) ) {
# 	Write-Host "Next PayDay Date   : $($properties.PayDay) $($properties.PayDate)" -ForegroundColor Gray -NoNewline:$false
# 	Write-Host "Days until Pay Day : $($DaysLeft) Days Left" -ForegroundColor Gray
# }
# else { 
# 	Write-Host "Next PayDay Date   : $($properties.PayDay) $($properties.PayDate)" -ForegroundColor Green -NoNewline:$false
# 	Write-Host "Days until Pay Day : $($DaysLeft) Days Left" -ForegroundColor Green
# }



}
function Install-RequiredModules {
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
    [Alias('trm')]
    Param
    (
        [Parameter(ParameterSetName = 'Default',
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Enter a computer name or pipe input'
        )]
        [Alias('pm')]
        [string[]]$PublicModules,

        [Parameter(ParameterSetName = 'Internal',
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Enter a computer name or pipe input'
        )]
        [Alias('im')]
        [string[]]$InternalModules,

        [Parameter(ParameterSetName = 'Internal',
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Enter a computer name or pipe input'
        )]
        [Alias('ign')]
        [string[]]$InternalGalleryName,

        [Parameter(ParameterSetName = 'RSAT',
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Use this switch to install the Microsoft RSAT suite of tools. This includes the Active Directory module which is not available in the PowerShell Gallery.'
        )]
        [Alias('rsat')]
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
}
function intunemods {
# Name of the first module to be checked
$moduleName1 = "microsoft.graph.intune"

# Name of the second module to be checked
$moduleName2 = "WindowsAutopilotIntune"

# Function to check, import, or install a module
Function CheckAndImportModule {
    # Name of the module to be checked
    Param([string]$moduleName)

    # Check if the module is already imported
    if (-not(Get-Module -name $moduleName)) {
        # If not, check if the module is installed
        if (Get-Module -ListAvailable | Where-Object { $_.name -eq $moduleName }) {
            # If the module is installed, import it
            Import-Module -Name $moduleName
            $true
        }     
        else {
            # If the module is not installed, install it
            Install-Module -Name $moduleName -force
        }    
    }    
    else {
        # If the module is already imported, return true
        $true
    }    
}     

# Call the function for the first module
CheckAndImportModule -name $moduleName1

# Call the function for the second module
CheckAndImportModule -name $moduleName2
}
function Manage-AzureADApp {
<#
.SYNOPSIS
    Manages Azure AD application registrations.

.DESCRIPTION
    This script allows you to create, update, list client secrets, and delete Azure AD application registrations.

.PARAMETER TenantFQDN
    The FQDN of the Azure AD tenant.

.PARAMETER DisplayName
    The display name of the application registration.

.PARAMETER CustomLifetimeSecretInDays
    The custom lifetime of the client secret in days.

.PARAMETER CreateOrUpdateApp
    Switch to create or update the application.

.PARAMETER DeleteApp
    Switch to delete the application.

.PARAMETER UpdateAPIPerms
    Switch to update API permissions.

.PARAMETER CreateClientSecret
    Switch to create a new client secret.

.PARAMETER DeleteAllClientSecrets
    Switch to delete all existing client secrets.

.PARAMETER ListAllClientSecrets
    Switch to list all existing client secrets.

.EXAMPLE
    .\Manage-AzureADApp.ps1 -TenantFQDN "example.onmicrosoft.com" -DisplayName "MyApp" -CreateOrUpdateApp -Verbose

.NOTES
    Author: Your Name
    Date: Today's Date
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$TenantFQDN,

    [Parameter(Mandatory = $true)]
    [string]$DisplayName,

    [Parameter()]
    [int]$CustomLifetimeSecretInDays = 1,

    [Parameter()]
    [switch]$CreateOrUpdateApp,

    [Parameter()]
    [switch]$DeleteApp,

    [Parameter()]
    [switch]$UpdateAPIPerms,

    [Parameter()]
    [switch]$CreateClientSecret,

    [Parameter()]
    [switch]$DeleteAllClientSecrets,

    [Parameter()]
    [switch]$ListAllClientSecrets
)

function Get-TenantIDFromFQDN {
    param (
        [Parameter(Mandatory = $true)]
        [string]$TenantFQDN
    )
    $oidcConfigDiscoveryURL = "https://login.microsoftonline.com/$TenantFQDN/v2.0/.well-known/openid-configuration"
    try {
        $oidcConfigDiscoveryResult = Invoke-RestMethod -Uri $oidcConfigDiscoveryURL -ErrorAction Stop
        $tenantId = $oidcConfigDiscoveryResult.authorization_endpoint.Split("/")[3]
        Write-Verbose "Retrieved Tenant ID: $tenantId"
    }
    catch {
        Write-Error "Failed to retrieve the information from the discovery endpoint URL."
        throw $_
    }
    return $tenantId
}

# Get Tenant ID
$TenantID = Get-TenantIDFromFQDN -TenantFQDN $TenantFQDN

# Connect to Microsoft Graph
try {
    Write-Verbose "Connecting to Microsoft Graph..."
    Connect-MgGraph -Scopes "Application.ReadWrite.All" -TenantId $TenantID -NoWelcome -ErrorAction Stop
    Write-Verbose "Connected to Microsoft Graph."
}
catch {
    Write-Error "Failed to connect to Microsoft Graph."
    throw $_
}

if ($CreateOrUpdateApp) {
    try {
        Write-Verbose "Creating or updating the application..."
        $app = Get-MgApplication -Filter "DisplayName eq '$DisplayName'" -ErrorAction Stop
        if ($null -eq $app) {
            $app = New-MgApplication -DisplayName $DisplayName -SignInAudience AzureADMyOrg -Web @{ RedirectUris = @("http://localhost") } -ErrorAction Stop
            Write-Verbose "Application created successfully."
        }
        else {
            Update-MgApplication -ApplicationId $app.Id -Web @{ RedirectUris = @("http://localhost") } -ErrorAction Stop
            Write-Verbose "Application updated successfully."
        }

        $appObjectId = $app.Id
        $appId = $app.AppId

        if (-not $appObjectId) {
            throw "ApplicationId is empty, application update failed."
        }

        if ($UpdateAPIPerms) {
            Write-Verbose "Updating API permissions..."
            $msftGraph = Get-MgServicePrincipal -Filter "AppId eq '00000003-0000-0000-c000-000000000000'"
            $requiredResourceAccess = @(
                [PSCustomObject]@{ id = ($msftGraph.AppRoles | Where-Object { $_.Value -eq "Mail.Read" }).Id; type = "Role" }
                [PSCustomObject]@{ id = ($msftGraph.AppRoles | Where-Object { $_.Value -eq "Mail.ReadWrite" }).Id; type = "Role" }
                [PSCustomObject]@{ id = ($msftGraph.AppRoles | Where-Object { $_.Value -eq "Mail.Send" }).Id; type = "Role" }
            )

            Update-MgApplication -ApplicationId $appObjectId -RequiredResourceAccess @(
                @{
                    ResourceAppId  = $msftGraph.AppId
                    ResourceAccess = $requiredResourceAccess
                }
            )
            Write-Verbose "API permissions updated."
        }

        if ($CreateClientSecret) {
            Write-Verbose "Creating client secret..."
            $startDate = Get-Date
            $endDate = $startDate.AddDays($CustomLifetimeSecretInDays)
            $passwordCredential = @{
                displayName   = "Client Secret"
                startDateTime = $startDate
                endDateTime   = $endDate
            }
            $clientSecret = Add-MgApplicationPassword -ApplicationId $appObjectId -PasswordCredential $passwordCredential
            Write-Verbose "Client secret created. Value: $($clientSecret.SecretText)"
        }

        [PSCustomObject]@{
            TenantID     = $TenantID
            AppID        = $appId
            ClientSecret = if ($clientSecret) { $clientSecret.SecretText } else { $null }
        }

    }
    catch {
        Write-Error "Failed to create or update the application."
        throw $_
    }
}

if ($ListAllClientSecrets) {
    try {
        Write-Verbose "Listing all client secrets..."
        $app = Get-MgApplication -Filter "DisplayName eq '$DisplayName'" -ErrorAction Stop
        if ($app) {
            $secrets = Get-MgApplication -ApplicationId $app.Id | Select-Object -ExpandProperty PasswordCredentials
            $secrets | ForEach-Object {
                [PSCustomObject]@{
                    DisplayName   = $_.DisplayName
                    StartDateTime = $_.StartDateTime
                    EndDateTime   = $_.EndDateTime
                }
            }
        }
        else {
            Write-Host "Application not found."
        }
    }
    catch {
        Write-Error "Failed to list client secrets."
        throw $_
    }
}

if ($DeleteAllClientSecrets) {
    try {
        Write-Verbose "Deleting all client secrets..."
        $app = Get-MgApplication -Filter "DisplayName eq '$DisplayName'" -ErrorAction Stop
        if ($app) {
            $secrets = $app.PasswordCredentials
            foreach ($secret in $secrets) {
                Remove-MgApplicationPassword -ApplicationId $app.Id -KeyId $secret.KeyId -ErrorAction Stop
            }
            Write-Verbose "All client secrets deleted."
        }
        else {
            Write-Host "Application not found."
        }
    }
    catch {
        Write-Error "Failed to delete client secrets."
        throw $_
    }
}

if ($DeleteApp) {
    try {
        Write-Verbose "Deleting the application..."
        $app = Get-MgApplication -Filter "DisplayName eq '$DisplayName'" -ErrorAction Stop
        if ($app) {
            Remove-MgApplication -ApplicationId $app.Id -ErrorAction Stop
            Write-Host "Application deleted."
        }
        else {
            Write-Host "Application not found."
        }
    }
    catch {
        Write-Error "Failed to delete the application."
        throw $_
    }
}

# Disconnect from Microsoft Graph
try {
    Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
    Write-Verbose "Disconnected from Microsoft Graph."
}
catch {
    Write-Verbose "Failed to disconnect from Microsoft Graph."
}

# End of script

}
function ManuallyUpgradeDowngradeQNAPfirmware {
<# 
Manually Upgrade/Downgrade firmware by SSH

NAS Model Number
QNAP TS-873-8G

#>

# 1. Upload the firmware img file to Public folder  by File station.
#Here I take TS-X53A_20190704-4.3.6.0993.img as example

#2. SSH access to the NAS

# 3. Run
ln -sf /mnt/HDA_ROOT/update /mnt/update

# 4.Run
/etc/init.d/update.sh /share/Public/TS-X53A_20190704-4.3.6.0993.img
 
# 5.Run
reboot -r


<#
Example Output
[~] # ln -sf /mnt/HDA_ROOT/update /mnt/update
[~] # /etc/init.d/update.sh /share/Public/TS-X53A_20190704-4.3.6.0993.img
cksum=2235270506
Check RAM space available for FW update: OK.
Using 120-bit encryption - (QNAPNASVERSION4)

#>
}
function Microsoft.PowerShell_profile_speedy {
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
}
function Microsoft.PowerShell_profile-current {
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

}
function Microsoft.PowerShell_profile {
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
}
function New-PDQBurntToastShutdown {
[CmdletBinding()]
param(
    $Days = 7
)


$ModuleName = 'BurntToast'


# Check the uptime
$cim = Get-CimInstance win32_operatingsystem
$uptime = (Get-Date) - ($cim.LastBootUpTime)
$uptimeDays = $Uptime.Days


# return code 0 if this computer hasn't been online for too long
if ($uptimeDays -LT $Days) {
    Write-Verbose "Uptime is $uptimeDays days. Script will not proceed" -Verbose
    Exit 0
}


# Install the module if it is not already installed, then load it.
Try {
    $null = Get-InstalledModule $ModuleName -ErrorAction Stop
}
Catch {
    if ( -not ( Get-PackageProvider -ListAvailable | Where-Object Name -eq "Nuget" ) ) {
        $null = Install-PackageProvider "Nuget" -Force
    }
    $null = Install-Module $ModuleName -Force
}
$null = Import-Module $ModuleName -Force


Write-Verbose "Displaying Toast" -Verbose
New-BurntToastNotification -Text "This computer hasn't been reboot in $uptimeDays days. Please reboot when possible." -SnoozeAndDismiss
}
function New-ToastMessage {
Function New-ToastMessage {
    [CmdletBinding()]
    param(
        $Text
    )

    # Import the BurntToast module
    Import-Module -Name BurntToast

    # Create buttons for the notification with different actions
    $Button1 = New-BTButton -Content 'Button1' -Arguments 'https://www.example.com'
    $Button2 = New-BTButton -Content 'Button2' -Arguments 'ms-settings:windowsupdate'

    # Create a button group
    $ButtonGroup = New-BTButtonGroup -Buttons $Button1, $Button2

    # Create a hashtable for the notification
    $Notification = @{
        Text   = $Text
        Button = $ButtonGroup
    }

    # Create the notification
    New-BurntToastNotification @Notification
}
}
function New-ToastReboot {
# Checking if ToastReboot:// protocol handler is present
New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT -ErrorAction SilentlyContinue | Out-Null
$ProtocolHandler = Get-Item 'HKCR:\ToastReboot' -ErrorAction SilentlyContinue
if (!$ProtocolHandler) {
    # create handler for reboot
    New-item 'HKCR:\ToastReboot' -Force
    Set-ItemProperty 'HKCR:\ToastReboot' -Name '(DEFAULT)' -Value 'url:ToastReboot' -Force
    Set-ItemProperty 'HKCR:\ToastReboot' -Name 'URL Protocol' -Value '' -Force
    New-ItemProperty -Path 'HKCR:\ToastReboot' -PropertyType dword -Name 'EditFlags' -Value 2162688
    New-Item 'HKCR:\ToastReboot\Shell\Open\command' -Force
    Set-ItemProperty 'HKCR:\ToastReboot\Shell\Open\command' -Name '(DEFAULT)' -Value 'C:\Windows\System32\shutdown.exe -r -t 00' -Force
}

Install-RequiredModules -PublicModules BurntToast
Install-RequiredModules -PublicModules RunAsUser
invoke-ascurrentuser -scriptblock {

    $heroimage = New-BTImage -Source 'C:\GitRepos\ProfileFunctions\LukeLeigh_Profile_300x300.jpg' -HeroImage
    $Text1 = New-BTText -Content  "System Update"
    $Text2 = New-BTText -Content "Updates have been installed on your computer at $(Get-Date). Please select if you'd like to restart now, or snooze this message."
    $Button = New-BTButton -Content "Later" -Snooze -Id 'SnoozeTime'
    $Button2 = New-BTButton -Content "Restart" -Arguments "ToastReboot:" -ActivationType Protocol
    $5Min = New-BTSelectionBoxItem -Id 5 -Content '5 minutes'
    $10Min = New-BTSelectionBoxItem -Id 10 -Content '10 minutes'
    $1Hour = New-BTSelectionBoxItem -Id 60 -Content '1 hour'
    $4Hour = New-BTSelectionBoxItem -Id 240 -Content '4 hours'
    $1Day = New-BTSelectionBoxItem -Id 1440 -Content '1 day'
    $Items = $5Min, $10Min, $1Hour, $4Hour, $1Day
    $SelectionBox = New-BTInput -Id 'SnoozeTime' -DefaultSelectionBoxItemId 10 -Items $Items
    $action = New-BTAction -Buttons $Button, $Button2 -inputs $SelectionBox
    $Binding = New-BTBinding -Children $text1, $text2 -HeroImage $heroimage
    $Visual = New-BTVisual -BindingGeneric $Binding
    $Content = New-BTContent -Visual $Visual -Actions $action
    Submit-BTNotification -Content $Content

}

function Remove-ToastReboot {
    # Create a new PowerShell drive mapped to the HKEY_CLASSES_ROOT registry hive
    New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT -ErrorAction SilentlyContinue | Out-Null
    # Check if the custom protocol handler is present
    $ProtocolHandler = Get-Item 'HKCR:\ToastReboot' -ErrorAction SilentlyContinue
    if ($ProtocolHandler) {
        Write-Output "Removing custom protocol handler."
        Remove-Item 'HKCR:\ToastReboot' -Recurse -Force
    }
    else {
        Write-Output "The custom protocol handler is not present."
    }
}
}
function O365Creds {
$ClientID = '9e1b3c36'
$TenantID = 'ceb371f6'
$ClientSecret = 'NDE'
$Credentials = [pscredential]::new($ClientID, (ConvertTo-SecureString $ClientSecret -AsPlainText -Force))
Connect-MgGraph -ClientSecretCredential $Credentials -TenantId $TenantID -NoWelcome
}
function Office365Deployment {
#Requires -Version 5.1

<#
.SYNOPSIS
    Installs Office 365 from config file or use a generic config file and installs.
.DESCRIPTION
    Installs Office 365 from config file or use a generic config file and installs.
.EXAMPLE
    No parameters need if you want to use
    the default config file
    OR
    change the $OfficeXML variable to your XML config file's content.
.EXAMPLE
     -ConfigurationXMLFile C:\Scripts\Office365Install\Config.xml
    Install Office 365 and use a local config file.
    You can use https://config.office.com/ to help build the config file.
.OUTPUTS
    None
.NOTES
    This will reboot after a successful install.
    Minimum OS Architecture Supported: Windows 10, Windows Server 2016
    If you use the ConfigurationXMLFile parameter and push the file to the endpoint, you can use https://config.office.com/ to help build the config file.
    Release Notes:
    Initial Release
By using this script, you indicate your acceptance of the following legal terms as well as our Terms of Use at https://www.ninjaone.com/terms-of-use.
    Ownership Rights: NinjaOne owns and will continue to own all right, title, and interest in and to the script (including the copyright). NinjaOne is giving you a limited license to use the script in accordance with these legal terms. 
    Use Limitation: You may only use the script for your legitimate personal or internal business purposes, and you may not share the script with another party. 
    Republication Prohibition: Under no circumstances are you permitted to re-publish the script in any script library or website belonging to or under the control of any other software provider. 
    Warranty Disclaimer: The script is provided “as is” and “as available”, without warranty of any kind. NinjaOne makes no promise or guarantee that the script will be free from defects or that it will meet your specific needs or expectations. 
    Assumption of Risk: Your use of the script is at your own risk. You acknowledge that there are certain inherent risks in using the script, and you understand and assume each of those risks. 
    Waiver and Release: You will not hold NinjaOne responsible for any adverse or unintended consequences resulting from your use of the script, and you waive any legal or equitable rights or remedies you may have against NinjaOne relating to your use of the script. 
    EULA: If you are a NinjaOne customer, your use of the script is subject to the End User License Agreement applicable to you (EULA).
#>

[CmdletBinding()]
param(
    # Use a existing config file
    [String]
    $ConfigurationXMLFile,
    # Path where we will store our install files and our XML file
    [String]
    $OfficeInstallDownloadPath = 'C:\Scripts\Office365Install',
    # Clean up our install files
    [Switch]
    $CleanUpInstallFiles = $False
)

begin {
    function Set-XMLFile {
        # XML data that will be used for the download/install
        # Example config below generated from https://config.office.com/
        # To use your own config, just replace <Configuration> to </Configuration> with your xml config file content.
        # Notes:
        #  "@ can not have any character after it
        #  @" can not have any spaces or character before it.
        $OfficeXML = [XML]@"
        <Configuration ID="61d9b493-1d60-4f01-a71b-2e0fcf93e948">
        <Info Description="Leigh Services Office Deployment Custom Configuration." />
        <Add OfficeClientEdition="64" Channel="Current" MigrateArch="TRUE">
          <Product ID="O365ProPlusRetail">
            <Language ID="en-gb" />
            <ExcludeApp ID="Groove" />
            <ExcludeApp ID="Lync" />
          </Product>
        </Add>
        <Property Name="SharedComputerLicensing" Value="0" />
        <Property Name="FORCEAPPSHUTDOWN" Value="FALSE" />
        <Property Name="DeviceBasedLicensing" Value="0" />
        <Property Name="SCLCacheOverride" Value="0" />
        <Property Name="TenantId" Value="3ab8c573-cfde-4a33-b33a-6bd96f601c18" />
        <Updates Enabled="TRUE" />
        <AppSettings>
          <Setup Name="Company" Value="Leigh Services" />
          <User Key="software\microsoft\office\16.0\excel\options" Name="defaultformat" Value="51" Type="REG_DWORD" App="excel16" Id="L_SaveExcelfilesas" />
          <User Key="software\microsoft\office\16.0\powerpoint\options" Name="defaultformat" Value="27" Type="REG_DWORD" App="ppt16" Id="L_SavePowerPointfilesas" />
          <User Key="software\microsoft\office\16.0\word\options" Name="defaultformat" Value="" Type="REG_SZ" App="word16" Id="L_SaveWordfilesas" />
        </AppSettings>
        <Display Level="None" AcceptEULA="TRUE" />
      </Configuration>
"@
        #Save the XML file
        $OfficeXML.Save("$OfficeInstallDownloadPath\OfficeInstall.xml")
      
    }
    function Get-ODTURL {
    
        [String]$MSWebPage = Invoke-RestMethod 'https://www.microsoft.com/en-us/download/confirmation.aspx?id=49117'
    
        $MSWebPage | ForEach-Object {
            if ($_ -match 'url=(https://.*officedeploymenttool.*\.exe)') {
                $matches[1]
            }
        }
    
    }
    function Test-IsElevated {
        $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $p = New-Object System.Security.Principal.WindowsPrincipal($id)
        if ($p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator))
        { Write-Output $true }
        else
        { Write-Output $false }
    }
}
process {
    $VerbosePreference = 'Continue'
    $ErrorActionPreference = 'Stop'

    if (-not (Test-IsElevated)) {
        Write-Error -Message "Access Denied. Please run with Administrator privileges."
        exit 1
    }

    $CurrentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (!($CurrentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))) {
        Write-Warning 'Script is not running as Administrator'
        Write-Warning 'Please rerun this script as Administrator.'
        exit 1
    }

    if (-Not(Test-Path $OfficeInstallDownloadPath )) {
        New-Item -Path $OfficeInstallDownloadPath -ItemType Directory | Out-Null
    }

    if (!($ConfigurationXMLFile)) {
        Set-XMLFile
    }
    else {
        if (!(Test-Path $ConfigurationXMLFile)) {
            Write-Warning 'The configuration XML file is not a valid file'
            Write-Warning 'Please check the path and try again'
            exit 1
        }
    }

    $ConfigurationXMLFile = "$OfficeInstallDownloadPath\OfficeInstall.xml"
    $ODTInstallLink = Get-ODTURL

    #Download the Office Deployment Tool
    Write-Verbose 'Downloading the Office Deployment Tool...'
    try {
        Invoke-WebRequest -Uri $ODTInstallLink -OutFile "$OfficeInstallDownloadPath\ODTSetup.exe"
    }
    catch {
        Write-Warning 'There was an error downloading the Office Deployment Tool.'
        Write-Warning 'Please verify the below link is valid:'
        Write-Warning $ODTInstallLink
        exit 1
    }

    #Run the Office Deployment Tool setup
    try {
        Write-Verbose 'Running the Office Deployment Tool...'
        Start-Process "$OfficeInstallDownloadPath\ODTSetup.exe" -ArgumentList "/quiet /extract:$OfficeInstallDownloadPath" -Wait
    }
    catch {
        Write-Warning 'Error running the Office Deployment Tool. The error is below:'
        Write-Warning $_
        exit 1
    }

    #Run the O365 install
    try {
        Write-Verbose 'Downloading and installing Microsoft 365'
        $Silent = Start-Process "$OfficeInstallDownloadPath\Setup.exe" -ArgumentList "/configure $ConfigurationXMLFile" -Wait -PassThru
    }
    Catch {
        Write-Warning 'Error running the Office install. The error is below:'
        Write-Warning $_
    }

    #Check if Office 365 suite was installed correctly.
    $RegLocations = @('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
    )

    $OfficeInstalled = $False
    foreach ($Key in (Get-ChildItem $RegLocations) ) {
        if ($Key.GetValue('DisplayName') -like '*Microsoft 365*') {
            $OfficeVersionInstalled = $Key.GetValue('DisplayName')
            $OfficeInstalled = $True
        }
    }

    if ($OfficeInstalled) {
        Write-Verbose "$($OfficeVersionInstalled) installed successfully!"
        shutdown.exe -r -t 60
    }
    else {
        Write-Warning 'Microsoft 365 was not detected after the install ran'
    }

    if ($CleanUpInstallFiles) {
        Remove-Item -Path $OfficeInstallDownloadPath -Force -Recurse
    }
}
end {}
}
function OhMyPoshInstall {
# Install Command
winget install oh-my-posh
or
winget install oh-my-posh --accept-source-agreements --accept-package-agreements

# Profile Changes
oh-my-posh init pwsh | Invoke-Expression


# Recommended font - Meslo LGM NF
}
function oneliners {

Import-Module cache -ErrorAction Ignore
Import-Module publishmap -ErrorAction Ignore

# grab functions from files
Get-ChildItem $PSScriptRoot\functions\ -Filter "*.ps1" | 
Where-Object { -not ($_.Name.Contains(".Tests.")) } |
Where-Object { -not (($_.Name).StartsWith("_")) } |
ForEach-Object { . $_.FullName }


function invoke-giteach($cmd) {
    Get-ChildItem | Where-Object { $_.psiscontainer } | ForEach-Object { Push-Location; Set-Location $_; if (tp ".git") { Write-Output; log-info $_; git $cmd }; Pop-Location; }
}
function invoke-gitpull {
    git-each "pull"
}

function convertto-colorcode($color) {
    $light = $false
    if ($color -isnot [int]) {
        if ($color.startswith("light")) {
            $light = $true
            $color = $color -replace "light", ""
        }
        $color = switch ($color) {
            "black" { 0 }
            "red" { 1 }
            "green" { 2 }
            "yellow" { 3 }
            "blue" { 4 }
            "magenta" { 5 }
            "cyan" { 6 }
            "white" { 7 }
            default { 9 }
        }
    }
    
    return $color, $light
}

function set-bgcolor($n) {
    $base = 40
    $n, $light = convertto-colorcode $n    
    Write-Output  ([char](0x1b) + "[$($base+$n);m")
    if ($light) { Write-Output ([char](0x1b) + "[1;m") }
}

function set-color($n) {
    $base = 30
    $n, $light = convertto-colorcode $n
    Write-Output  ([char](0x1b) + "[$($base+$n);m")
    if ($light) { Write-Output ([char](0x1b) + "[1;m") }
}

function write-controlchar($c) {
    Write-Output  ([char](0x1b) + "[$c;m")
}


function set-windowtitle([string] $title) {
    $host.ui.RawUI.WindowTitle = $title
}
function update-windowtitle() {
    if ("$PWD" -match "\\([^\\]*).hg") {
        set-windowtitle $Matches[1]
    }
}

function split-output {
    [CmdletBinding()] 
    param([Parameter(ValueFromPipeline = $true)]$item, [ScriptBlock] $Filter, $filePath, [switch][bool] $append)
    process {
        $null = $_ | Where-Object $filter | tee-object -filePath $filePath -Append:$append 
        $_
    }
}

<#
function pin-totaskbar {
    param($cmd, $arguments)
    $shell = new-object -com "Shell.Application"
    $cmd = (Get-Item $cmd).FullName
    $dir = split-path -Parent $cmd 
    $exe = Split-Path -Leaf $cmd 
    $folder = $shell.Namespace($dir)    
    $item = $folder.Parsename($cmd)
    $verb = $item.Verbs() | ? {$_.Name -eq 'Pin to Tas&kbar'}
    if ($verb) {$verb.DoIt()}
}#>

function Get-ComFolderItem {
    [CMDLetBinding()]
    param(
        [Parameter(Mandatory = $true)] $Path
    )

    $ShellApp = New-Object -ComObject 'Shell.Application'

    $Item = Get-Item $Path -ErrorAction Stop

    if ($Item -is [System.IO.FileInfo]) {
        $ComFolderItem = $ShellApp.Namespace($Item.Directory.FullName).ParseName($Item.Name)
    }
    elseif ($Item -is [System.IO.DirectoryInfo]) {
        $ComFolderItem = $ShellApp.Namespace($Item.Parent.FullName).ParseName($Item.Name)
    }
    else {
        throw "Path is not a file nor a directory"
    }

    return $ComFolderItem
}

function Install-TaskBarPinnedItem {
    [CMDLetBinding()]
    param(
        [Parameter(Mandatory = $true)] [System.IO.FileInfo] $Item
    )

    $Pinned = Get-ComFolderItem -Path $Item

    $Pinned.invokeverb('taskbarpin')
}

function Uninstall-TaskBarPinnedItem {
    [CMDLetBinding()]
    param(
        [Parameter(Mandatory = $true)] [System.IO.FileInfo] $Item
    )

    $Pinned = Get-ComFolderItem -Path $Item

    $Pinned.invokeverb('taskbarunpin')
}

<#  new-shortcut is defined in pscx also #>

function new-shortcut {
    param ( [Parameter(Mandatory = $true)][string]$Name, [Parameter(Mandatory = $true)][string]$target, [string]$Arguments = "" )
    
    $WshShell = New-Object -comObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($Name)
    $Shortcut.TargetPath = $target
    $Shortcut.Arguments = $Arguments
    $Shortcut.Save()
}

function stop-allprocesses ($name) {
    # or just:
    # stop-process -name $name
    cmd /C taskkill /IM "$name.exe" /F
    cmd /C taskkill /IM "$name" /F
}

function test-any() {
    begin { $ok = $true; $seen = $false } 
    process { $seen = $true; if (!$_) { $ok = $false } } 
    end { $ok -and $seen }
} 

function get-dotnetversions() {
    $def = get-content "$psscriptroot\dotnetver.cs" | out-string
    add-type -TypeDefinition $def

    return [DotNetVer]::GetVersionFromRegistry()
}

<#
function reload-module($module) {
    if (gmo $module) { rmo $module  }
    ipmo $module -Global
}
#>

function test-tcp {
    Param(
        [Parameter(Mandatory = $True, Position = 1)]
        [string]$ip,

        [Parameter(Mandatory = $True, Position = 2)]
        [int]$port
    )

    $connection = New-Object System.Net.Sockets.TcpClient($ip, $port)
    if ($connection.Connected) {
        Return "Connection Success"
    }
    else {
        Return "Connection Failed"
    }
}

function import-state([Parameter(Mandatory = $true)]$file) {
    if (!(test-path $file)) {
        return $null
    }
    $c = get-content $file | out-string
    $obj = convertfrom-json $c 
    if ($null -eq $obj) { throw "failed to read state from file $file" }
    return $obj
}

function export-state([Parameter(Mandatory = $true)]$state, [Parameter(Mandatory = $true)]$file) {
    $state | convertto-json | out-file $file -encoding utf8
}


function Add-DnsAlias {
    [CmdletBinding()]
    param ([Parameter(Mandatory = $true)] $from, [Parameter(Mandatory = $true)] $to)
     
    $hostlines = @(get-content "c:\Windows\System32\drivers\etc\hosts")
    $hosts = @{}
    
    write-verbose "resolving name '$to'"

    if ($to -match "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+") {
        $ip = $to
    }
    else {
        $r = Resolve-DnsName $to
        if ($null -ne $r.Ip4address) {
            $ip = $r.ip4address        
        }
        else {
            throw "could not resolve name '$to'"
        }
    }
    for ($l = 0; $l -lt $hostlines.Length; $l++) {
        $_ = $hostlines[$l].Trim()
        if ($_.StartsWith("#") -or $_.length -eq 0 -or [string]::IsNullOrEmpty($_)) { continue }        
        $s = $_.Split(' ')
        $org = $_
        try {
            $hosts[$s[1]] = New-Object -type pscustomobject -Property @{ alias = $s[1]; ip = $s[0]; line = $l } 
        }
        catch {
            Write-Warning "failed to pars etc/hosts line: '$org'"
        }
    }
    
    if ($hosts.ContainsKey($from)) {
        $hosts[$from].ip = $ip
    }
    else {
        $hosts[$from] = New-Object -type pscustomobject -Property @{ alias = $from; ip = $ip; line = $hostlines.Length }
        $hostlines += @("")
    }
    
    Write-Verbose "adding to etc\hosts: $ip $from"
    $hostlines[$hosts[$from].line] = "$ip $from"
    
    $guid = [guid]::NewGuid().ToString("n")
    Write-Verbose "backing up etc\hosts to $env:TEMP\hosts-$guid"
    Copy-Item "c:\Windows\System32\drivers\etc\hosts" "$env:TEMP\hosts-$guid"  
    
    $hostlines | Out-File "c:\Windows\System32\drivers\etc\hosts" -Encoding ascii
}

function remove-dnsalias([Parameter(Mandatory = $true)] $from) {
    $hostlines = @(Get-Content "c:\Windows\System32\drivers\etc\hosts")
    $hosts = @{}
    
    $newlines = @()
    $found = $false
    for ($l = 0; $l -lt $hostlines.Length; $l++) {
        $_ = $hostlines[$l]
        if ($_.Trim().StartsWith("#") -or $_.Trim().length -eq 0) { 
            $newlines += @($_); 
            continue 
        }        
        $s = $_.Trim().Split(' ')
        if ($s[1] -ne $from) {
            $newlines += @($_)            
        }
        else {
            $found = $true
        }
    }
    
    if (!$found) {
        Write-Warning "alias '$from' not found!"
        return
    } 
    
    $guid = [guid]::NewGuid().ToString("n")
    Write-Host "backing up etc\hosts to $env:TEMP\hosts-$guid"
    Copy-Item "c:\Windows\System32\drivers\etc\hosts" "$env:TEMP\hosts-$guid"  
    
    $newlines | Out-File "c:\Windows\System32\drivers\etc\hosts" 
    
}

function test-isadmin() {
    # Get the ID and security principal of the current user account
    $myWindowsID = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $myWindowsPrincipal = new-object System.Security.Principal.WindowsPrincipal($myWindowsID)

    # Get the security principal for the Administrator role
    $adminRole = [System.Security.Principal.WindowsBuiltInRole]::Administrator

    # Check to see if we are currently running "as Administrator"
    return $myWindowsPrincipal.IsInRole($adminRole)
}

function Send-Slack {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]$Text,
        [Parameter(Mandatory = $false)]$Channel,
        [Parameter(Mandatory = $false)]$AsUser
    )
    process {
        Import-Module Require
        req psslack

        $cred = get-credentialscached -message "slack username and token (or webhook  uri)" -container "slack"
        $username = $cred.UserName
        $token = $cred.GetNetworkCredential().password

        $sendasuser = $AsUser

        if ($null -eq $AsUser) {
            $sendasuser = $true
        }

        if ($null -eq $Channel -and $null -ne $env:slackuser) {
            $Channel = "@$env:slackuser"
            Write-Verbose "setting channel to $channel"
            if ($null -eq $AsUser) { $sendasuser = $false }
        }
        if ($null -eq $Channel) {
            $Channel = "@$username"
            if ($null -eq $AsUser) { $sendasuser = $false }
        }

        $a = @{}
        if ($token.startswith("http")) {
            $a["uri"] = $token
        }
        else {
            $a["token"] = $token
            $a["username"] = $username
            $a["channel"] = $channel
        }
        $null = Send-SlackMessage @a -Text $text  -AsUser:$sendasuser
    }
}

function disable-hyperv {
    bcdedit /set hypervisorlaunchtype off
    write-host "hypervisorlaunchtype=off. Reboot to apply:"
    write-host "shutdown /r /t 0 /f"
}
function enable-hyperv {
    bcdedit /set hypervisorlaunchtype auto
    write-host "hypervisorlaunchtype=auto. Reboot to apply:"
    write-host "shutdown /r /t 0 /f"
}

function grep {
    param($regex)

    begin {
    }

    process {
        $_ | Where-Object { $_ -match $regex }
    }

    end {        
    }

}

function notify {
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]$Text,
        [Parameter(Mandatory = $false)]$Channel,
        [Parameter(Mandatory = $false)]$AsUser
    )
    begin { 
        slack "[$(get-date -Format "yyyy-MM-dd HH:mm:ss.ff")] Starting $Text" -Channel $Channel -AsUser:$AsUser 
    }
    process {
        write-verbose "notify"
    }    
    end {
        if ($Text -is [System.Management.Automation.ErrorRecord]) {
            slack "[$(get-date -Format "yyyy-MM-dd HH:mm:ss.ff")] FAIL $Text" -Channel $Channel -AsUser:$AsUser
        }
        else {
            slack "[$(get-date -Format "yyyy-MM-dd HH:mm:ss.ff")] DONE $Text" -Channel $Channel -AsUser:$AsUser
        }
    }
}

function foreach-repo ([scriptblock] $ScriptBlock, $argumentList) {
    foreach ($d in (Get-ChildItem . -Directory)) {
        try {
            if (Test-Path "$($d.name)/.hg") {
                Push-Location 
                Set-Location $d.name
                try {
                    Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList (@("hg") + $argumentList)
                }
                finally {
                    Pop-Location
                }
            }
            if (test-path "$($d.name)/.git") {
                Push-Location 
                Set-Location $d.name
                try {
                    Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList (@("git") + $argumentList)
                }
                finally {
                    Pop-Location
                }
            }
        }
        catch {
            Write-Error $_
        }
    }
}

function pull-all {
    foreach-repo {
        param($command)
        invoke $command pull
    }
}

function update-all ($rev) {
    foreach-repo {
        param($command, $rev)
        if ($command -eq "hg") {
            invoke $command update $rev
        }
        else {
            Write-Warning "don't know how to git update"
        }
    } 
}

function tryloop {
    param([scriptblock]$cmd, $interval = 1)
    while (1) {
        try {
            Invoke-Command $cmd -ErrorAction Stop
            break
        }
        catch {
            Write-Warning $_.Message
            Start-Sleep $interval
        }
    }
}

function Register-FileSystemWatcher {
    
    Param(
        [Parameter(Mandatory = $true)][string]$file, 
        [Parameter(Mandatory = $true)][scriptblock] $cmd,        
        $filter = "*.*",
        [ValidateSet("Created", "Changed", "Deleted", "Renamed")]
        $events = @("Created", "Changed", "Deleted", "Renamed"),
        [switch][bool] $loop,
        [switch][bool] $nowait         
    ) 

    ### SET FOLDER TO WATCH + FILES TO WATCH + SUBFOLDERS YES/NO
    $watcher = New-Object System.IO.FileSystemWatcher
    $watcher.Path = (Get-Item $file).FullName
    $watcher.Filter = $filter
    $watcher.IncludeSubdirectories = $true
    $watcher.EnableRaisingEvents = $true  

    ### DEFINE ACTIONS AFTER AN EVENT IS DETECTED
    $action = { 
        try {
            #$event | format-table | out-string | write-verbose -verbose
            #$event.MessageData | out-string | write-verbose -verbose
            #$event.MessageData.gettype() | out-string | write-verbose -verbose
            $path = $Event.SourceEventArgs.FullPath
            $changeType = $Event.SourceEventArgs.ChangeType
                        
            Write-Verbose "[$(Get-Date)] $changeType, $path" -Verbose
            Invoke-Command $event.MessageData.cmd -ArgumentList $path, $changeType -Verbose
            Write-Verbose "[$(Get-Date)] DONE $changeType, $path" -Verbose
            if ($event.MessageData.loop) {
                #Register-ObjectEvent $event.sender -EventName $changeType -Action $event.MessageData.action -MessageData $event.MessageData
            }
        }
        catch {
            Write-Error $_
            throw                    
        }
    }          

    ### DECIDE WHICH EVENTS SHOULD BE WATCHED 

    $jobs = $events | ForEach-Object {
        Register-ObjectEvent $watcher $_ -Action $action -MessageData @{ action = $action; cmd = $cmd; loop = $loop }
    }
    if (!$nowait) {
        try {
            while ($true) { Start-Sleep 1 }
        }
        finally {
            Stop-Job $jobs
        }
    }
}


new-alias tp test-path
new-alias git-each invoke-giteach
new-alias gitr git-each
new-alias x1b write-controlchar
new-alias swt set-windowtitle
new-alias pin-totaskbar Install-TaskBarPinnedItem
new-alias killall stop-allprocesses
new-alias tee-filter split-output
new-alias any test-any
new-alias relmo reload-module
new-alias tcpping test-tcp
#new-alias is-admin test-isadmin
new-alias slack send-slack
new-alias watch-file Register-FileSystemWatcher 
new-alias watch watch-file
Export-ModuleMember -Function * -Cmdlet * -Alias *

}
function Password Expire Mail {
#========================================================================
# Created By: Anders Wahlqvist
# Website: DollarUnderscore (http://dollarunderscore.azurewebsites.net)
#========================================================================

# Set when users should get a warning...

# First time
$FirstPasswordWarningDays = 14

# Second time
$SecondPasswordWarningDays = 7

# Last time
$LastPasswordWarningDays = 3

# Set SMTP-server
$SMTPServer = "MySMTP.Contoso.Com"

# Get the password expires policy
$PasswordExpiresLength = (Get-ADDefaultDomainPasswordPolicy).MaxPasswordAge

# Calculating when passwords would have been set if they expire today
$CurrentPWChangeDateLimit = (Get-Date).AddDays(-$PasswordExpiresLength.Days)

# Calculating all dates
$FirstPasswordDateLimit = $CurrentPWChangeDateLimit.AddDays($FirstPasswordWarningDays)
$SecondPasswordDateLimit = $CurrentPWChangeDateLimit.AddDays($SecondPasswordWarningDays)
$LastPasswordDateLimit = $CurrentPWChangeDateLimit.AddDays($LastPasswordWarningDays)

# Load the users
$MailUsers = Get-ADUser -Filter "(Mail -like '*@*') -AND `
(	PasswordLastSet -le '$FirstPasswordDateLimit' -AND PasswordLastSet -gt '$($FirstPasswordDateLimit.AddDays(-1))' -OR `
	PasswordLastSet -le '$SecondPasswordDateLimit' -AND PasswordLastSet -gt '$($SecondPasswordDateLimit.AddDays(-1))' -OR `
	PasswordLastSet -le '$LastPasswordDateLimit' -AND PasswordLastSet -gt '$($LastPasswordDateLimit.AddDays(-1))') -AND `
(	PasswordNeverExpires -eq '$false' -AND Enabled -eq '$true')" -Properties PasswordLastSet, DisplayName, PasswordNeverExpires, mail

# Loop through them
foreach ($MailUser in $MailUsers) {

	# Count how many days are left before the password expires and round that number
	$PasswordExpiresInDays = [System.Math]::Round((New-TimeSpan -Start $CurrentPWChangeDateLimit -End ($MailUser.PasswordLastSet)).TotalDays)

	# Write some status...
	Write-Output "$($MailUser.DisplayName) needs to change password in $PasswordExpiresInDays days."

	# Build the body depending on where in the organisation the user is

	# Change MyOU1 to match your the OU you want your users are in.
	if ($MailUser.DistinguishedName -like "*MyOU1*") {
		$Subject = "Your password is expiring in $PasswordExpiresInDays days"
		$Body = "Hi $($MailUser.DisplayName),<BR><BR>Your password is expiring in $PasswordExpiresInDays days. Please change it now!<BR><BR>Don't forget to change it in your mobile devices if you are using mailsync.<BR><BR>Helpdesk 1"
		$EmailFrom = "Helpdesk 1 <no-reply@contoso.com>"
	}
	# Change MyOU2 to match your environment
	elseif ($MailUser.DistinguishedName -like "*MyOU2*") {
		$Subject = "Your password is expiring in $PasswordExpiresInDays days"
		$Body = "Hi $($MailUser.DisplayName),<BR><BR>Your password is expiring in $PasswordExpiresInDays days. Please change it now!<BR><BR>Don't forget to change it in your mobile devices if you are using mailsync.<BR><BR>Helpdesk 2"
		$EmailFrom = "Helpdesk 2 <no-reply@contoso.com>"
	}
	# This is the default e-mail
	else {
		$Subject = "Your password is expiring in $PasswordExpiresInDays days"
		$Body = "Hi $($MailUser.DisplayName),<BR><BR>Your password is expiring in $PasswordExpiresInDays days. Please change it now!<BR><BR>Don't forget to change it in your mobile devices if you are using mailsync.<BR><BR>Helpdesk 3"
		$EmailFrom = "Helpdesk 3 <no-reply@contoso.com>"
	}

	# Time to send the e-mail

	# The line below might need changing depending on what SMTP you are using (authentication or not)
	Send-MailMessage -Body $Body -From $EmailFrom -SmtpServer $SMTPServer -Subject $Subject -Encoding UTF8 -BodyAsHtml -To $MailUser.mail

	# E-mail is sent!
}
}
function QuarantineFunctions {
# Ensure the ExchangeOnlineManagement module is installed
Install-Module -Name ExchangeOnlineManagement -Force

# Connect to Exchange Online
Connect-ExchangeOnline -UserPrincipalName <your-admin-username> -ShowProgress $true

# Load custom format data
Update-FormatData -PrependPath .\QuarantineEmailFormat.xml

# Function to list quarantined emails with filtering options
function Get-QuarantinedEmails {
    [CmdletBinding()]
    param (
        [string[]]$Recipient,
        [string]$Sender,
        [string]$Subject,
        [datetime]$StartReceivedDate,
        [datetime]$EndReceivedDate,
        [int]$PageSize = 100,
        [int]$Page = 1,
        [ValidateSet("Bulk", "HighConfPhish", "Malware", "Phish", "Spam", "SPOMalware", "TransportRule")]
        [string[]]$QuarantineTypes
    )

    # Initialize filter parameters
    $filterParams = @{}
    if ($Recipient) { $filterParams['RecipientAddress'] = $Recipient }
    if ($Sender) { $filterParams['SenderAddress'] = $Sender }
    if ($Subject) { $filterParams['Subject'] = $Subject }
    if ($StartReceivedDate) { $filterParams['StartReceivedDate'] = $StartReceivedDate }
    if ($EndReceivedDate) { $filterParams['EndReceivedDate'] = $EndReceivedDate }
    if ($PageSize) { $filterParams['PageSize'] = $PageSize }
    if ($Page) { $filterParams['Page'] = $Page }
    if ($QuarantineTypes) { $filterParams['QuarantineTypes'] = $QuarantineTypes }

    Write-Verbose "Starting to retrieve quarantined emails with the following filters: $filterParams"

    # Retrieve quarantined emails
    try {
        $quarantinedEmails = Get-QuarantineMessage @filterParams
        Write-Verbose "Retrieved $(($quarantinedEmails).Count) quarantined emails."
    }
    catch {
        Write-Error "Failed to retrieve quarantined emails. Error: $_"
        return
    }

    # Select relevant information
    $emailInfo = $quarantinedEmails | Select-Object ReceivedTime, Type, SenderAddress, RecipientAddress, Subject, Size, Expires
    Write-Verbose "Filtered email information ready for output."

    return $emailInfo
}

# Function to release quarantined email by MessageId
function Release-QuarantinedEmail {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$MessageId
    )

    Write-Verbose "Attempting to release email with MessageId: $MessageId"

    try {
        Release-QuarantineMessage -Identity $MessageId -ReleaseToAllRecipients
        Write-Output "Message with ID $MessageId has been released successfully."
    }
    catch {
        Write-Error "Failed to release message with ID $MessageId. Error: $_"
    }
}

# Example usage to list quarantined emails for specific recipients with optional filters
$Recipients = @("user1@example.com", "user2@example.com")
$Sender = "specific.sender@example.com"
$Subject = "Important Subject"
$StartReceivedDate = Get-Date "2024-06-01"
$EndReceivedDate = Get-Date "2024-06-09"
$PageSize = 50
$Page = 1
$QuarantineTypes = @("Spam", "Phish")

$quarantinedEmails = Get-QuarantinedEmails -Recipient $Recipients -Sender $Sender -Subject $Subject -StartReceivedDate $StartReceivedDate -EndReceivedDate $EndReceivedDate -PageSize $PageSize -Page $Page -QuarantineTypes $QuarantineTypes -Verbose

# Display the quarantined emails in a table format
$quarantinedEmails | Format-Table -AutoSize

# Example usage to release a specific email
# Replace 'example-message-id' with the actual MessageId
$MessageId = "example-message-id"
Release-QuarantinedEmail -MessageId $MessageId -Verbose
}
function Reset-WindowsUpdate {
<#
.SYNOPSIS
This function resets the Windows Update components.

.DESCRIPTION
The Reset-WindowsUpdate function stops the Windows Update services, removes the QMGR data file, renames the SoftwareDistribution and CatRoot folders, removes the old Windows Update log, resets the Windows Update services to default settings, registers some DLLs, removes WSUS client settings, resets the WinSock, deletes all BITS jobs, attempts to install the Windows Update Agent, starts the Windows Update services, and forces Windows Update to check for updates.

.PARAMETER StopServices
Stops the Windows Update services.

.PARAMETER RemoveQMGR
Removes the QMGR data file.

.PARAMETER RenameFolders
Renames the SoftwareDistribution and CatRoot folders.

.PARAMETER RemoveLog
Removes the old Windows Update log.

.PARAMETER ResetServices
Resets the Windows Update services to default settings.

.PARAMETER RegisterDLLs
Registers some DLLs.

.PARAMETER RemoveWSUS
Removes WSUS client settings.

.PARAMETER ResetWinSock
Resets the WinSock.

.PARAMETER DeleteBITS
Deletes all BITS jobs.

.PARAMETER InstallAgent
Attempts to install the Windows Update Agent.

.PARAMETER StartServices
Starts the Windows Update services.

.PARAMETER ForceDiscovery
Forces Windows Update to check for updates.

.PARAMETER RunAll
Performs all the operations.

.EXAMPLE
Reset-WindowsUpdate -Verbose

This command performs all the operations and displays verbose output for each step.

.EXAMPLE
Reset-WindowsUpdate -StopServices -Verbose

This command stops the Windows Update services and displays verbose output.

.EXAMPLE
Reset-WindowsUpdate -RemoveQMGR -RenameFolders -Verbose

This command removes the QMGR data file, renames the SoftwareDistribution and CatRoot folders, and displays verbose output.

.EXAMPLE
Reset-WindowsUpdate -ResetServices -RegisterDLLs -RemoveWSUS -Verbose

This command resets the Windows Update services to default settings, registers some DLLs, removes WSUS client settings, and displays verbose output.

.EXAMPLE
Reset-WindowsUpdate -ResetWinSock -DeleteBITS -InstallAgent -StartServices -ForceDiscovery -Verbose

This command resets the WinSock, deletes all BITS jobs, attempts to install the Windows Update Agent, starts the Windows Update services, forces Windows Update to check for updates, and displays verbose output.

#>

function Reset-WindowsUpdate {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(ValueFromPipeline = $true, HelpMessage = "Stops the Windows Update services.")]
        [switch]$StopServices,

        [Parameter(ValueFromPipeline = $true, HelpMessage = "Removes the QMGR data file.")]
        [switch]$RemoveQMGR,

        [Parameter(ValueFromPipeline = $true, HelpMessage = "Renames the SoftwareDistribution and CatRoot folders.")]
        [switch]$RenameFolders,

        [Parameter(ValueFromPipeline = $true, HelpMessage = "Removes the old Windows Update log.")]
        [switch]$RemoveLog,

        [Parameter(ValueFromPipeline = $true, HelpMessage = "Resets the Windows Update services to default settings.")]
        [switch]$ResetServices,

        [Parameter(ValueFromPipeline = $true, HelpMessage = "Registers some DLLs.")]
        [switch]$RegisterDLLs,

        [Parameter(ValueFromPipeline = $true, HelpMessage = "Removes WSUS client settings.")]
        [switch]$RemoveWSUS,

        [Parameter(ValueFromPipeline = $true, HelpMessage = "Resets the WinSock.")]
        [switch]$ResetWinSock,

        [Parameter(ValueFromPipeline = $true, HelpMessage = "Deletes all BITS jobs.")]
        [switch]$DeleteBITS,

        [Parameter(ValueFromPipeline = $true, HelpMessage = "Attempts to install the Windows Update Agent.")]
        [switch]$InstallAgent,

        [Parameter(ValueFromPipeline = $true, HelpMessage = "Starts the Windows Update services.")]
        [switch]$StartServices,

        [Parameter(ValueFromPipeline = $true, HelpMessage = "Forces Windows Update to check for updates.")]
        [switch]$ForceDiscovery,

        [Parameter(ValueFromPipeline = $true, HelpMessage = "Performs all the operations.")]
        [switch]$RunAll
    )

    # If no operation switches are selected, set $RunAll to $true
    if (-not ($StopServices -or $RemoveQMGR -or $RenameFolders -or $RemoveLog -or $ResetServices -or $RegisterDLLs -or $RemoveWSUS -or $ResetWinSock -or $DeleteBITS -or $InstallAgent -or $StartServices -or $ForceDiscovery -or $RunAll)) {
        $RunAll = $true
    }

    if ($RunAll) {
        $StopServices = $true
        $RemoveQMGR = $true
        $RenameFolders = $true
        $RemoveLog = $true
        $ResetServices = $true
        $RegisterDLLs = $true
        $RemoveWSUS = $true
        $ResetWinSock = $true
        $DeleteBITS = $true
        $InstallAgent = $true
        $StartServices = $true
        $ForceDiscovery = $true
    }

    $arch = Get-WMIObject -Class Win32_Processor -ComputerName LocalHost | Select-Object AddressWidth

    if ($PSCmdlet.ShouldProcess("Windows Update", "Reset")) {
        try {
            if ($StopServices) {
                Write-Verbose "1. Stopping Windows Update Services..." -Verbose
                Stop-Service -Name BITS -ErrorAction Stop
                Stop-Service -Name wuauserv -ErrorAction Stop
                Stop-Service -Name appidsvc -ErrorAction Stop
                Stop-Service -Name cryptsvc -ErrorAction Stop
            }

            if ($RemoveQMGR) {
                Write-Verbose "2. Remove QMGR Data file..." -Verbose
                Remove-Item "$env:allusersprofile\Application Data\Microsoft\Network\Downloader\qmgr*.dat" -ErrorAction Stop
            }

            if ($RenameFolders) {
                Write-Verbose "3. Renaming the Software Distribution and CatRoot Folder..." -Verbose
                if (Test-Path $env:systemroot\SoftwareDistribution.bak) {
                    Remove-Item $env:systemroot\SoftwareDistribution.bak -Recurse -Force -ErrorAction Stop
                }
                Rename-Item $env:systemroot\SoftwareDistribution SoftwareDistribution.bak -ErrorAction Stop

                if (Test-Path $env:systemroot\System32\catroot2.bak) {
                    Remove-Item $env:systemroot\System32\catroot2.bak -Recurse -Force -ErrorAction Stop
                }
                Rename-Item $env:systemroot\System32\Catroot2 catroot2.bak -ErrorAction Stop
            }

            if ($RemoveLog) {
                Write-Verbose "4. Removing old Windows Update log..." -Verbose
                Remove-Item $env:systemroot\WindowsUpdate.log -ErrorAction Stop
            }

            if ($ResetServices) {
                Write-Verbose "5. Resetting the Windows Update Services to defualt settings..." -Verbose
                "sc.exe sdset bits D:(A;;CCLCSWRPWPDTLOCRRC;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCLCSWLOCRRC;;;AU)(A;;CCLCSWRPWPDTLOCRRC;;;PU)"
                "sc.exe sdset wuauserv D:(A;;CCLCSWRPWPDTLOCRRC;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCLCSWLOCRRC;;;AU)(A;;CCLCSWRPWPDTLOCRRC;;;PU)"
            }

            if ($RegisterDLLs) {
                Write-Verbose "6. Registering some DLLs..." -Verbose
                regsvr32.exe /s atl.dll 
                regsvr32.exe /s urlmon.dll 
                regsvr32.exe /s mshtml.dll 
                regsvr32.exe /s shdocvw.dll 
                regsvr32.exe /s browseui.dll 
                regsvr32.exe /s jscript.dll 
                regsvr32.exe /s vbscript.dll 
                regsvr32.exe /s scrrun.dll 
                regsvr32.exe /s msxml.dll 
                regsvr32.exe /s msxml3.dll 
                regsvr32.exe /s msxml6.dll 
                regsvr32.exe /s actxprxy.dll 
                regsvr32.exe /s softpub.dll 
                regsvr32.exe /s wintrust.dll 
                regsvr32.exe /s dssenh.dll 
                regsvr32.exe /s rsaenh.dll 
                regsvr32.exe /s gpkcsp.dll 
                regsvr32.exe /s sccbase.dll 
                regsvr32.exe /s slbcsp.dll 
                regsvr32.exe /s cryptdlg.dll 
                regsvr32.exe /s oleaut32.dll 
                regsvr32.exe /s ole32.dll 
                regsvr32.exe /s shell32.dll 
                regsvr32.exe /s initpki.dll 
                regsvr32.exe /s wuapi.dll 
                regsvr32.exe /s wuaueng.dll 
                regsvr32.exe /s wuaueng1.dll 
                regsvr32.exe /s wucltui.dll 
                regsvr32.exe /s wups.dll 
                regsvr32.exe /s wups2.dll 
                regsvr32.exe /s wuweb.dll 
                regsvr32.exe /s qmgr.dll 
                regsvr32.exe /s qmgrprxy.dll 
                regsvr32.exe /s wucltux.dll 
                regsvr32.exe /s muweb.dll 
                regsvr32.exe /s wuwebv.dll 

            }

            if ($RemoveWSUS) {
                Write-Verbose "7) Removing WSUS client settings..." -Verbose
                REG DELETE "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate" /v AccountDomainSid /f 
                REG DELETE "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate" /v PingID /f 
                REG DELETE "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate" /v SusClientId /f 

            }

            if ($ResetWinSock) {
                Write-Verbose "8) Resetting the WinSock..." -Verbose
                netsh winsock reset
                netsh winhttp reset proxy

            }

            if ($DeleteBITS) {
                Write-Verbose "9) Delete all BITS jobs..." -Verbose
                Get-BitsTransfer | Remove-BitsTransfer

            }

            if ($InstallAgent) {
                Write-Verbose "10) Attempting to install the Windows Update Agent..." -Verbose
                if ($arch -eq 64) {
                    wusa Windows8-RT-KB2937636-x64 /quiet
                }
                else {
                    wusa Windows8-RT-KB2937636-x86 /quiet
                }

            }

            if ($StartServices) {
                Write-Verbose "11) Starting Windows Update Services..." -Verbose
                Start-Service -Name BITS -ErrorAction Stop
                Start-Service -Name wuauserv -ErrorAction Stop
                Start-Service -Name appidsvc -ErrorAction Stop
                Start-Service -Name cryptsvc -ErrorAction Stop

            }

            if ($ForceDiscovery) {
                Write-Verbose "12) Forcing Windows Update to check for updates..." -Verbose
                wuauclt /resetauthorization /detectnow

            }

            Write-Verbose "Process complete. Please reboot your computer." -Verbose
        }
        catch {
            Write-Error "An error occurred: $_"
        }
    }
}
}
function Reset-WindowsUpdateOriginal {
<# 
.SYNOPSIS 
Reset-WindowsUpdate.ps1 - Resets the Windows Update components 
 
.DESCRIPTION  
This script will reset all of the Windows Updates components to DEFAULT SETTINGS. 
 
.OUTPUTS 
Results are printed to the console. Future releases will support outputting to a log file.  
 
.NOTES 
Written by: Ryan Nemeth 
 
Find me on: 
 
* My Blog:    http://www.geekyryan.com 
* Twitter:    https://twitter.com/geeky_ryan 
* LinkedIn:    https://www.linkedin.com/in/ryan-nemeth-b0b1504b/ 
* Github:    https://github.com/rnemeth90 
* TechNet:  https://social.technet.microsoft.com/profile/ryan%20nemeth/ 
 
Change Log 
V1.00, 05/21/2015 - Initial version 
V1.10, 09/22/2016 - Fixed bug with call to sc.exe 
V1.20, 11/13/2017 - Fixed environment variables 
#> 
 
 
$arch = Get-WMIObject -Class Win32_Processor -ComputerName LocalHost | Select-Object AddressWidth 
 
Write-Host "1. Stopping Windows Update Services..." 
Stop-Service -Name BITS 
Stop-Service -Name wuauserv 
Stop-Service -Name appidsvc 
Stop-Service -Name cryptsvc 
 
Write-Host "2. Remove QMGR Data file..." 
Remove-Item "$env:allusersprofile\Application Data\Microsoft\Network\Downloader\qmgr*.dat" -ErrorAction SilentlyContinue 
 
Write-Host "3. Renaming the Software Distribution and CatRoot Folder..." 
Rename-Item $env:systemroot\SoftwareDistribution SoftwareDistribution.bak -ErrorAction SilentlyContinue 
Rename-Item $env:systemroot\System32\Catroot2 catroot2.bak -ErrorAction SilentlyContinue 
 
Write-Host "4. Removing old Windows Update log..." 
Remove-Item $env:systemroot\WindowsUpdate.log -ErrorAction SilentlyContinue 
 
Write-Host "5. Resetting the Windows Update Services to defualt settings..." 
"sc.exe sdset bits D:(A;;CCLCSWRPWPDTLOCRRC;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCLCSWLOCRRC;;;AU)(A;;CCLCSWRPWPDTLOCRRC;;;PU)" 
"sc.exe sdset wuauserv D:(A;;CCLCSWRPWPDTLOCRRC;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCLCSWLOCRRC;;;AU)(A;;CCLCSWRPWPDTLOCRRC;;;PU)" 
 
Set-Location $env:systemroot\system32 
 
Write-Host "6. Registering some DLLs..." 
regsvr32.exe /s atl.dll 
regsvr32.exe /s urlmon.dll 
regsvr32.exe /s mshtml.dll 
regsvr32.exe /s shdocvw.dll 
regsvr32.exe /s browseui.dll 
regsvr32.exe /s jscript.dll 
regsvr32.exe /s vbscript.dll 
regsvr32.exe /s scrrun.dll 
regsvr32.exe /s msxml.dll 
regsvr32.exe /s msxml3.dll 
regsvr32.exe /s msxml6.dll 
regsvr32.exe /s actxprxy.dll 
regsvr32.exe /s softpub.dll 
regsvr32.exe /s wintrust.dll 
regsvr32.exe /s dssenh.dll 
regsvr32.exe /s rsaenh.dll 
regsvr32.exe /s gpkcsp.dll 
regsvr32.exe /s sccbase.dll 
regsvr32.exe /s slbcsp.dll 
regsvr32.exe /s cryptdlg.dll 
regsvr32.exe /s oleaut32.dll 
regsvr32.exe /s ole32.dll 
regsvr32.exe /s shell32.dll 
regsvr32.exe /s initpki.dll 
regsvr32.exe /s wuapi.dll 
regsvr32.exe /s wuaueng.dll 
regsvr32.exe /s wuaueng1.dll 
regsvr32.exe /s wucltui.dll 
regsvr32.exe /s wups.dll 
regsvr32.exe /s wups2.dll 
regsvr32.exe /s wuweb.dll 
regsvr32.exe /s qmgr.dll 
regsvr32.exe /s qmgrprxy.dll 
regsvr32.exe /s wucltux.dll 
regsvr32.exe /s muweb.dll 
regsvr32.exe /s wuwebv.dll 
 
Write-Host "7) Removing WSUS client settings..." 
REG DELETE "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate" /v AccountDomainSid /f 
REG DELETE "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate" /v PingID /f 
REG DELETE "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate" /v SusClientId /f 
 
Write-Host "8) Resetting the WinSock..." 
netsh winsock reset 
netsh winhttp reset proxy 
 
Write-Host "9) Delete all BITS jobs..." 
Get-BitsTransfer | Remove-BitsTransfer 
 
Write-Host "10) Attempting to install the Windows Update Agent..." 
if($arch -eq 64){ 
    wusa Windows8-RT-KB2937636-x64 /quiet 
} 
else{ 
    wusa Windows8-RT-KB2937636-x86 /quiet 
} 
 
Write-Host "11) Starting Windows Update Services..." 
Start-Service -Name BITS 
Start-Service -Name wuauserv 
Start-Service -Name appidsvc 
Start-Service -Name cryptsvc 
 
Write-Host "12) Forcing discovery..." 
wuauclt /resetauthorization /detectnow 
 
Write-Host "Process complete. Please reboot your computer."
}
function ScheduledTasks {
#requires -RunAsAdministrator

function ScheduledTask-Create-FuckWithPsGalleryStats {
    $action = New-ScheduledTaskAction `
        -Execute 'pwsh.exe' `
        -Argument '-ExecutionPolicy Bypass -File "C:\Users\Rob\OneDrive\Documents\PowerShell\Scripts\Fuck-WithPsGalleryStats.ps1"'

    $trigger = New-ScheduledTaskTrigger -Daily -At 5pm

    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable

    Register-ScheduledTask `
        -TaskName "Fuck With Ps Gallery Stats" `
        -Action $action `
        -Trigger $trigger `
        -Settings $settings `
        -Description "Creates a docker container running Powershell and installs modules to up the install count in PSGallery"
}

function ScheduledTask-Delete-FuckWithPsGalleryStats {
    Unregister-ScheduledTask -TaskName "Fuck With Ps Gallery Stats" -Confirm:$false
}
}
function ServerSelection {
$Results = Get-Content -Path C:\Temp\Result-22-08-2022-13-38-20.json | ConvertFrom-Json
$Servers = $Results.serverSelection.servers
foreach ($Server in $Servers) {
    Try {
        $serverSelection = [ordered]@{
            ID       = $Server.server.id
            Host     = $Server.server.host
            Port     = $Server.server.port
            Name     = $Server.server.name
            Location = $Server.server.location
            Country  = $Server.server.country
        }
    }
    Catch {
        Write-Error $_
    }
    Finally {
        $obj = New-Object -TypeName PSObject -Property $serverSelection
        Write-Output $obj
    }
}
}
function Start-BurntToastReminder {
Function Start-PomodoroTimer {
    Param(
        [int]$Minutes = "25"
    )
    $seconds = (60 * $($Minutes))
    $sb = {
        Start-Sleep -Seconds $using:seconds
        New-BurntToastNotification -Text 'Timer complete. Take a break and get back to it' -SnoozeandDismiss -Sound SMS
    }
    Start-Job -Name 'Pomodoro Timer' -ScriptBlock $sb -Argumentlist $seconds
}
}
function Stop-NonRespondingProcesses {
function Stop-NonRespondingProcesses {
    param(
        [int]$timeout = 3,
        [switch]$continuous
    )

    # use a hash table to keep track of processes
    $hash = @{ }

    do {
        Get-Process |
        Where-Object MainWindowTitle |
        ForEach-Object {
            $key = $_.id
            if ($_.Responding) {
                $hash[$key] = 0
            }
            else {
                $hash[$key]++
            }
        }

        $keys = @($hash.Keys).Clone()

        $keys |
        Where-Object { $hash[$_] -gt $timeout } |
        ForEach-Object {
            $hash[$_] = 0
            Get-Process -id $_
        } | 
        Where-Object { $_.HasExited -eq $false } |
        Select-Object -Property Id, Name, StartTime, HasExited |
        Out-GridView -Title "Select apps to kill that are hanging for more than $timeout seconds" -PassThru |
        ForEach-Object {
            try {
                $_ | Stop-Process -Force
                Write-Host "Stopped process $($_.Id) - $($_.Name)"
            }
            catch {
                Write-Error "Failed to stop process $($_.Id) - $($_.Name)"
            }
        }

        if (-not $continuous) {
            break
        }

        Start-Sleep -Seconds 1

    } while ($true) 
}
}
function Test-SubnetResponse {
# <#
# 	mass-ping an entire IP range
# #>

# # IP range to ping
# $CIDRAddress
# $Subnet
 
# # timeout in milliseconds
# $timeout = 1000
 
# # number of simultaneous pings
# $throttleLimit = 80
 
# Based on the example code above Can you write a function that will allow me to enter the IP range using the parameters cidraddress, subnet and the timeout value, and return the results?
# The function will be called Test-SubnetResponse
# Available Parameters will be:
# -cidraddress
# -subnet
# -timeout

# Example:
# Test-SubnetResponse -cidraddress 10.10.0.0 -subnet 24 -timeout 1000

# The function should return the following:
# IP Address
# Status
# Response Time

# Example:
# IP Address:
#
# Status:
#
# Response Time:

# The function should also return the total execution time in milliseconds.

# Example:
# Execution Time: 1000 ms

# The function should also return the total number of IP addresses in the subnet.

# Example:
# Total IP Addresses: 254

# The function should also return the total number of IP addresses that responded.

# Example:
# Total IP Addresses Responded: 254

# The function should also return the total number of IP addresses that did not respond.

# Example:
# Total IP Addresses Did Not Respond: 0

Function Test-SubnetResponse {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true)]
        [string]$cidraddress,
        [Parameter(Mandatory = $true)]
        [int]$subnet,
        [Parameter(Mandatory = $true)]
        [int]$timeout
    )

    $ip = [System.Net.IPAddress]::Parse($cidraddress)
    $ipbytes = $ip.GetAddressBytes()
    $maskbytes = [System.Net.IPAddress]::IPv6MaskToIPv4Mask([System.Net.IPAddress]::Parse("::" * $subnet).GetAddressBytes(), 0)
    $start = [System.BitConverter]::ToUInt32($ipbytes, 0)
    $end = [System.BitConverter]::ToUInt32($maskbytes, 0)
    $total = $end - $start
    $totalip = $total + 1
    $totalipresponded = 0
    $totalipdidnotrespond = 0
    $totaltime = 0


    For ($i = $start; $i -le $end; $i++) {
        $ip = [System.Net.IPAddress]::Parse($i.ToString())
        $ping = New-Object System.Net.NetworkInformation.Ping
        $reply = $ping.Send($ip, $timeout)
        $totaltime += $reply.RoundtripTime
        If ($reply.Status -eq "Success") {
            $totalipresponded++
            Write-Host "IP Address: $ip"
            Write-Host "Status: $reply.Status"
            Write-Host "Response Time: $reply.RoundtripTime"
        }
        Else {
            $totalipdidnotrespond++
        }
    }

    Write-Host "Execution Time: $totaltime ms"
    Write-Host "Total IP Addresses: $totalip"
    Write-Host "Total IP Addresses Responded: $totalipresponded"
    Write-Host "Total IP Addresses Did Not Respond: $totalipdidnotrespond"
}

# Test-SubnetResponse -cidraddress 10.10.0.0 -subnet 24 -timeout 1000

}
function ThrowException {
Get-ADUser -Filter { name -like '*' } -Properties * | Where-Object -FilterScript { $_.UserPrincipalName -NE $null } | ForEach-Object -Process {
    try {
        $Perms = Get-O365CalendarPermissions -UserPrincipalName $_.UserPrincipalName -ErrorAction Ignore
        $prop = @{
            "Access"            = $Perms.AccessRights
            "User"              = $Perms.User
            "UserPrincipalName" = $Perms.UserPrincipalName
        }
        $obj = New-Object -TypeName psobject -Property $prop
        Write-Output -InputObject $obj
    }
    catch {
        Write-Error -Message "$($_.UserPrincipalName) : Mailbox does not exist"
    }
}
}
function TryingForDuplicateFiles {
# function Get-Files {
#     [CmdletBinding()]
#     param (
#         [Parameter(Mandatory = $true)]
#         [string]$Path,
#         [Parameter(Mandatory = $true)]
#         [string]$Extension,
#         [switch]$Recurse
#     )

#     $ChildItemParams = @{
#         LiteralPath = $Path
#         File        = $true
#         Recurse     = $Recurse.IsPresent
#         Filter      = "*$($Extension)"
#     }

#     Get-ChildItem @ChildItemParams | Select-Object -Property FullName, Name, Length, LastWriteTime, Extension, DirectoryName
# }

# function Compare-Files {
#     [CmdletBinding()]
#     param (
#         [Parameter(Mandatory = $true)]
#         [array]$SourceFiles,
#         [Parameter(Mandatory = $true)]
#         [array]$DestinationFiles
#     )

#     Compare-Object -ReferenceObject $SourceFiles -DifferenceObject $DestinationFiles -Property Name -PassThru | ForEach-Object {
#         if ($_.SideIndicator -ne '==') {
#             $_ | Add-Member -MemberType NoteProperty -Name IsDuplicate -Value $false -Force -PassThru
#         }
#         else {
#             $_ | Add-Member -MemberType NoteProperty -Name IsDuplicate -Value $true -Force -PassThru
#         }
#     } | Where-Object { $_.IsDuplicate }
# }

# function Remove-Files {
#     [CmdletBinding()]
#     param (
#         [Parameter(Mandatory = $true)]
#         [array]$Files,
#         [switch]$Delete
#     )

#     if ($Delete.IsPresent) {
#         $Files | Remove-Item -Force
#     }

#     $Files
# }

# function Find-DuplicateFiles {
#     [CmdletBinding()]
#     param (
#         [Parameter(Mandatory = $true)]
#         [string]$SourcePath,
#         [Parameter(Mandatory = $true)]
#         [string]$DestinationPath,
#         [Parameter(Mandatory = $true)]
#         [string]$SourceExtension,
#         [Parameter(Mandatory = $true)]
#         [string]$DestinationExtension,
#         [switch]$Recurse
#     )

#     begin {
#         Write-Verbose -Message "Starting processing of $($SourcePath) files with extension $($SourceExtension) and $($DestinationPath) files with extension $($DestinationExtension)"
#     }

#     process {
#         $SourceFiles = Get-Files -Path $SourcePath -Extension $SourceExtension -Recurse:$Recurse
#         $DestinationFiles = Get-Files -Path $DestinationPath -Extension $DestinationExtension -Recurse:$Recurse

#         $DuplicateFiles = Compare-Files -SourceFiles $SourceFiles -DestinationFiles $DestinationFiles

#         $DuplicateFiles | Select-Object -Property FullName, Name, Length, LastWriteTime, Extension, DirectoryName, @{Name = 'IsDuplicate'; Expression = { $_.IsDuplicate } }, @{Name = 'SideIndicator'; Expression = { $_.SideIndicator -replace '==', 'Duplicate' } }
#     }

#     end {
#         Write-Verbose -Message "Finished processing of $($SourcePath) files with extension $($SourceExtension) and $($DestinationPath) files with extension $($DestinationExtension)"
#     }
# }
}
function Update-QNAPfirmware {
<#
.SYNOPSIS
Updates the firmware of a QNAP device using the Posh-SSH module.

.DESCRIPTION
The Update-QNAPFirmware function copies a firmware file to a specified destination, establishes an SSH session with a QNAP device, and runs a series of commands to update the firmware and reboot the device.

.PARAMETER sourceFile
The path to the source firmware file. This path must exist.

.PARAMETER destinationPath
The path to the destination folder. This path must exist and the current user must have modify access to it.

.PARAMETER credential
The PSCredential object for SSH access.

.PARAMETER hostname
The hostname for SSH access.

.PARAMETER firmwareFileName
The name of the firmware file.

.EXAMPLE
$credential = Get-Credential -Message "Enter your SSH credentials"
Update-QNAPFirmware -sourceFile "C:\firmware.img" -destinationPath "C:\Public" -credential $credential -hostname "192.168.1.100" -firmwareFileName "firmware.img"

This example updates the firmware of the QNAP device at 192.168.1.100 using the firmware file at C:\firmware.img.
#>
function Update-QNAPFirmware {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, HelpMessage = "Path to the source firmware file.")]
        [ValidateScript({ Test-Path $_ })]
        [string]$sourceFile,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, HelpMessage = "Path to the destination folder.")]
        [ValidateScript({
                if (-not (Test-Path $_)) {
                    throw "Path '$_' does not exist."
                }

                $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
                $acl = Get-Acl $_

                if (-not ($acl.Access | Where-Object { $_.IdentityReference.Value -eq $currentUser -and $_.FileSystemRights -band [System.Security.AccessControl.FileSystemRights]::Modify })) {
                    throw "Current user '$currentUser' does not have modify access to path '$_'."
                }

                return $true
            })]
        [string]$destinationPath,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, HelpMessage = "PSCredential object for SSH access.")]
        [System.Management.Automation.PSCredential]$credential,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, HelpMessage = "Hostname for SSH access.")]
        [string]$hostname,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, HelpMessage = "Name of the firmware file.")]
        [string]$firmwareFileName
    )

    try {
        # 1. Upload the firmware img file to Public folder by File station.
        Write-Verbose "Copying firmware file to destination..."
        Write-Progress -Activity "Updating Firmware" -Status "Copying firmware file" -PercentComplete 0
        Copy-Item -Path $sourceFile -Destination $destinationPath -ErrorAction Stop
        Write-Verbose "Firmware file copied successfully."
    
        # 2. SSH access to the NAS
        Write-Verbose "Establishing SSH session..."
        Write-Progress -Activity "Updating Firmware" -Status "Establishing SSH session" -PercentComplete 20
        $session = New-SSHSession -ComputerName $hostname -Credential $credential -AcceptKey -ErrorAction Stop
    
        if ($null -eq $session) {
            throw "Failed to establish SSH session."
        }
    
        Write-Verbose "SSH session established successfully."
    
        # 3. Run
        Write-Verbose "Running command: ln -sf /mnt/HDA_ROOT/update /mnt/update"
        Write-Progress -Activity "Updating Firmware" -Status "Running command: ln -sf /mnt/HDA_ROOT/update /mnt/update" -PercentComplete 40
        Invoke-SSHCommand -SessionId $session.SessionId -Command 'ln -sf /mnt/HDA_ROOT/update /mnt/update'

        # 4.Run
        Write-Verbose "Running command: /etc/init.d/update.sh /share/Public/$firmwareFileName"
        Write-Progress -Activity "Updating Firmware" -Status "Running command: /etc/init.d/update.sh /share/Public/$firmwareFileName" -PercentComplete 60
        Invoke-SSHCommand -SessionId $session.SessionId -Command "/etc/init.d/update.sh /share/Public/$firmwareFileName"

        # 5.Run
        Write-Verbose "Running command: reboot -r"
        Write-Progress -Activity "Updating Firmware" -Status "Running command: reboot -r" -PercentComplete 80
        Invoke-SSHCommand -SessionId $session.SessionId -Command 'reboot -r'

        Write-Verbose "Firmware update process completed successfully."
        Write-Progress -Activity "Updating Firmware" -Status "Completed" -Completed
    }
    catch {
        Write-Error "An error occurred during the firmware update process: $_"
    }
    finally {
        # Close the SSH session
        if ($session) {
            Write-Verbose "Closing SSH session..."
            Remove-SSHSession -SessionId $session.SessionId
            Write-Verbose "SSH session closed."
        }
    }
}
}
function WeirdChatFunction {
Function New-ToastMessage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text,
        [Parameter(Mandatory = $true)]
        [ValidateRange(1, [int]::MaxValue)]
        [int]$ShutdownInMinutes,
        [string]$IconPath
    )

    try {
        Import-Module -Name BurntToast -ErrorAction Stop

        $Button1 = New-BTButton -Content 'Shutdown Now' -Arguments 'shutdown /s /t 0'
        $Button2 = New-BTButton -Content 'Postpone Shutdown' -Arguments 'shutdown /a'

        $Action1 = New-BTAction -Buttons $Button1
        $Action2 = New-BTAction -Buttons $Button2

        $Notification = @{
            Text    = $Text
            Actions = $Action1, $Action2
            AppLogo = $IconPath
        }

        New-BurntToastNotification @Notification
    }
    catch {
        Write-Error "Failed to create toast notification: $_"
    }
}

Function New-ScheduledShutdown {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateRange(1, [int]::MaxValue)]
        [int]$ShutdownInHours,
        [Parameter(Mandatory = $true)]
        [ValidateRange(1, [int]::MaxValue)]
        [int]$ReminderIntervalInMinutes
    )

    try {
        $Reminders = $ShutdownInHours * 60 / $ReminderIntervalInMinutes

        for ($i = 0; $i -lt $Reminders; $i++) {
            $Time = (Get-Date).AddMinutes($ReminderIntervalInMinutes * ($i + 1))
            Register-ScheduledJob -Name "Reminder$i" -ScriptBlock {
                New-ToastMessage -Text "Shutdown in $(($Reminders - $i) * $ReminderIntervalInMinutes) minutes" -ShutdownInMinutes $(($Reminders - $i) * $ReminderIntervalInMinutes)
            } -Trigger (New-JobTrigger -Once -At $Time)
        }

        $Time = (Get-Date).AddHours($ShutdownInHours)
        Register-ScheduledJob -Name "Shutdown" -ScriptBlock {
            shutdown /s /t 0
        } -Trigger (New-JobTrigger -Once -At $Time)
    }
    catch {
        Write-Error "Failed to schedule shutdown: $_"
    }
}

Function Stop-ScheduledShutdown {
    try {
        Get-ScheduledJob -Name "Shutdown" | Unregister-ScheduledJob
        Get-ScheduledJob | Where-Object { $_.Name -like "Reminder*" } | Unregister-ScheduledJob
    }
    catch {
        Write-Error "Failed to stop scheduled shutdown: $_"
    }
}

# Test the New-ToastMessage function
# New-ToastMessage -Text "Test message" -ShutdownInMinutes 1

# Test the New-ScheduledShutdown function
# New-ScheduledShutdown -ShutdownInHours 1 -ReminderIntervalInMinutes 30

# Test the Stop-ScheduledShutdown function
# Stop-ScheduledShutdown
}
