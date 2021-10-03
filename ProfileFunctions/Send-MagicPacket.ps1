function Send-MagicPacket {
    <#
    
    .SYNOPSIS
    Set-GoogleDynamicDNS.ps1 - Cmdlet to update your Google Dynamic DNS Record.
    
    .DESCRIPTION
    The Set-GoogleDynamicDNS Cmdlet can update your Google Dynamic DNS Record using the module GoogleDynamicDNSTools.
    This command will update the subdomain for the domain specified with the external IP with the computers current internet connection.

    Using Module https://www.powershellgallery.com/packages/GoogleDynamicDNSTools/3.0
    API from https://ipinfo.io/account

    .PARAMETER      Town


    .PARAMETER      Units
    Available on: All plans
    By default, the API will return all results in metric units. Aside from metric units, other common unit formats are supported as well. You can use the units parameter to switch between the different unit formats Metric, Scientific and Fahrenheit.

    m for Metric:
    Parameter	Units
    units = m	temperature: Celsius
    units = m	Wind Speed/Visibility: Kilometers/Hour
    units = m	Pressure: MB - Millibar
    units = m	Precip: MM - Millimeters
    units = m	Total Snow: CM - Centimeters

    s for Scientific:
    Parameter	Units
    units = s	temperature: Kelvin
    units = s	Wind Speed/Visibility: Kilometers/Hour
    units = s	Pressure: MB - Millibar
    units = s	Precip: MM - Millimeters
    units = s	Total Snow: CM - Centimeters

    f for Fahrenheit:
    Parameter	Units
    units = f	temperature: Fahrenheit
    units = f	Wind Speed/Visibility: Miles/Hour
    units = f	Pressure: MB - Millibar
    units = f	Precip: IN - Inches
    units = f	Total Snow: IN - Inches
    
    .INPUTS
    [string]Town
    [string]Units
    [string]access_key

    .OUTPUTS
    None. Returns no objects or output.

    .EXAMPLE
    Set-GoogleDynamicDNS -DomainName "example.com" -SubDomain "myhome" -Username "[USERNAME]" -Password "[PASSWORD]"

    This command will update the subdomain "myhome.example.com" with the external IP for the current internet connection.

    .LINK
    https://www.powershellgallery.com/packages/GoogleDynamicDNSTools/3.0

    .LINK
    https://ipinfo.io/account

    .NOTES
    Author	: Luke Leigh
    Website	: https://blog.lukeleigh.com
    Twitter	: https://twitter.com/luke_leighs

    Using Module https://www.powershellgallery.com/packages/GoogleDynamicDNSTools/3.0
    API from https://ipinfo.io/account

    #>

    [CmdletBinding(DefaultParameterSetName = 'Default',
        HelpUri = 'http://www.microsoft.com/',
        ConfirmImpact = 'Low')]
    [Alias('gwd')]
    [OutputType([String])]
    Param (
        # This field will accept a string value for the MAC Address - e.g. "98-90-96-DE-4C-6E" or "98:90:96:DE:4C:6E"
        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $false, 
            ParameterSetName = 'Default',
            HelpMessage = "This field will accept a string value for the MAC Address - e.g. '98-90-96-DE-4C-6E' or '98:90:96:DE:4C:6E' ")]
        [String]
        $Mac
    )


    $MacByteArray = $Mac -split "[:-]" | ForEach-Object { [Byte] "0x$_" }
    [Byte[]] $MagicPacket = (, 0xFF * 6) + ($MacByteArray * 16)
    $UdpClient = New-Object System.Net.Sockets.UdpClient
    $UdpClient.Connect(([System.Net.IPAddress]::Broadcast), 7)
    $UdpClient.Send($MagicPacket, $MagicPacket.Length)
    $UdpClient.Close()

}