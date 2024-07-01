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