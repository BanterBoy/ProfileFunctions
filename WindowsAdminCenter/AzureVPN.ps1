function Complete-P2SVPNConfiguration {
<#

.SYNOPSIS
Download, Extract VPN Folder File & Configure Point to Site VPN

.DESCRIPTION
This script is used to download VPN Client, extract VPN Folder File & Configure Point to Site VPN

.ROLE
Administrators

#>
param(
    [Parameter(Mandatory = $true)]
    [String]
    $AccessToken,
    [Parameter(Mandatory = $true)]
    [String]
    $ClientID,
    [Parameter(Mandatory = $true)]
    [String]
    $VNetSubnets, #"10.8.0.0/24;11.8.0.0/26"
    [Parameter(Mandatory = $true)]
    [String]
    $Subscription,
    [Parameter(Mandatory = $true)]
    [String]
    $ResourceGroup,
    [Parameter(Mandatory = $true)]
    [String]
    $GatewayName,
    [Parameter(Mandatory = $true)]
    [String]
    $VirtualNetwork,
    [Parameter(Mandatory = $true)]
    [String]
    $AddressSpace,
    [Parameter(Mandatory = $true)]
    [String]
    $Location
   
)
#Function to log event
function Log-MyEvent($Message){
    Try {
        $eventLogName = "ANA-LOG"
        $eventID = Get-Random -Minimum -1 -Maximum 65535
        #Create WAC specific Event Source if not exists
        $logFileExists = Get-EventLog -list | Where-Object {$_.logdisplayname -eq $eventLogName} 
        if (!$logFileExists) {
            New-EventLog -LogName $eventLogName -Source $eventLogName
        }
        #Prepare Event Log content and Write Event Log
        Write-EventLog -LogName $eventLogName -Source $eventLogName -EntryType Information -EventID $eventID -Message $Message

        $result = "Success"
    }
    Catch [Exception] {
        $result = $_.Exception.Message
    }
}

Function Build-Vpn( 
[Parameter(Mandatory = $true)]
[string]$XmlFilePathBuild,
[Parameter(Mandatory = $true)]
[string]$ProfileNameBuild,
[Parameter(Mandatory = $true)]
[string]$VNetGatewayNameBuild
)
{
    Log-MyEvent -Message "VPN Client Build started"
    
    #Enabling SC Config on demand
    $scConfigResult=CMD /C "sc config dmwappushservice start=demand"

    $a = Test-Path $xmlFilePathBuild
    Write-Output $a

    $ProfileXML = Get-Content $xmlFilePathBuild

    Write-Output $XML

    $ProfileNameBuildEscaped = $ProfileNameBuild -replace ' ', '%20'

    $Version = 201606090004

    $ProfileXML = $ProfileXML -replace '<', '&lt;'
    $ProfileXML = $ProfileXML -replace '>', '&gt;'
    $ProfileXML = $ProfileXML -replace '"', '&quot;'

    $nodeCSPURI = './Vendor/MSFT/VPNv2'
    $namespaceName = "root\cimv2\mdm\dmmap"
    $className = "MDM_VPNv2_01"

    $session = New-CimSession

    try
    {
        $newInstance = New-Object Microsoft.Management.Infrastructure.CimInstance $className, $namespaceName
        $property = [Microsoft.Management.Infrastructure.CimProperty]::Create("ParentID", "$nodeCSPURI", 'String', 'Key')
        $newInstance.CimInstanceProperties.Add($property)
        $property = [Microsoft.Management.Infrastructure.CimProperty]::Create("InstanceID", "$ProfileNameBuildEscaped", 'String', 'Key')
        $newInstance.CimInstanceProperties.Add($property)
        $property = [Microsoft.Management.Infrastructure.CimProperty]::Create("ProfileXML", "$ProfileXML", 'String', 'Property')
        $newInstance.CimInstanceProperties.Add($property)

        $session.CreateInstance($namespaceName, $newInstance)
        Log-MyEvent -Message "VPN Client Build completed."

        #Delete from RegEdit
        Remove-ItemProperty -path HKLM:\Software\WAC\VNetGatewayNotConfigured -name $VNetGatewayNameBuild -ErrorAction SilentlyContinue
        Log-MyEvent -Message "Removed from VNetGatewayNotConfigured RegEdit"

        #Delete File & Folders

        $folderToDelete = Split-Path -Path $xmlFilePathBuild

        Remove-Item -path $folderToDelete -Force -Recurse -ErrorAction SilentlyContinue
        Remove-Item -path $folderToDelete'.zip' -Force -Recurse -ErrorAction SilentlyContinue

        Log-MyEvent -Message "Trying to connect to VPN....."
        #Connect to this VPN
        $vpnConnected = rasdial $ProfileNameBuild
        Log-MyEvent -Message "VPN Connection established successfully."

        $Message = "Created $ProfileNameBuild profile."
        
        return "success"
    }
    catch [Exception]
    {
        Log-MyEvent -Message "Error Occured during establishing VPN"
        $Message = "Unable to create $ProfileNameBuild profile: $_"
        Log-MyEvent -Message $Message
        
        return $_.Exception.Message
    }
}

#Main operation started
Log-MyEvent -Message "Starting Gateway -'$GatewayName'"

$azureRmModule = Get-Module AzureRM -ListAvailable | Microsoft.PowerShell.Utility\Select-Object -Property Name -ErrorAction SilentlyContinue
if (!$azureRmModule.Name) {
    Log-MyEvent -Message "AzureRM module Not Available. Installing AzureRM Module"
    $packageProvIntsalled = Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
    $armIntalled = Install-Module AzureRm -Force
    Log-MyEvent -Message "Installed AzureRM Module successfully"
} 
else
{
    Log-MyEvent -Message "AzureRM Module Available"
}

import-module AzureRm

Log-MyEvent -Message "Imported AzureRM Module successfully"

#Login into Azure
#$logInRes = Login-AzureRmAccount -AccessToken $AccessToken -AccountId $ClientID
Log-MyEvent -Message "Logging in and selecting subscription..."
#Select Subscription
#$selectSubRes = Select-AzureRmSubscription -SubscriptionId $Subscription
$selectSubRes = Add-AzureRmAccount -AccessToken $AccessToken -AccountId $ClientID -Subscription $Subscription
if($selectSubRes)
{
    Log-MyEvent -Message "Selected Subscription successfully"

    #Select Gateway and generate URL to download VPN Client
    $profile = New-AzureRmVpnClientConfiguration -ResourceGroupName $ResourceGroup -Name $GatewayName -AuthenticationMethod "EapTls"
    if($profile)
    {
        Log-MyEvent -Message "URL generated to download VPN Client"

        #Create a Temp Folder if not exists
        $tempPath = "C:\WAC-TEMP"
        if (!(Test-Path $tempPath)) {
            $TempfolderCreated = New-Item -Path $tempPath -ItemType directory
        }

        #Delete previously downloaded zip file and extracted folder (if any)
        if (Test-Path "$tempPath\$GatewayName.zip") {
                Log-MyEvent -Message "Previous zip file found. deleting it.."
                Remove-Item -path "$tempPath\$GatewayName.zip" -Force -Recurse -ErrorAction SilentlyContinue
                Log-MyEvent -Message "Previous zip file deleted successfully."
        }
        if (Test-Path "$tempPath\$GatewayName") {
            Log-MyEvent -Message "Previous extracted folder found. deleting it.."
            Remove-Item -path "$tempPath\$GatewayName" -Force -Recurse -ErrorAction SilentlyContinue
            Log-MyEvent -Message "Previous extracted folder deleted successfully."
        }
    
        #Download VPN Client and save into a local temp folder
        $output = "$tempPath\" + $GatewayName + ".zip"
        $downLoadUrl = Invoke-WebRequest -Uri $profile.VPNProfileSASUrl -OutFile $output
        Log-MyEvent -Message "VPN Client downloaded successfully"

        #Extract zip
        $DestinationFolder = "$tempPath\" + $GatewayName
        Expand-Archive $output -DestinationPath $DestinationFolder
        Log-MyEvent -Message "VPN Client extracted successfully"

        #Read VPN Setting from Generic folder
        [xml]$XmlDocument = Get-Content -Path $DestinationFolder/Generic/VpnSettings.xml
        $vpnDNSRecord = $XmlDocument.VpnProfile.VpnServer
        Log-MyEvent -Message "Fetched VPN DNS record from VpnSettings.xml file in Generic foder"

        #Create a new VPN Profile name - check uniqueness
        $randomNumber = Get-Random -Minimum -1 -Maximum 65535
        $newVpnProfileName ='WACVPN-' + $randomNumber + '.xml'
        $isVpnAailable = 0
        while($isVpnAailable -eq 0)
        {
            if(!(Get-VpnConnection -Name $newVpnProfileName.split(".")[0] -ErrorAction SilentlyContinue))
            {
                $isVpnAailable=1
            }
            else
            { 
                $randomNumber = Get-Random -Minimum -1 -Maximum 65535
                $newVpnProfileName = 'WACVPN-' + $randomNumber + '.xml'
                $isVpnAailable=0
            }
        }
        try
        {
            Log-MyEvent -Message "Finalized VPN profile unique name"

            $xml_Path = $DestinationFolder + '\' + $newVpnProfileName
 
            #Set RasMan RegEdit value to 1
            $rasManPath = "HKLM:\System\CurrentControlSet\Services\RasMan\IKEv2"
            if((get-item -Path $rasManPath -ErrorAction SilentlyContinue))
            {
                Set-ItemProperty -Path $rasManPath -Name DisableCertReqPayload -Value 1
            }
            Log-MyEvent -Message "Updated RasMan to 1 in RegEdit"

            # Create the XML File Tags
            $xmlWriter = New-Object System.XMl.XmlTextWriter($xml_Path, $Null)
            $xmlWriter.Formatting = 'Indented'
            $xmlWriter.Indentation = 1
            $XmlWriter.IndentChar = "`t"
            $xmlWriter.WriteStartDocument()
            $xmlWriter.WriteStartElement('VPNProfile')
            $xmlWriter.WriteEndElement()
            $xmlWriter.WriteEndDocument()
            $xmlWriter.Flush()
            $xmlWriter.Close()
            Log-MyEvent -Message "XML File creation started"

            #Creating Root Node -NativeProfile
            $xmlDoc = [System.Xml.XmlDocument](Get-Content $xml_Path);
            $siteCollectionNode = $xmlDoc.CreateElement("NativeProfile")
            $nodeCreation = $xmlDoc.SelectSingleNode("//VPNProfile").AppendChild($siteCollectionNode)
            $xmlDoc.Save($xml_Path)

            #Creating Node -Servers
            $xmlDoc = [System.Xml.XmlDocument](Get-Content $xml_Path);
            $siteCollectionNode = $xmlDoc.CreateElement("Servers")
            $nodeCreation = $xmlDoc.SelectSingleNode("//VPNProfile/NativeProfile").AppendChild($siteCollectionNode)

            #Adding VPN DNS Record
            $RootFolderTextNode = $siteCollectionNode.AppendChild($xmlDoc.CreateTextNode($vpnDNSRecord));
            $xmlDoc.Save($xml_Path)

            #Creating Native Protocolol Type
            $xmlDoc = [System.Xml.XmlDocument](Get-Content $xml_Path);
            $siteCollectionNode = $xmlDoc.CreateElement("NativeProtocolType")
            $nodeCreation = $xmlDoc.SelectSingleNode("//VPNProfile/NativeProfile").AppendChild($siteCollectionNode)

            #Adding IKEv2
            $RootFolderTextNode = $siteCollectionNode.AppendChild($xmlDoc.CreateTextNode("IKEv2"));
            $xmlDoc.Save($xml_Path)

            #Creating Authentication
            $xmlDoc = [System.Xml.XmlDocument](Get-Content $xml_Path);
            $siteCollectionNode = $xmlDoc.CreateElement("Authentication")
            $nodeCreation = $xmlDoc.SelectSingleNode("//VPNProfile/NativeProfile").AppendChild($siteCollectionNode)
            $xmlDoc.Save($xml_Path)
            $xmlDoc = [System.Xml.XmlDocument](Get-Content $xml_Path);
            $siteCollectionNode = $xmlDoc.CreateElement("MachineMethod")
            $nodeCreation = $xmlDoc.SelectSingleNode("//VPNProfile/NativeProfile/Authentication").AppendChild($siteCollectionNode)
            $RootFolderTextNode = $siteCollectionNode.AppendChild($xmlDoc.CreateTextNode("Certificate"));
            $xmlDoc.Save($xml_Path)

            #Creating RoutingPolicyType
            $xmlDoc = [System.Xml.XmlDocument](Get-Content $xml_Path);
            $siteCollectionNode = $xmlDoc.CreateElement("RoutingPolicyType")
            $nodeCreation = $xmlDoc.SelectSingleNode("//VPNProfile/NativeProfile").AppendChild($siteCollectionNode)
            $RootFolderTextNode = $siteCollectionNode.AppendChild($xmlDoc.CreateTextNode("SplitTunnel"));
            $xmlDoc.Save($xml_Path)

            #Creating DisableClassBasedDefaultRoute
            $xmlDoc = [System.Xml.XmlDocument](Get-Content $xml_Path);
            $siteCollectionNode = $xmlDoc.CreateElement("DisableClassBasedDefaultRoute")
            $nodeCreation = $xmlDoc.SelectSingleNode("//VPNProfile/NativeProfile").AppendChild($siteCollectionNode)
            $RootFolderTextNode = $siteCollectionNode.AppendChild($xmlDoc.CreateTextNode("true"));
            $xmlDoc.Save($xml_Path)

            #Create Route
            $xmlDoc = [System.Xml.XmlDocument](Get-Content $xml_Path);
            $siteCollectionNode = $xmlDoc.CreateElement("Route")
            $nodeCreation = $xmlDoc.SelectSingleNode("//VPNProfile").AppendChild($siteCollectionNode)
            $xmlDoc.Save($xml_Path)

            #Get VNet Subnets and populate Address and prefix
            $allVnetSubnets = $VNetSubnets.split(";")
            foreach ($currentSubnet in $allVnetSubnets) {
                $address = $currentSubnet.split("/")[0]
                $prefixSize = $currentSubnet.split("/")[1]

                $xmlDoc = [System.Xml.XmlDocument](Get-Content $xml_Path);
                $siteCollectionNode = $xmlDoc.CreateElement("Address")
                $nodeCreation = $xmlDoc.SelectSingleNode("//VPNProfile/Route").AppendChild($siteCollectionNode)
                $RootFolderTextNode = $siteCollectionNode.AppendChild($xmlDoc.CreateTextNode($address));

                $siteCollectionNode = $xmlDoc.CreateElement("PrefixSize")
                $nodeCreation = $xmlDoc.SelectSingleNode("//VPNProfile/Route").AppendChild($siteCollectionNode)
                $RootFolderTextNode = $siteCollectionNode.AppendChild($xmlDoc.CreateTextNode($prefixSize));
    
                $xmlDoc.Save($xml_Path)
            }

            #Create TrafficFilter
            $xmlDoc = [System.Xml.XmlDocument](Get-Content $xml_Path);
            $siteCollectionNode = $xmlDoc.CreateElement("TrafficFilter")
            $nodeCreation = $xmlDoc.SelectSingleNode("//VPNProfile").AppendChild($siteCollectionNode)
            $xmlDoc.Save($xml_Path)

            #Get VNet Subnets and populate Address and prefix
            $allVnetSubnets = $VNetSubnets.split(";")
            foreach ($currentSubnet in $allVnetSubnets) {
                $xmlDoc = [System.Xml.XmlDocument](Get-Content $xml_Path);
                $siteCollectionNode = $xmlDoc.CreateElement("RemoteAddressRanges")
                $nodeCreation = $xmlDoc.SelectSingleNode("//VPNProfile/TrafficFilter").AppendChild($siteCollectionNode)
                $RootFolderTextNode = $siteCollectionNode.AppendChild($xmlDoc.CreateTextNode($currentSubnet));
    
                $xmlDoc.Save($xml_Path)
            }

            #Creating AlwaysOn
            $xmlDoc = [System.Xml.XmlDocument](Get-Content $xml_Path);
            $siteCollectionNode = $xmlDoc.CreateElement("AlwaysOn")
            $nodeCreation = $xmlDoc.SelectSingleNode("//VPNProfile").AppendChild($siteCollectionNode)
            $RootFolderTextNode = $siteCollectionNode.AppendChild($xmlDoc.CreateTextNode("true"));
            $xmlDoc.Save($xml_Path)

            #Creating DeviceTunnel
            $xmlDoc = [System.Xml.XmlDocument](Get-Content $xml_Path);
            $siteCollectionNode = $xmlDoc.CreateElement("DeviceTunnel")
            $nodeCreation = $xmlDoc.SelectSingleNode("//VPNProfile").AppendChild($siteCollectionNode)
            $RootFolderTextNode = $siteCollectionNode.AppendChild($xmlDoc.CreateTextNode("true"));
            $xmlDoc.Save($xml_Path)

            #Creating RegisterDNS
            $xmlDoc = [System.Xml.XmlDocument](Get-Content $xml_Path);
            $siteCollectionNode = $xmlDoc.CreateElement("RegisterDNS")
            $nodeCreation = $xmlDoc.SelectSingleNode("//VPNProfile").AppendChild($siteCollectionNode)
            $RootFolderTextNode = $siteCollectionNode.AppendChild($xmlDoc.CreateTextNode("true"));
            $xmlDoc.Save($xml_Path)

            #Removing XML Declaration 
            (Get-Content $xml_Path -raw).Replace('<?xml version="1.0"?>', '') | Set-Content $xml_Path;
            Log-MyEvent -Message "XML File creation completed"

            $returnType = ""
            $returnMsg = ""
            #Building VPN Client

            $buildStatus = Build-Vpn -XmlFilePathBuild $xml_Path -ProfileNameBuild $newVpnProfileName.split(".")[0] -VNetGatewayNameBuild $GatewayName
            if($buildStatus -eq "success")
            {
                #Create Registry Key and add Value to it
                $vpnConfiguredRegEditPath="HKLM:\Software\WAC\VPNConfigured"
                if(!(get-item -Path $vpnConfiguredRegEditPath -ErrorAction SilentlyContinue))
                {
                    $regKeyCreated = New-Item -Path HKLM:\Software -Name WAC\VPNConfigured -Force
                }
                $regKeyValue = $Subscription + ':' + $ResourceGroup + ':' + $GatewayName+ ':' + $VirtualNetwork+ ':' + $AddressSpace+':'+ $Location
    
                #Delete the previous gateway entry if already exists
                $readAllRegEdit = Get-Item -path $vpnConfiguredRegEditPath
                Foreach($thisRegEdit in $readAllRegEdit.Property)
                {
                    $thisRegValue = Get-ItemPropertyValue -path $vpnConfiguredRegEditPath -name $thisRegEdit
                    if($thisRegValue.ToLower() -eq $regKeyValue.ToLower())
                    {
                            Log-MyEvent -Message "Found previous connection with this Gateway. Deleting it"
                            Remove-ItemProperty -path $vpnConfiguredRegEditPath -name $thisRegEdit
                            Remove-VpnConnection -Name $thisRegEdit -Force -ErrorAction SilentlyContinue
                    }
                }
     
                Set-ItemProperty -Path $vpnConfiguredRegEditPath -Name $newVpnProfileName.split(".")[0] -Value $regKeyValue
                Log-MyEvent -Message "Logged into RegEdit successfully"

                $returnType = "success"
                $returnMsg = ""
            }
            else
            {
                #Delete from RegEdit
                Remove-ItemProperty -path HKLM:\Software\WAC\VNetGatewayNotConfigured -name $GatewayName -ErrorAction SilentlyContinue
                Log-MyEvent -Message "Removed from VNetGatewayNotConfigured RegEdit"
                $returnType = "fail"
                $returnMsg = "Building VPN on target machine failed"
            }
        }
        Catch [Exception] {
           Log-MyEvent -Message "Error occured during downloading and building VPN client"
           Log-MyEvent -Message $_.Exception.Message
           #Delete from RegEdit
           Remove-ItemProperty -path HKLM:\Software\WAC\VNetGatewayNotConfigured -name $GatewayName -ErrorAction SilentlyContinue
           Log-MyEvent -Message "Removed from VNetGatewayNotConfigured RegEdit"
           $returnType = "fail"
           $returnMsg = $_.Exception.Message
        }
        Log-MyEvent -Message "Ending Building process for -'$GatewayName'"
        $myResponse = New-Object -TypeName psobject

        $myResponse | Add-Member -MemberType NoteProperty -Name 'Status' -Value $returnType -ErrorAction SilentlyContinue
        $myResponse | Add-Member -MemberType NoteProperty -Name 'Message' -Value $returnMsg -ErrorAction SilentlyContinue

        $myResponse
    }
    else
    {
    
        Log-MyEvent -Message "Error Downloading VPN Client"
        #Delete from RegEdit
        Remove-ItemProperty -path HKLM:\Software\WAC\VNetGatewayNotConfigured -name $GatewayName -ErrorAction SilentlyContinue
        Log-MyEvent -Message "Removed from VNetGatewayNotConfigured RegEdit"
        Log-MyEvent -Message "Ending Building process with error for -'$GatewayName'"
    }
}
else
{
   Log-MyEvent -Message "Error in subscription selection."
   #Delete from RegEdit
   Remove-ItemProperty -path HKLM:\Software\WAC\VNetGatewayNotConfigured -name $GatewayName -ErrorAction SilentlyContinue
   Log-MyEvent -Message "Removed from VNetGatewayNotConfigured RegEdit"
   Log-MyEvent -Message "Ending Building process with error for -'$GatewayName'"
}
}
## [END] Complete-P2SVPNConfiguration ##
function Disable-AzureRmContextAutosave {
<#

.SYNOPSIS
Disable AzureRm Context Auto save

.DESCRIPTION
This script is used to disable AzureRm Context Auto save

.ROLE
Administrators

#>
$azureRmModule = Get-Module AzureRM -ListAvailable | Microsoft.PowerShell.Utility\Select-Object -Property Name -ErrorAction SilentlyContinue
if (!$azureRmModule.Name) {   
    $packageProvIntsalled = Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
    $armIntalled = Install-Module AzureRm -Force   
} 
Disable-AzureRmContextAutosave
}
## [END] Disable-AzureRmContextAutosave ##
function Get-ClientAddressSpace {
<#

.SYNOPSIS
Get Client Address Space

.DESCRIPTION
This script is used to get client address space

.ROLE
Readers

#>
$clientAddressSpace = ""
Try
{
    #Fetch the IP Address of the Machine. There might be many IP Addresses, Here first index is getting fetched
    $ip = get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object {$_.Ipaddress.length -gt 1}
    $cidr = (Get-NetIPAddress -IPAddress $ip.ipaddress[0]).PrefixLength
    $clientaddr = "127.0.0.1/32"

    function INT64-toIP() { 
      param ([int64]$int) 
      return (([math]::truncate($int/16777216)).tostring()+"."+([math]::truncate(($int%16777216)/65536)).tostring()+"."+([math]::truncate(($int%65536)/256)).tostring()+"."+([math]::truncate($int%256)).tostring() )
    } 

    if ($cidr){
        $ipaddr = [Net.IPAddress]::Parse($ip.ipaddress[0])
        $maskaddr = [Net.IPAddress]::Parse((INT64-toIP -int ([convert]::ToInt64(("1"*$cidr+"0"*(32-$cidr)),2))))
        $networkaddr = new-object net.ipaddress ($maskaddr.address -band $ipaddr.address)
        $clientAddressSpace = "$networkaddr/$cidr"
    }
}
Catch
{
    $clientAddressSpace = ""
}
$clientAddressSpace
}
## [END] Get-ClientAddressSpace ##
function Get-Networks {
<#

.SYNOPSIS
Gets the network ip configuration.

.DESCRIPTION
Gets the network ip configuration. The supported Operating Systems are Window Server 2012, Windows Server 2012R2, Windows Server 2016.

.ROLE
Readers

#>
Import-Module NetAdapter
Import-Module NetTCPIP
Import-Module DnsClient

Set-StrictMode -Version 5.0
$ErrorActionPreference = 'SilentlyContinue'

# Get all net information
$netAdapter = Get-NetAdapter

# conditions used to select the proper ip address for that object modeled after ibiza method.
# We only want manual (set by user manually), dhcp (set up automatically with dhcp), or link (set from link address)
# fe80 is the prefix for link local addresses, so that is the format want if the suffix origin is link
# SkipAsSource -eq zero only grabs ip addresses with skipassource set to false so we only get the preffered ip address
$ipAddress = Get-NetIPAddress | Where-Object {($_.SuffixOrigin -eq 'Manual') -or ($_.SuffixOrigin -eq 'Dhcp') -or (($_.SuffixOrigin -eq 'Link') -and (($_.IPAddress.StartsWith('fe80:')) -or ($_.IPAddress.StartsWith('2001:'))))}

$netIPInterface = Get-NetIPInterface
$netRoute = Get-NetRoute -PolicyStore ActiveStore
$dnsServer = Get-DnsClientServerAddress

# Load in relevant net information by name
Foreach ($currentNetAdapter in $netAdapter) {
    $result = New-Object PSObject

    # Net Adapter information
    $result | Add-Member -MemberType NoteProperty -Name 'InterfaceAlias' -Value $currentNetAdapter.InterfaceAlias
    $result | Add-Member -MemberType NoteProperty -Name 'InterfaceIndex' -Value $currentNetAdapter.InterfaceIndex
    $result | Add-Member -MemberType NoteProperty -Name 'InterfaceDescription' -Value $currentNetAdapter.InterfaceDescription
    $result | Add-Member -MemberType NoteProperty -Name 'Status' -Value $currentNetAdapter.Status
    $result | Add-Member -MemberType NoteProperty -Name 'MacAddress' -Value $currentNetAdapter.MacAddress
    $result | Add-Member -MemberType NoteProperty -Name 'LinkSpeed' -Value $currentNetAdapter.LinkSpeed

    # Net IP Address information
    # Primary addresses are used for outgoing calls so SkipAsSource is false (0)
    # Should only return one if properly configured, but it is possible to set multiple, so collect all
    $primaryIPv6Addresses = $ipAddress | Where-Object {($_.InterfaceAlias -eq $currentNetAdapter.Name) -and ($_.AddressFamily -eq 'IPv6') -and ($_.SkipAsSource -eq 0)}
    if ($primaryIPv6Addresses) {
        $ipArray = New-Object System.Collections.ArrayList
        $linkLocalArray = New-Object System.Collections.ArrayList
        Foreach ($address in $primaryIPv6Addresses) {
            if ($address -ne $null -and $address.IPAddress -ne $null -and $address.IPAddress.StartsWith('fe80')) {
                $linkLocalArray.Add(($address.IPAddress, $address.PrefixLength)) > $null
            }
            else {
                $ipArray.Add(($address.IPAddress, $address.PrefixLength)) > $null
            }
        }
        $result | Add-Member -MemberType NoteProperty -Name 'PrimaryIPv6Address' -Value $ipArray
        $result | Add-Member -MemberType NoteProperty -Name 'LinkLocalIPv6Address' -Value $linkLocalArray
    }

    $primaryIPv4Addresses = $ipAddress | Where-Object {($_.InterfaceAlias -eq $currentNetAdapter.Name) -and ($_.AddressFamily -eq 'IPv4') -and ($_.SkipAsSource -eq 0)}
    if ($primaryIPv4Addresses) {
        $ipArray = New-Object System.Collections.ArrayList
        Foreach ($address in $primaryIPv4Addresses) {
            $ipArray.Add(($address.IPAddress, $address.PrefixLength)) > $null
        }
        $result | Add-Member -MemberType NoteProperty -Name 'PrimaryIPv4Address' -Value $ipArray
    }

    # Secondary addresses are not used for outgoing calls so SkipAsSource is true (1)
    # There will usually not be secondary addresses, but collect them just in case
    $secondaryIPv6Adresses = $ipAddress | Where-Object {($_.InterfaceAlias -eq $currentNetAdapter.Name) -and ($_.AddressFamily -eq 'IPv6') -and ($_.SkipAsSource -eq 1)}
    if ($secondaryIPv6Adresses) {
        $ipArray = New-Object System.Collections.ArrayList
        Foreach ($address in $secondaryIPv6Adresses) {
            $ipArray.Add(($address.IPAddress, $address.PrefixLength)) > $null
        }
        $result | Add-Member -MemberType NoteProperty -Name 'SecondaryIPv6Address' -Value $ipArray
    }

    $secondaryIPv4Addresses = $ipAddress | Where-Object {($_.InterfaceAlias -eq $currentNetAdapter.Name) -and ($_.AddressFamily -eq 'IPv4') -and ($_.SkipAsSource -eq 1)}
    if ($secondaryIPv4Addresses) {
        $ipArray = New-Object System.Collections.ArrayList
        Foreach ($address in $secondaryIPv4Addresses) {
            $ipArray.Add(($address.IPAddress, $address.PrefixLength)) > $null
        }
        $result | Add-Member -MemberType NoteProperty -Name 'SecondaryIPv4Address' -Value $ipArray
    }

    # Net IP Interface information
    $currentDhcpIPv4 = $netIPInterface | Where-Object {($_.InterfaceAlias -eq $currentNetAdapter.Name) -and ($_.AddressFamily -eq 'IPv4')}
    if ($currentDhcpIPv4) {
        $result | Add-Member -MemberType NoteProperty -Name 'DhcpIPv4' -Value $currentDhcpIPv4.Dhcp
        $result | Add-Member -MemberType NoteProperty -Name 'IPv4Enabled' -Value $true
    }
    else {
        $result | Add-Member -MemberType NoteProperty -Name 'IPv4Enabled' -Value $false
    }

    $currentDhcpIPv6 = $netIPInterface | Where-Object {($_.InterfaceAlias -eq $currentNetAdapter.Name) -and ($_.AddressFamily -eq 'IPv6')}
    if ($currentDhcpIPv6) {
        $result | Add-Member -MemberType NoteProperty -Name 'DhcpIPv6' -Value $currentDhcpIPv6.Dhcp
        $result | Add-Member -MemberType NoteProperty -Name 'IPv6Enabled' -Value $true
    }
    else {
        $result | Add-Member -MemberType NoteProperty -Name 'IPv6Enabled' -Value $false
    }

    # Net Route information
    # destination prefix for selected ipv6 address is always ::/0
    $currentIPv6DefaultGateway = $netRoute | Where-Object {($_.InterfaceAlias -eq $currentNetAdapter.Name) -and ($_.DestinationPrefix -eq '::/0')}
    if ($currentIPv6DefaultGateway) {
        $ipArray = New-Object System.Collections.ArrayList
        Foreach ($address in $currentIPv6DefaultGateway) {
            if ($address.NextHop) {
                $ipArray.Add($address.NextHop) > $null
            }
        }
        $result | Add-Member -MemberType NoteProperty -Name 'IPv6DefaultGateway' -Value $ipArray
    }

    # destination prefix for selected ipv4 address is always 0.0.0.0/0
    $currentIPv4DefaultGateway = $netRoute | Where-Object {($_.InterfaceAlias -eq $currentNetAdapter.Name) -and ($_.DestinationPrefix -eq '0.0.0.0/0')}
    if ($currentIPv4DefaultGateway) {
        $ipArray = New-Object System.Collections.ArrayList
        Foreach ($address in $currentIPv4DefaultGateway) {
            if ($address.NextHop) {
                $ipArray.Add($address.NextHop) > $null
            }
        }
        $result | Add-Member -MemberType NoteProperty -Name 'IPv4DefaultGateway' -Value $ipArray
    }

    # DNS information
    # dns server util code for ipv4 is 2
    $currentIPv4DnsServer = $dnsServer | Where-Object {($_.InterfaceAlias -eq $currentNetAdapter.Name) -and ($_.AddressFamily -eq 2)}
    if ($currentIPv4DnsServer) {
        $ipArray = New-Object System.Collections.ArrayList
        Foreach ($address in $currentIPv4DnsServer) {
            if ($address.ServerAddresses) {
                $ipArray.Add($address.ServerAddresses) > $null
            }
        }
        $result | Add-Member -MemberType NoteProperty -Name 'IPv4DNSServer' -Value $ipArray
    }

    # dns server util code for ipv6 is 23
    $currentIPv6DnsServer = $dnsServer | Where-Object {($_.InterfaceAlias -eq $currentNetAdapter.Name) -and ($_.AddressFamily -eq 23)}
    if ($currentIPv6DnsServer) {
        $ipArray = New-Object System.Collections.ArrayList
        Foreach ($address in $currentIPv6DnsServer) {
            if ($address.ServerAddresses) {
                $ipArray.Add($address.ServerAddresses) > $null
            }
        }
        $result | Add-Member -MemberType NoteProperty -Name 'IPv6DNSServer' -Value $ipArray
    }

    $adapterGuid = $currentNetAdapter.InterfaceGuid
    if ($adapterGuid) {
      $regPath = "Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$($adapterGuid)"
      $ipv4Properties = Get-ItemProperty $regPath
      if ($ipv4Properties -and $ipv4Properties.NameServer) {
        $result | Add-Member -MemberType NoteProperty -Name 'IPv4DnsManuallyConfigured' -Value $true
      } else {
        $result | Add-Member -MemberType NoteProperty -Name 'IPv4DnsManuallyConfigured' -Value $false
      }

      $regPath = "Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters\Interfaces\$($adapterGuid)"
      $ipv6Properties = Get-ItemProperty $regPath
      if ($ipv6Properties -and $ipv6Properties.NameServer) {
        $result | Add-Member -MemberType NoteProperty -Name 'IPv6DnsManuallyConfigured' -Value $true
      } else {
        $result | Add-Member -MemberType NoteProperty -Name 'IPv6DnsManuallyConfigured' -Value $false
      }
    }

    $result
}

}
## [END] Get-Networks ##
function Get-RootCertValue {
<#

.SYNOPSIS
Storing Root and Client certificate, and then generate certificate value

.DESCRIPTION
This script is used to Storing Root and Client certificate provided by users, and then generate certificate value

.ROLE
Administrators

#>
param(
    [Parameter(Mandatory = $true)]
    [String]
    $RootCertPath,
    [Parameter(Mandatory = $true)]
    [String]
    $ClientCertPath,
    [Parameter(Mandatory = $true)]
    [String]
    $Password
)
$certName = ""
$content = ""

#Import Root certificate to Localmachine Root
if (Test-Path $RootCertPath) {
    $rootCertImported = Import-Certificate -FilePath $RootCertPath -certstorelocation 'Cert:\LocalMachine\Root'
    $certName = $rootCertImported.Subject.Split('=')[1]
    $content = @(
		[System.Convert]::ToBase64String($rootCertImported.RawData, 'InsertLineBreaks')
    )
    #Removing uploaded root cert file
    Remove-Item -path $RootCertPath -Force -Recurse -ErrorAction SilentlyContinue
}

#Import Client certificate to Localmachine My
if (Test-Path $ClientCertPath) {

    $securePassword = ConvertTo-SecureString $Password -asplaintext -force 
    $clientCertImported = Import-PfxCertificate -FilePath $ClientCertPath -CertStoreLocation Cert:\LocalMachine\My -Password $securePassword
    
    #Removing uploaded client cert file
    Remove-Item -path $ClientCertPath -Force -Recurse -ErrorAction SilentlyContinue
}

if($clientCertImported)
{
	$result = New-Object System.Object
	$result | Add-Member -MemberType NoteProperty -Name 'RootCertName' -Value $certName
	$result | Add-Member -MemberType NoteProperty -Name 'Content' -Value $content
	$result
}
}
## [END] Get-RootCertValue ##
function Get-VNetGatewayNameFromRegEdit {
<#

.SYNOPSIS
Reading Virtual Network Gateway information from Event Log

.DESCRIPTION
This Script is used to read Virtual Network Gateway information from Event Log

.ROLE
Administrators

#>

function Return-Object($rawData,$keyName)
{
	#Preparing Result object
    $subscriptionID = $rawData.Split(":")[0]
    $resourceGroup = $rawData.Split(":")[1]
    $vNetGateway = $rawData.Split(":")[2]

    $result = New-Object System.Object
    $result | Add-Member -MemberType NoteProperty -Name 'SubscriptionID' -Value $subscriptionID
    $result | Add-Member -MemberType NoteProperty -Name 'ResourceGroup' -Value $resourceGroup
    $result | Add-Member -MemberType NoteProperty -Name 'VNetGateway' -Value $vNetGateway
    $result | Add-Member -MemberType NoteProperty -Name 'KeyName' -Value $keyName
    $result
}

#Fetching from RegEdit (Only available/not configured)
$regEditPath = "HKLM:\Software\WAC\VNetGatewayNotConfigured"
$regItems = Get-Item -path $regEditPath -ErrorAction SilentlyContinue
Foreach($regitem in $regItems.Property)
{
  $regValue = Get-ItemPropertyValue -path $regEditPath -name $regitem
  Return-Object $regValue $regitem
}
}
## [END] Get-VNetGatewayNameFromRegEdit ##
function Get-VPNGatewayStatus {
<#

.SYNOPSIS
Check if the same gateway record is available

.DESCRIPTION
This Script is used to check if the same gateway record is available

.ROLE
Readers

#>
Param(
    [Parameter(Mandatory = $true)]
    [string] $Subscription,
    [Parameter(Mandatory = $true)]
    [string] $ResourceGroup,
    [Parameter(Mandatory = $true)]
    [string] $VNetGateway
)

$result = $false

$regKeyValue = $Subscription + ":" + $ResourceGroup + ":" + $VNetGateway

$vpnConfiguredRegEditPath = "HKLM:\Software\WAC\VNetGatewayNotConfigured"
if((Get-Item -Path $vpnConfiguredRegEditPath -ErrorAction SilentlyContinue))
{
    #check previous gateway entry if already exists
    $readAllRegEdit = Get-Item -Path $vpnConfiguredRegEditPath
    $isRecordAvailable = "0"
    Foreach($thisRegEdit in $readAllRegEdit.Property)
    {
        $thisRegValue = Get-ItemPropertyValue -Path $vpnConfiguredRegEditPath -Name $thisRegEdit
        if($thisRegValue.ToLower() -eq $regKeyValue.ToLower())
        {
            $isRecordAvailable = "1"
        }
    }

    if($isRecordAvailable -eq "1")
    {
         $result = $true
    }
    else
    {
         $result = $false
    }

}
else
{
    $result = $false
}

$result
}
## [END] Get-VPNGatewayStatus ##
function Get-VpnConnections {
<#

.SYNOPSIS
Get VPN Connections

.DESCRIPTION
This script is used to List all VPN Connection by reading from Registration Key and 
matching with machine connected P2S VPn and Return Details

.ROLE
Reader

#>
Try
{
    $allVpnConnections = Get-VpnConnection -ErrorAction SilentlyContinue
    #Get VPN Profile Names from Registration Key
    $regEditPath = "HKLM:\SOFTWARE\WAC\VPNConfigured"
    $regItems = Get-Item -path $regEditPath -ErrorAction SilentlyContinue
    Foreach($regitem in $regItems.Property)
    {
        #Check if VPN Connection is available or not
        $thisVpn = $allVpnConnections | Where-Object {$_.name -eq $regitem} -ErrorAction SilentlyContinue
        if($thisVpn)
        {
            $regValue = Get-ItemPropertyValue -path $regEditPath -name $regitem -ErrorAction SilentlyContinue

            if($regValue)
            {
                #Generating response
                $connectionName = $regitem
                $description = "Point to Site VPN to Azure Virtual Network '"+ $regValue.split(":")[3]+"'"
                $connectionStatus = $thisVpn.ConnectionStatus
                $tunnelType = $thisVpn.TunnelType
                $vNetGatewayAddress = $thisVpn.ServerAddress
                $subscription = $regValue.split(":")[0]
                $resourceGroup = $regValue.split(":")[1]
                $vNetGateway = $regValue.split(":")[2]
                $virtualNetwork = $regValue.split(":")[3]
                $localNetworkAddressSpace = $regValue.split(":")[4]
                $location = $regValue.split(":")[5]

                #Preparing Object
                $myResponse = New-Object -TypeName psobject
                $myResponse | Add-Member -MemberType NoteProperty -Name 'Name' -Value $connectionName -ErrorAction SilentlyContinue
                $myResponse | Add-Member -MemberType NoteProperty -Name 'Description' -Value $description -ErrorAction SilentlyContinue
                $myResponse | Add-Member -MemberType NoteProperty -Name 'ConnectionStatus' -Value $connectionStatus -ErrorAction SilentlyContinue
                $myResponse | Add-Member -MemberType NoteProperty -Name 'TunnelType' -Value $tunnelType -ErrorAction SilentlyContinue
                $myResponse | Add-Member -MemberType NoteProperty -Name 'VnetGatewayAddress' -Value $vNetGatewayAddress -ErrorAction SilentlyContinue
                $myResponse | Add-Member -MemberType NoteProperty -Name 'Subscription' -Value $subscription -ErrorAction SilentlyContinue
                $myResponse | Add-Member -MemberType NoteProperty -Name 'ResourceGroup' -Value $resourceGroup -ErrorAction SilentlyContinue
                $myResponse | Add-Member -MemberType NoteProperty -Name 'VnetGateway' -Value $vNetGateway -ErrorAction SilentlyContinue
                $myResponse | Add-Member -MemberType NoteProperty -Name 'VirtualNetwork' -Value $virtualNetwork -ErrorAction SilentlyContinue
                $myResponse | Add-Member -MemberType NoteProperty -Name 'LocalNetworkAddressSpace' -Value $localNetworkAddressSpace -ErrorAction SilentlyContinue
                $myResponse | Add-Member -MemberType NoteProperty -Name 'Location' -Value $location -ErrorAction SilentlyContinue


                $myResponse 
            }
        }
    }
}
Catch [Exception]{
    $myResponse = "Failed"
    $myResponse
}

}
## [END] Get-VpnConnections ##
function New-LogMyEvent {
<#

.SYNOPSIS
Logging My Event in Event Log

.DESCRIPTION
Logging My Event in Event Log

.ROLE
Administrators

#>
param(
    [Parameter(Mandatory = $true)]
    [String]
    $LogMessage
)
#Function to log event
function Log-MyEvent($Message){
    Try {
        $eventLogName = "ANA-LOG"
        $eventID = Get-Random -Minimum -1 -Maximum 65535
        #Create WAC specific Event Source if not exists
        $logFileExists = Get-EventLog -list | Where-Object {$_.logdisplayname -eq $eventLogName} 
        if (!$logFileExists) {
            New-EventLog -LogName $eventLogName -Source $eventLogName
        }
        #Prepare Event Log content and Write Event Log
        Write-EventLog -LogName $eventLogName -Source $eventLogName -EntryType Information -EventID $eventID -Message $Message

        $result = "Success"
    }
    Catch [Exception] {
        $result = $_.Exception.Message
    }
}

Log-MyEvent -Message "$LogMessage" 

}
## [END] New-LogMyEvent ##
function New-RegEditNotConfigured {
<#

.SYNOPSIS
Writing Virtual Network Gateway information into Event Log

.DESCRIPTION
This Script is used to store newly created Virtual Network Gateway information into Event Log

.ROLE
Administrators

#>
Param(
    [Parameter(Mandatory = $true)]
    [string] $Subscription,
    [Parameter(Mandatory = $true)]
    [string] $ResourceGroup,
    [Parameter(Mandatory = $true)]
    [string] $VNetGateway
)

$result = ""
Try {
    
    #Create Registry Key and add Value to it
    if(!(get-item -Path HKLM:\Software\WAC\VNetGatewayNotConfigured -ErrorAction SilentlyContinue))
    {
        $regKeyCreated = New-Item -Path HKLM:\Software -Name WAC\VNetGatewayNotConfigured -Force
    }
    $regKeyValue = $Subscription + ":" + $ResourceGroup + ":" + $VNetGateway
    Set-ItemProperty -Path HKLM:\Software\WAC\VNetGatewayNotConfigured -Name $VNetGateway -Value $regKeyValue
    
    $result = "Success"
}
Catch {
    $result = "Failed"
}
$result
}
## [END] New-RegEditNotConfigured ##
function New-SelfSignedRootCertificate {
<#

.SYNOPSIS
Create a Self-Signed Root certificate & Client Certificate

.DESCRIPTION
This script creates a Self-Signed Root certificate
The supported Operating Systems are Window Server 2012, Windows Server 2012R2, Windows Server 2016.

.ROLE
Readers

#>
param(
    [Parameter(Mandatory = $true)]
    [String]
    $VNetGatewayName
   
)
$content=""
Try
{
    #Finalizing name of the certificate
    $uniqueRootCertName = $VNetGatewayName+'-P2SRoot-'+(Get-Date -UFormat "%m%d%Y%H%M")
    $uniqueClientCertName = $VNetGatewayName+'-P2SClient-'+(Get-Date -UFormat "%m%d%Y%H%M")

    #Creating Root Certificate
    $myCert = New-SelfSignedCertificate -Type Custom -KeySpec Signature -Subject "CN=$uniqueRootCertName" -KeyExportPolicy Exportable -HashAlgorithm sha256 -KeyLength 2048 -CertStoreLocation "Cert:\LocalMachine\My" -KeyUsageProperty Sign -KeyUsage CertSign

    #Creating client certificate
    $myClientCert = New-SelfSignedCertificate -Type Custom -DnsName $uniqueClientCertName -KeySpec Signature -Subject "CN=$uniqueClientCertName" -KeyExportPolicy Exportable -HashAlgorithm sha256 -KeyLength 2048 -CertStoreLocation "Cert:\LocalMachine\My" -Signer $myCert -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.2") 

    #Create a Temp Folder if not exists
    $tempPath = "C:\WAC-TEMP"
    if (!(Test-Path $tempPath)) {
       $tempfolderCreated = New-Item -Path $tempPath -ItemType directory
    }

    #Moving Root certificate from 'Cert:\LocalMachine\My' to 'Cert:\LocalMachine\Root'
    $exportLocation = $tempPath+"\$uniqueRootCertName.cer"
    $certExported = Export-Certificate -cert $myCert -filepath $exportLocation
    $certImported = Import-Certificate -FilePath $exportLocation -certstorelocation 'cert:\LocalMachine\Root'

    #Get Base64 Certificate Content
    $content = @(
		[System.Convert]::ToBase64String($myCert.RawData, 'InsertLineBreaks')
    )

    #Deleting temporary exported certificate file
    if (Test-Path $exportLocation) {
         Remove-Item -path $exportLocation -Force -Recurse -ErrorAction SilentlyContinue
    }
}
Catch [Exception]
{
    $content = $_.Exception.Message
}

$Result = New-Object System.Object
$Result | Add-Member -MemberType NoteProperty -Name 'RootCertName' -Value $uniqueRootCertName
$Result | Add-Member -MemberType NoteProperty -Name 'Content' -Value $content
$Result

}
## [END] New-SelfSignedRootCertificate ##
function New-TempFolder {
<#

.SYNOPSIS
Create a Temporary Folder in C drive of Target server

.DESCRIPTION
This script creates a Temporary Folder in C drive of Target server

.ROLE
Administrators

#>
$tempPath = "C:\WAC-TEMP"
if (!(Test-Path $tempPath)) {
    $tempFolderCreated = New-Item -Path $tempPath -ItemType directory
}
$tempPath
}
## [END] New-TempFolder ##
function Remove-NotConfiguredGateway {
<#

.SYNOPSIS
Remove Not found gateway or not valid provisioning status of Gateway entry from VNetGatewayNotConfigured RegEdit

.DESCRIPTION
This script is used to Remove Not found gateway or not valid provisioning status of Gateway entry from VNetGatewayNotConfigured RegEdit

.ROLE
Administrators

#>
param(
    [Parameter(Mandatory = $true)]
    [String]
    $VNetGatewayName,
    [Parameter(Mandatory = $true)]
    [String]
    $TenantId,
    [Parameter(Mandatory = $true)]
    [String]
    $AppId
)
#Function to log event
function Log-MyEvent($Message) {
    Try {
        $eventLogName = "ANA-LOG"
        $eventID = Get-Random -Minimum -1 -Maximum 65535
        #Create WAC specific Event Source if not exists
        $logFileExists = Get-EventLog -list | Where-Object {$_.logdisplayname -eq $eventLogName} 
        if (!$logFileExists) {
            New-EventLog -LogName $eventLogName -Source $eventLogName
        }
        #Prepare Event Log content and Write Event Log
        Write-EventLog -LogName $eventLogName -Source $eventLogName -EntryType Information -EventID $eventID -Message $Message

        $result = "Success"
    }
    Catch [Exception] {
        $result = $_.Exception.Message
    }
}

Log-MyEvent -Message "Gateway $VNetGatewayName doesn't exists or in failed state. so deleting this Gateway. Directory ID- $TenantId and App Id- $AppId" 
Remove-ItemProperty -path HKLM:\Software\WAC\VNetGatewayNotConfigured -name $VNetGatewayName
Log-MyEvent -Message "Gateway $VNetGatewayName has been deleted" 
}
## [END] Remove-NotConfiguredGateway ##
function Remove-VpnConnection {
<#

.SYNOPSIS
Remove VPN Connection

.DESCRIPTION
This script is used to remove VPN Connection

.ROLE
Administrators

#>
param(
    [Parameter(Mandatory = $true)]
    [String]
    $ConnectionName
   
)
#Removing VPN Connection
Remove-VpnConnection -Name $ConnectionName -Force

#Removing Item from RegEdit
Remove-ItemProperty -path HKLM:\Software\WAC\VPNConfigured -name $ConnectionName
}
## [END] Remove-VpnConnection ##
function Set-DhcpIP {
<#

.SYNOPSIS
Sets configuration of the specified network interface to use DHCP and updates DNS settings.

.DESCRIPTION
Sets configuration of the specified network interface to use DHCP and updates DNS settings. The supported Operating Systems are Window Server 2012, Windows Server 2012R2, Windows Server 2016.

.ROLE
Administrators

#>

param (
    [Parameter(Mandatory = $true)] [string] $interfaceIndex,
    [Parameter(Mandatory = $true)] [string] $addressFamily,
    [string] $preferredDNS,
    [string] $alternateDNS)

Import-Module NetTCPIP

$ErrorActionPreference = 'Stop'

$ipInterface = Get-NetIPInterface -InterfaceIndex $interfaceIndex -AddressFamily $addressFamily
$netIPAddress = Get-NetIPAddress -InterfaceIndex $interfaceIndex -AddressFamily $addressFamily -ErrorAction SilentlyContinue
if ($addressFamily -eq "IPv4") {
    $prefix = '0.0.0.0/0'
}
else {
    $prefix = '::/0'
}

$netRoute = Get-NetRoute -InterfaceIndex $interfaceIndex -DestinationPrefix $prefix -ErrorAction SilentlyContinue

# avoid extra work if dhcp already set up
if ($ipInterface.Dhcp -eq 'Disabled') {
    if ($netIPAddress) {
        $netIPAddress | Remove-NetIPAddress -Confirm:$false
    }
    if ($netRoute) {
        $netRoute | Remove-NetRoute -Confirm:$false
    }

    $ipInterface | Set-NetIPInterface -DHCP Enabled
}

# reset or configure dns servers
$interfaceAlias = $ipInterface.InterfaceAlias
if ($preferredDNS) {
    netsh.exe interface $addressFamily set dnsservers name="$interfaceAlias" source=static validate=yes address="$preferredDNS"
    if (($LASTEXITCODE -eq 0) -and $alternateDNS) {
        netsh.exe interface $addressFamily add dnsservers name="$interfaceAlias" validate=yes address="$alternateDNS"
    }
}
else {
    netsh.exe interface $addressFamily delete dnsservers name="$interfaceAlias" address=all
}

# captures exit code of netsh.exe
$LASTEXITCODE

}
## [END] Set-DhcpIP ##
function Set-P2SVPNStatus {
<#

.SYNOPSIS
Connect / Disconnect P2S VPN

.DESCRIPTION
This script is used to Connect / Disconnect P2S VPN

.ROLE
Administrators

#>
param(
    [Parameter(Mandatory = $true)]
    [String]
    $VpnProfileName,
    [Parameter(Mandatory = $true)]
    [Int]
    $StatusFlag
    #Flag "1" is to Connect VPN. Flaf "0" to disconnect VPN.
)
if($StatusFlag -eq 1)
{
    #Connect VPN
	$result = rasdial $VpnProfileName
	$result = [String] $result
}
Elseif($StatusFlag -eq 0)
{
    #Disconnect VPN
    $result =  rasdial $VpnProfileName /disconnect
    $result= [String] $result
}
else
{
    $result = "No flag provided. Use 1 to connect and 0 to disconnect"
}
$statusProperty = "success"
$contentProperty = $result

if($result -match 'error' -or $result -match 'unacceptable' -or $result -match 'not')
{
	$statusProperty = "error"
}

#Preparing response Object
$response = New-Object System.Object
$response | Add-Member -MemberType NoteProperty -Name 'status' -Value $statusProperty
$response | Add-Member -MemberType NoteProperty -Name 'content' -Value $contentProperty
$response
}
## [END] Set-P2SVPNStatus ##
function Set-StaticIP {
<#

.SYNOPSIS
Sets configuration of the specified network interface to use a static IP address and updates DNS settings.

.DESCRIPTION
Sets configuration of the specified network interface to use a static IP address and updates DNS settings. The supported Operating Systems are Window Server 2012, Windows Server 2012R2, Windows Server 2016.

.ROLE
Administrators

#>
param (
    [Parameter(Mandatory = $true)] [string] $interfaceIndex,
    [Parameter(Mandatory = $true)] [string] $ipAddress,
    [Parameter(Mandatory = $true)] [string] $prefixLength,
    [string] $defaultGateway,
    [string] $preferredDNS,
    [string] $alternateDNS,
    [Parameter(Mandatory = $true)] [string] $addressFamily)

Import-Module NetTCPIP

Set-StrictMode -Version 5.0
$ErrorActionPreference = 'Stop'

$netIPAddress = Get-NetIPAddress -InterfaceIndex $interfaceIndex -AddressFamily $addressFamily -ErrorAction SilentlyContinue

if ($addressFamily -eq "IPv4") {
    $prefix = '0.0.0.0/0'
}
else {
    $prefix = '::/0'
}

$netRoute = Get-NetRoute -InterfaceIndex $interfaceIndex -DestinationPrefix $prefix -ErrorAction SilentlyContinue

if ($netIPAddress) {
    $netIPAddress | Remove-NetIPAddress -Confirm:$false
}
if ($netRoute) {
    $netRoute | Remove-NetRoute -Confirm:$false
}

Set-NetIPInterface -InterfaceIndex $interfaceIndex -AddressFamily $addressFamily -DHCP Disabled

try {
    # this will fail if input is invalid
    if ($defaultGateway) {
        $netIPAddress | New-NetIPAddress -IPAddress $ipAddress -PrefixLength $prefixLength -DefaultGateway $defaultGateway -AddressFamily $addressFamily -ErrorAction Stop
    }
    else {
        $netIPAddress | New-NetIPAddress -IPAddress $ipAddress -PrefixLength $prefixLength -AddressFamily $addressFamily -ErrorAction Stop
    }
}
catch {
    # restore net route and ip address to previous values
    if ($netRoute -and $netIPAddress) {
        $netIPAddress | New-NetIPAddress -DefaultGateway $netRoute.NextHop -PrefixLength $netIPAddress.PrefixLength
    }
    elseif ($netIPAddress) {
        $netIPAddress | New-NetIPAddress
    }
    throw
}

$interfaceAlias = $netIPAddress.InterfaceAlias
if ($preferredDNS) {
    netsh.exe interface $addressFamily set dnsservers name="$interfaceAlias" source=static validate=yes address="$preferredDNS"
    if (($LASTEXITCODE -eq 0) -and $alternateDNS) {
        netsh.exe interface $addressFamily add dnsservers name="$interfaceAlias" validate=yes address="$alternateDNS"
    }
    return $LASTEXITCODE
}
else {
    return 0
}



}
## [END] Set-StaticIP ##
function Get-CimWin32LogicalDisk {
<#

.SYNOPSIS
Gets Win32_LogicalDisk object.

.DESCRIPTION
Gets Win32_LogicalDisk object.

.ROLE
Readers

#>
##SkipCheck=true##


import-module CimCmdlets

Get-CimInstance -Namespace root/cimv2 -ClassName Win32_LogicalDisk

}
## [END] Get-CimWin32LogicalDisk ##
function Get-CimWin32NetworkAdapter {
<#

.SYNOPSIS
Gets Win32_NetworkAdapter object.

.DESCRIPTION
Gets Win32_NetworkAdapter object.

.ROLE
Readers

#>
##SkipCheck=true##


import-module CimCmdlets

Get-CimInstance -Namespace root/cimv2 -ClassName Win32_NetworkAdapter

}
## [END] Get-CimWin32NetworkAdapter ##
function Get-CimWin32PhysicalMemory {
<#

.SYNOPSIS
Gets Win32_PhysicalMemory object.

.DESCRIPTION
Gets Win32_PhysicalMemory object.

.ROLE
Readers

#>
##SkipCheck=true##


import-module CimCmdlets

Get-CimInstance -Namespace root/cimv2 -ClassName Win32_PhysicalMemory

}
## [END] Get-CimWin32PhysicalMemory ##
function Get-CimWin32Processor {
<#

.SYNOPSIS
Gets Win32_Processor object.

.DESCRIPTION
Gets Win32_Processor object.

.ROLE
Readers

#>
##SkipCheck=true##


import-module CimCmdlets

Get-CimInstance -Namespace root/cimv2 -ClassName Win32_Processor

}
## [END] Get-CimWin32Processor ##
function Get-ClusterInventory {
<#

.SYNOPSIS
Retrieves the inventory data for a cluster.

.DESCRIPTION
Retrieves the inventory data for a cluster.

.ROLE
Readers

#>

import-module CimCmdlets -ErrorAction SilentlyContinue

# JEA code requires to pre-import the module (this is slow on failover cluster environment.)
import-module FailoverClusters -ErrorAction SilentlyContinue

<#

.SYNOPSIS
Get the name of this computer.

.DESCRIPTION
Get the best available name for this computer.  The FQDN is preferred, but when not avaialble
the NetBIOS name will be used instead.

#>

function getComputerName() {
    $computerSystem = Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue | Microsoft.PowerShell.Utility\Select-Object Name, DNSHostName

    if ($computerSystem) {
        $computerName = $computerSystem.DNSHostName

        if ($null -eq $computerName) {
            $computerName = $computerSystem.Name
        }

        return $computerName
    }

    return $null
}

<#

.SYNOPSIS
Are the cluster PowerShell cmdlets installed on this server?

.DESCRIPTION
Are the cluster PowerShell cmdlets installed on this server?

#>

function getIsClusterCmdletAvailable() {
    $cmdlet = Get-Command "Get-Cluster" -ErrorAction SilentlyContinue

    return !!$cmdlet
}

<#

.SYNOPSIS
Get the MSCluster Cluster CIM instance from this server.

.DESCRIPTION
Get the MSCluster Cluster CIM instance from this server.

#>
function getClusterCimInstance() {
    $namespace = Get-CimInstance -Namespace root/MSCluster -ClassName __NAMESPACE -ErrorAction SilentlyContinue

    if ($namespace) {
        return Get-CimInstance -Namespace root/mscluster MSCluster_Cluster -ErrorAction SilentlyContinue | Microsoft.PowerShell.Utility\Select-Object fqdn, S2DEnabled
    }

    return $null
}


<#

.SYNOPSIS
Determines if the current cluster supports Failover Clusters Time Series Database.

.DESCRIPTION
Use the existance of the path value of cmdlet Get-StorageHealthSetting to determine if TSDB 
is supported or not.

#>
function getClusterPerformanceHistoryPath() {
    return $null -ne (Get-StorageSubSystem clus* | Get-StorageHealthSetting -Name "System.PerformanceHistory.Path")
}

<#

.SYNOPSIS
Get some basic information about the cluster from the cluster.

.DESCRIPTION
Get the needed cluster properties from the cluster.

#>
function getClusterInfo() {
    $returnValues = @{}

    $returnValues.Fqdn = $null
    $returnValues.isS2DEnabled = $false
    $returnValues.isTsdbEnabled = $false

    $cluster = getClusterCimInstance
    if ($cluster) {
        $returnValues.Fqdn = $cluster.fqdn
        $isS2dEnabled = !!(Get-Member -InputObject $cluster -Name "S2DEnabled") -and ($cluster.S2DEnabled -eq 1)
        $returnValues.isS2DEnabled = $isS2dEnabled

        if ($isS2DEnabled) {
            $returnValues.isTsdbEnabled = getClusterPerformanceHistoryPath
        } else {
            $returnValues.isTsdbEnabled = $false
        }
    }

    return $returnValues
}

<#

.SYNOPSIS
Are the cluster PowerShell Health cmdlets installed on this server?

.DESCRIPTION
Are the cluster PowerShell Health cmdlets installed on this server?

s#>
function getisClusterHealthCmdletAvailable() {
    $cmdlet = Get-Command -Name "Get-HealthFault" -ErrorAction SilentlyContinue

    return !!$cmdlet
}
<#

.SYNOPSIS
Are the Britannica (sddc management resources) available on the cluster?

.DESCRIPTION
Are the Britannica (sddc management resources) available on the cluster?

#>
function getIsBritannicaEnabled() {
    return $null -ne (Get-CimInstance -Namespace root/sddc/management -ClassName SDDC_Cluster -ErrorAction SilentlyContinue)
}

<#

.SYNOPSIS
Are the Britannica (sddc management resources) virtual machine available on the cluster?

.DESCRIPTION
Are the Britannica (sddc management resources) virtual machine available on the cluster?

#>
function getIsBritannicaVirtualMachineEnabled() {
    return $null -ne (Get-CimInstance -Namespace root/sddc/management -ClassName SDDC_VirtualMachine -ErrorAction SilentlyContinue)
}

<#

.SYNOPSIS
Are the Britannica (sddc management resources) virtual switch available on the cluster?

.DESCRIPTION
Are the Britannica (sddc management resources) virtual switch available on the cluster?

#>
function getIsBritannicaVirtualSwitchEnabled() {
    return $null -ne (Get-CimInstance -Namespace root/sddc/management -ClassName SDDC_VirtualSwitch -ErrorAction SilentlyContinue)
}

###########################################################################
# main()
###########################################################################

$clusterInfo = getClusterInfo

$result = New-Object PSObject

$result | Add-Member -MemberType NoteProperty -Name 'Fqdn' -Value $clusterInfo.Fqdn
$result | Add-Member -MemberType NoteProperty -Name 'IsS2DEnabled' -Value $clusterInfo.isS2DEnabled
$result | Add-Member -MemberType NoteProperty -Name 'IsTsdbEnabled' -Value $clusterInfo.isTsdbEnabled
$result | Add-Member -MemberType NoteProperty -Name 'IsClusterHealthCmdletAvailable' -Value (getIsClusterHealthCmdletAvailable)
$result | Add-Member -MemberType NoteProperty -Name 'IsBritannicaEnabled' -Value (getIsBritannicaEnabled)
$result | Add-Member -MemberType NoteProperty -Name 'IsBritannicaVirtualMachineEnabled' -Value (getIsBritannicaVirtualMachineEnabled)
$result | Add-Member -MemberType NoteProperty -Name 'IsBritannicaVirtualSwitchEnabled' -Value (getIsBritannicaVirtualSwitchEnabled)
$result | Add-Member -MemberType NoteProperty -Name 'IsClusterCmdletAvailable' -Value (getIsClusterCmdletAvailable)
$result | Add-Member -MemberType NoteProperty -Name 'CurrentClusterNode' -Value (getComputerName)

$result

}
## [END] Get-ClusterInventory ##
function Get-ClusterNodes {
<#

.SYNOPSIS
Retrieves the inventory data for cluster nodes in a particular cluster.

.DESCRIPTION
Retrieves the inventory data for cluster nodes in a particular cluster.

.ROLE
Readers

#>

import-module CimCmdlets

# JEA code requires to pre-import the module (this is slow on failover cluster environment.)
import-module FailoverClusters -ErrorAction SilentlyContinue

###############################################################################
# Constants
###############################################################################

Set-Variable -Name LogName -Option Constant -Value "Microsoft-ServerManagementExperience" -ErrorAction SilentlyContinue
Set-Variable -Name LogSource -Option Constant -Value "SMEScripts" -ErrorAction SilentlyContinue
Set-Variable -Name ScriptName -Option Constant -Value $MyInvocation.ScriptName -ErrorAction SilentlyContinue

<#

.SYNOPSIS
Are the cluster PowerShell cmdlets installed?

.DESCRIPTION
Use the Get-Command cmdlet to quickly test if the cluster PowerShell cmdlets
are installed on this server.

#>

function getClusterPowerShellSupport() {
    $cmdletInfo = Get-Command 'Get-ClusterNode' -ErrorAction SilentlyContinue

    return $cmdletInfo -and $cmdletInfo.Name -eq "Get-ClusterNode"
}

<#

.SYNOPSIS
Get the cluster nodes using the cluster CIM provider.

.DESCRIPTION
When the cluster PowerShell cmdlets are not available fallback to using
the cluster CIM provider to get the needed information.

#>

function getClusterNodeCimInstances() {
    # Change the WMI property NodeDrainStatus to DrainStatus to match the PS cmdlet output.
    return Get-CimInstance -Namespace root/mscluster MSCluster_Node -ErrorAction SilentlyContinue | `
        Microsoft.PowerShell.Utility\Select-Object @{Name="DrainStatus"; Expression={$_.NodeDrainStatus}}, DynamicWeight, Name, NodeWeight, FaultDomain, State
}

<#

.SYNOPSIS
Get the cluster nodes using the cluster PowerShell cmdlets.

.DESCRIPTION
When the cluster PowerShell cmdlets are available use this preferred function.

#>

function getClusterNodePsInstances() {
    return Get-ClusterNode -ErrorAction SilentlyContinue | Microsoft.PowerShell.Utility\Select-Object DrainStatus, DynamicWeight, Name, NodeWeight, FaultDomain, State
}

<#

.SYNOPSIS
Use DNS services to get the FQDN of the cluster NetBIOS name.

.DESCRIPTION
Use DNS services to get the FQDN of the cluster NetBIOS name.

.Notes
It is encouraged that the caller add their approprate -ErrorAction when
calling this function.

#>

function getClusterNodeFqdn([string]$clusterNodeName) {
    return ([System.Net.Dns]::GetHostEntry($clusterNodeName)).HostName
}

<#

.SYNOPSIS
Writes message to event log as warning.

.DESCRIPTION
Writes message to event log as warning.

#>

function writeToEventLog([string]$message) {
    Microsoft.PowerShell.Management\New-EventLog -LogName $LogName -Source $LogSource -ErrorAction SilentlyContinue
    Microsoft.PowerShell.Management\Write-EventLog -LogName $LogName -Source $LogSource -EventId 0 -Category 0 -EntryType Warning `
        -Message $message  -ErrorAction SilentlyContinue
}

<#

.SYNOPSIS
Get the cluster nodes.

.DESCRIPTION
When the cluster PowerShell cmdlets are available get the information about the cluster nodes
using PowerShell.  When the cmdlets are not available use the Cluster CIM provider.

#>

function getClusterNodes() {
    $isClusterCmdletAvailable = getClusterPowerShellSupport

    if ($isClusterCmdletAvailable) {
        $clusterNodes = getClusterNodePsInstances
    } else {
        $clusterNodes = getClusterNodeCimInstances
    }

    $clusterNodeMap = @{}

    foreach ($clusterNode in $clusterNodes) {
        $clusterNodeName = $clusterNode.Name.ToLower()
        try 
        {
            $clusterNodeFqdn = getClusterNodeFqdn $clusterNodeName -ErrorAction SilentlyContinue
        }
        catch 
        {
            $clusterNodeFqdn = $clusterNodeName
            writeToEventLog "[$ScriptName]: The fqdn for node '$clusterNodeName' could not be obtained. Defaulting to machine name '$clusterNodeName'"
        }

        $clusterNodeResult = New-Object PSObject

        $clusterNodeResult | Add-Member -MemberType NoteProperty -Name 'FullyQualifiedDomainName' -Value $clusterNodeFqdn
        $clusterNodeResult | Add-Member -MemberType NoteProperty -Name 'Name' -Value $clusterNodeName
        $clusterNodeResult | Add-Member -MemberType NoteProperty -Name 'DynamicWeight' -Value $clusterNode.DynamicWeight
        $clusterNodeResult | Add-Member -MemberType NoteProperty -Name 'NodeWeight' -Value $clusterNode.NodeWeight
        $clusterNodeResult | Add-Member -MemberType NoteProperty -Name 'FaultDomain' -Value $clusterNode.FaultDomain
        $clusterNodeResult | Add-Member -MemberType NoteProperty -Name 'State' -Value $clusterNode.State
        $clusterNodeResult | Add-Member -MemberType NoteProperty -Name 'DrainStatus' -Value $clusterNode.DrainStatus

        $clusterNodeMap.Add($clusterNodeName, $clusterNodeResult)
    }

    return $clusterNodeMap
}

###########################################################################
# main()
###########################################################################

getClusterNodes

}
## [END] Get-ClusterNodes ##
function Get-ServerInventory {
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
function Install-MMAgent {
<#

.SYNOPSIS
Download and install Microsoft Monitoring Agent for Windows.

.DESCRIPTION
Download and install Microsoft Monitoring Agent for Windows.

.PARAMETER workspaceId
The log analytics workspace id a target node has to connect to.

.PARAMETER workspacePrimaryKey
The primary key of log analytics workspace.

.PARAMETER taskName
The task name.

.ROLE
Readers

#>

param(
    [Parameter(Mandatory = $true)]
    [String]
    $workspaceId,
    [Parameter(Mandatory = $true)]
    [String]
    $workspacePrimaryKey,
    [Parameter(Mandatory = $true)]
    [String]
    $taskName
)

$Script = @'
$mmaExe = Join-Path -Path $env:temp -ChildPath 'MMASetup-AMD64.exe'
if (Test-Path $mmaExe) {
    Remove-Item $mmaExe
}

Invoke-WebRequest -Uri https://go.microsoft.com/fwlink/?LinkId=828603 -OutFile $mmaExe

$extractFolder = Join-Path -Path $env:temp -ChildPath 'SmeMMAInstaller'
if (Test-Path $extractFolder) {
    Remove-Item $extractFolder -Force -Recurse
}

&$mmaExe /c /t:$extractFolder
$setupExe = Join-Path -Path $extractFolder -ChildPath 'setup.exe'
for ($i=1; $i -le 10; $i++) {
    if(-Not(Test-Path $setupExe)) {
        sleep -s 6
    }
}

&$setupExe /qn NOAPM=1 ADD_OPINSIGHTS_WORKSPACE=1 OPINSIGHTS_WORKSPACE_AZURE_CLOUD_TYPE=0 OPINSIGHTS_WORKSPACE_ID=$workspaceId OPINSIGHTS_WORKSPACE_KEY=$workspacePrimaryKey AcceptEndUserLicenseAgreement=1
'@

$Script = '$workspaceId = ' + "'$workspaceId';" + $Script
$Script = '$workspacePrimaryKey =' + "'$workspacePrimaryKey';" + $Script

$ScriptFile = Join-Path -Path $env:LocalAppData -ChildPath "$taskName.ps1"
$ResultFile = Join-Path -Path $env:temp -ChildPath "$taskName.log"
if (Test-Path $ResultFile) {
    Remove-Item $ResultFile
}

$Script | Out-File $ScriptFile
if (-Not(Test-Path $ScriptFile)) {
    $message = "Failed to create file:" + $ScriptFile
    Write-Error $message
    return #If failed to create script file, no need continue just return here
}

#Create a scheduled task
$User = [Security.Principal.WindowsIdentity]::GetCurrent()
$Role = (New-Object Security.Principal.WindowsPrincipal $User).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
$arg = "-NoProfile -NoLogo -NonInteractive -ExecutionPolicy Bypass -c $ScriptFile >> $ResultFile 2>&1"
if(!$Role)
{
  Write-Warning "To perform some operations you must run an elevated Windows PowerShell console."
}

$Scheduler = New-Object -ComObject Schedule.Service

#Try to connect to schedule service 3 time since it may fail the first time
for ($i=1; $i -le 3; $i++)
{
  Try
  {
    $Scheduler.Connect()
    Break
  }
  Catch
  {
    if($i -ge 3)
    {
      Write-EventLog -LogName Application -Source "SME Register $taskName" -EntryType Error -EventID 1 -Message "Can't connect to Schedule service"
      Write-Error "Can't connect to Schedule service" -ErrorAction Stop
    }
    else
    {
      Start-Sleep -s 1
    }
  }
}

$RootFolder = $Scheduler.GetFolder("\")
#Delete existing task
if($RootFolder.GetTasks(0) | Where-Object {$_.Name -eq $TaskName})
{
  Write-Debug("Deleting existing task" + $TaskName)
  $RootFolder.DeleteTask($TaskName,0)
}

$Task = $Scheduler.NewTask(0)
$RegistrationInfo = $Task.RegistrationInfo
$RegistrationInfo.Description = $TaskName
$RegistrationInfo.Author = $User.Name

$Triggers = $Task.Triggers
$Trigger = $Triggers.Create(7) #TASK_TRIGGER_REGISTRATION: Starts the task when the task is registered.
$Trigger.Enabled = $true

$Settings = $Task.Settings
$Settings.Enabled = $True
$Settings.StartWhenAvailable = $True
$Settings.Hidden = $False
$Settings.ExecutionTimeLimit  = "PT20M" # 20 minutes

$Action = $Task.Actions.Create(0)
$Action.Path = "powershell"
$Action.Arguments = $arg

#Tasks will be run with the highest privileges
$Task.Principal.RunLevel = 1

#Start the task to run in Local System account. 6: TASK_CREATE_OR_UPDATE
$RootFolder.RegisterTaskDefinition($TaskName, $Task, 6, "SYSTEM", $Null, 1) | Out-Null
#Wait for running task finished
$RootFolder.GetTask($TaskName).Run(0) | Out-Null
while($Scheduler.GetRunningTasks(0) | Where-Object {$_.Name -eq $TaskName})
{
  Start-Sleep -s 1
}

#Clean up
$RootFolder.DeleteTask($TaskName,0)
Remove-Item $ScriptFile

if (Test-Path $ResultFile)
{
    Get-Content -Path $ResultFile | Out-String -Stream
    Remove-Item $ResultFile
}

}
## [END] Install-MMAgent ##

# SIG # Begin signature block
# MIIdjgYJKoZIhvcNAQcCoIIdfzCCHXsCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUDWRqpPjQ3KgWG62LPt6yIPbv
# 0nCgghhqMIIE2jCCA8KgAwIBAgITMwAAAR4S9EGOKUc2xgAAAAABHjANBgkqhkiG
# 9w0BAQUFADB3MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4G
# A1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSEw
# HwYDVQQDExhNaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EwHhcNMTgxMDI0MjEwNzM2
# WhcNMjAwMTEwMjEwNzM2WjCByjELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hp
# bmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jw
# b3JhdGlvbjElMCMGA1UECxMcTWljcm9zb2Z0IEFtZXJpY2EgT3BlcmF0aW9uczEm
# MCQGA1UECxMdVGhhbGVzIFRTUyBFU046QUUyQy1FMzJCLTFBRkMxJTAjBgNVBAMT
# HE1pY3Jvc29mdCBUaW1lLVN0YW1wIFNlcnZpY2UwggEiMA0GCSqGSIb3DQEBAQUA
# A4IBDwAwggEKAoIBAQDzb28mkTnE/Qx2JfKv+ykRWkxyTx2Gt1TN7wBh/G2D9Z9J
# oWGDsHVyLMxbJzirFVKII+4mj6qKjCbMhWWhrUcKaez6q7hh6tpNL/knhCj48lZe
# FYMbSNAcY+cgHt5i+xV3kh6sZz1x8VrNopcripG3IjrbIJ5a47/NMUVCZyLwn+V8
# yz0elFnqH52amVPanbS0Re4Mku1U9IEOAdhlFd1AMfNL4kumj3GucM+W1rL9jsRO
# 9kgSsMDFwsM5lDAhn3toZcapx0yMi961g05xhpSmZ/hI4+szlAyqH0HN1CXjq2XQ
# 6PhRYcn4o+BdUzYbJ8rSrU3VwUhOzhv7hdTl5R2DAgMBAAGjggEJMIIBBTAdBgNV
# HQ4EFgQU3NGCgrg8lSUew8D8IjHvi1eXPDUwHwYDVR0jBBgwFoAUIzT42VJGcArt
# QPt2+7MrsMM1sw8wVAYDVR0fBE0wSzBJoEegRYZDaHR0cDovL2NybC5taWNyb3Nv
# ZnQuY29tL3BraS9jcmwvcHJvZHVjdHMvTWljcm9zb2Z0VGltZVN0YW1wUENBLmNy
# bDBYBggrBgEFBQcBAQRMMEowSAYIKwYBBQUHMAKGPGh0dHA6Ly93d3cubWljcm9z
# b2Z0LmNvbS9wa2kvY2VydHMvTWljcm9zb2Z0VGltZVN0YW1wUENBLmNydDATBgNV
# HSUEDDAKBggrBgEFBQcDCDANBgkqhkiG9w0BAQUFAAOCAQEAWR2z6mBmVxajzjhf
# 10GitwpRJTFbD1PjMopI0EPjoQiZUNQk4pxBLpQMSTv983jET+IHM6tU58aH8zI9
# 6GRYxgqVC4fNWWmZZq+OJ8+kLC95j65TbHarqzjZeW8x7nbZBd+l27sDbgyE99YA
# m9LwKecAYJY4IOcC2vl1CwdBzVMvnwN+mbgHw5X1hEdrjRODR0Fq0p/Yp6olDZ+4
# 8Wytf1U2gnOxM+3oMIg5OMnZ36pvAU05trHyX3/sx4vv/iKnuenE4tnK7MVqF4Jd
# u49bNdNxrivTf7UIluolvjaOIfnePwHajCAKRQLcHcD9LgtFg5PFEFhx64v52YnZ
# YAWspDCCBf8wggPnoAMCAQICEzMAAAEDXiUcmR+jHrgAAAAAAQMwDQYJKoZIhvcN
# AQELBQAwfjELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNV
# BAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEoMCYG
# A1UEAxMfTWljcm9zb2Z0IENvZGUgU2lnbmluZyBQQ0EgMjAxMTAeFw0xODA3MTIy
# MDA4NDhaFw0xOTA3MjYyMDA4NDhaMHQxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpX
# YXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQg
# Q29ycG9yYXRpb24xHjAcBgNVBAMTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjCCASIw
# DQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBANGUdjbmhqs2/mn5RnyLiFDLkHB/
# sFWpJB1+OecFnw+se5eyznMK+9SbJFwWtTndG34zbBH8OybzmKpdU2uqw+wTuNLv
# z1d/zGXLr00uMrFWK040B4n+aSG9PkT73hKdhb98doZ9crF2m2HmimRMRs621TqM
# d5N3ZyGctloGXkeG9TzRCcoNPc2y6aFQeNGEiOIBPCL8r5YIzF2ZwO3rpVqYkvXI
# QE5qc6/e43R6019Gl7ziZyh3mazBDjEWjwAPAf5LXlQPysRlPwrjo0bb9iwDOhm+
# aAUWnOZ/NL+nh41lOSbJY9Tvxd29Jf79KPQ0hnmsKtVfMJE75BRq67HKBCMCAwEA
# AaOCAX4wggF6MB8GA1UdJQQYMBYGCisGAQQBgjdMCAEGCCsGAQUFBwMDMB0GA1Ud
# DgQWBBRHvsDL4aY//WXWOPIDXbevd/dA/zBQBgNVHREESTBHpEUwQzEpMCcGA1UE
# CxMgTWljcm9zb2Z0IE9wZXJhdGlvbnMgUHVlcnRvIFJpY28xFjAUBgNVBAUTDTIz
# MDAxMis0Mzc5NjUwHwYDVR0jBBgwFoAUSG5k5VAF04KqFzc3IrVtqMp1ApUwVAYD
# VR0fBE0wSzBJoEegRYZDaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9j
# cmwvTWljQ29kU2lnUENBMjAxMV8yMDExLTA3LTA4LmNybDBhBggrBgEFBQcBAQRV
# MFMwUQYIKwYBBQUHMAKGRWh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMv
# Y2VydHMvTWljQ29kU2lnUENBMjAxMV8yMDExLTA3LTA4LmNydDAMBgNVHRMBAf8E
# AjAAMA0GCSqGSIb3DQEBCwUAA4ICAQCf9clTDT8NJuyiRNgN0Z9jlgZLPx5cxTOj
# pMNsrx/AAbrrZeyeMxAPp6xb1L2QYRfnMefDJrSs9SfTSJOGiP4SNZFkItFrLTuo
# LBWUKdI3luY1/wzOyAYWFp4kseI5+W4OeNgMG7YpYCd2NCSb3bmXdcsBO62CEhYi
# gIkVhLuYUCCwFyaGSa/OfUUVQzSWz4FcGCzUk/Jnq+JzyD2jzfwyHmAc6bAbMPss
# uwculoSTRShUXM2W/aDbgdi2MMpDsfNIwLJGHF1edipYn9Tu8vT6SEy1YYuwjEHp
# qridkPT/akIPuT7pDuyU/I2Au3jjI6d4W7JtH/lZwX220TnJeeCDHGAK2j2w0e02
# v0UH6Rs2buU9OwUDp9SnJRKP5najE7NFWkMxgtrYhK65sB919fYdfVERNyfotTWE
# cfdXqq76iXHJmNKeWmR2vozDfRVqkfEU9PLZNTG423L6tHXIiJtqv5hFx2ay1//O
# kpB15OvmhtLIG9snwFuVb0lvWF1pKt5TS/joynv2bBX5AxkPEYWqT5q/qlfdYMb1
# cSD0UaiayunR6zRHPXX6IuxVP2oZOWsQ6Vo/jvQjeDCy8qY4yzWNqphZJEC4Omek
# B1+g/tg7SRP7DOHtC22DUM7wfz7g2QjojCFKQcLe645b7gPDHW5u5lQ1ZmdyfBrq
# UvYixHI/rjCCBgcwggPvoAMCAQICCmEWaDQAAAAAABwwDQYJKoZIhvcNAQEFBQAw
# XzETMBEGCgmSJomT8ixkARkWA2NvbTEZMBcGCgmSJomT8ixkARkWCW1pY3Jvc29m
# dDEtMCsGA1UEAxMkTWljcm9zb2Z0IFJvb3QgQ2VydGlmaWNhdGUgQXV0aG9yaXR5
# MB4XDTA3MDQwMzEyNTMwOVoXDTIxMDQwMzEzMDMwOVowdzELMAkGA1UEBhMCVVMx
# EzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoT
# FU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEhMB8GA1UEAxMYTWljcm9zb2Z0IFRpbWUt
# U3RhbXAgUENBMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAn6Fssd/b
# SJIqfGsuGeG94uPFmVEjUK3O3RhOJA/u0afRTK10MCAR6wfVVJUVSZQbQpKumFww
# JtoAa+h7veyJBw/3DgSY8InMH8szJIed8vRnHCz8e+eIHernTqOhwSNTyo36Rc8J
# 0F6v0LBCBKL5pmyTZ9co3EZTsIbQ5ShGLieshk9VUgzkAyz7apCQMG6H81kwnfp+
# 1pez6CGXfvjSE/MIt1NtUrRFkJ9IAEpHZhEnKWaol+TTBoFKovmEpxFHFAmCn4Tt
# VXj+AZodUAiFABAwRu233iNGu8QtVJ+vHnhBMXfMm987g5OhYQK1HQ2x/PebsgHO
# IktU//kFw8IgCwIDAQABo4IBqzCCAacwDwYDVR0TAQH/BAUwAwEB/zAdBgNVHQ4E
# FgQUIzT42VJGcArtQPt2+7MrsMM1sw8wCwYDVR0PBAQDAgGGMBAGCSsGAQQBgjcV
# AQQDAgEAMIGYBgNVHSMEgZAwgY2AFA6sgmBAVieX5SUT/CrhClOVWeSkoWOkYTBf
# MRMwEQYKCZImiZPyLGQBGRYDY29tMRkwFwYKCZImiZPyLGQBGRYJbWljcm9zb2Z0
# MS0wKwYDVQQDEyRNaWNyb3NvZnQgUm9vdCBDZXJ0aWZpY2F0ZSBBdXRob3JpdHmC
# EHmtFqFKoKWtTHNY9AcTLmUwUAYDVR0fBEkwRzBFoEOgQYY/aHR0cDovL2NybC5t
# aWNyb3NvZnQuY29tL3BraS9jcmwvcHJvZHVjdHMvbWljcm9zb2Z0cm9vdGNlcnQu
# Y3JsMFQGCCsGAQUFBwEBBEgwRjBEBggrBgEFBQcwAoY4aHR0cDovL3d3dy5taWNy
# b3NvZnQuY29tL3BraS9jZXJ0cy9NaWNyb3NvZnRSb290Q2VydC5jcnQwEwYDVR0l
# BAwwCgYIKwYBBQUHAwgwDQYJKoZIhvcNAQEFBQADggIBABCXisNcA0Q23em0rXfb
# znlRTQGxLnRxW20ME6vOvnuPuC7UEqKMbWK4VwLLTiATUJndekDiV7uvWJoc4R0B
# hqy7ePKL0Ow7Ae7ivo8KBciNSOLwUxXdT6uS5OeNatWAweaU8gYvhQPpkSokInD7
# 9vzkeJkuDfcH4nC8GE6djmsKcpW4oTmcZy3FUQ7qYlw/FpiLID/iBxoy+cwxSnYx
# PStyC8jqcD3/hQoT38IKYY7w17gX606Lf8U1K16jv+u8fQtCe9RTciHuMMq7eGVc
# WwEXChQO0toUmPU8uWZYsy0v5/mFhsxRVuidcJRsrDlM1PZ5v6oYemIp76KbKTQG
# dxpiyT0ebR+C8AvHLLvPQ7Pl+ex9teOkqHQ1uE7FcSMSJnYLPFKMcVpGQxS8s7Ow
# TWfIn0L/gHkhgJ4VMGboQhJeGsieIiHQQ+kr6bv0SMws1NgygEwmKkgkX1rqVu+m
# 3pmdyjpvvYEndAYR7nYhv5uCwSdUtrFqPYmhdmG0bqETpr+qR/ASb/2KMmyy/t9R
# yIwjyWa9nR2HEmQCPS2vWY+45CHltbDKY7R4VAXUQS5QrJSwpXirs6CWdRrZkocT
# dSIvMqgIbqBbjCW/oO+EyiHW6x5PyZruSeD3AWVviQt9yGnI5m7qp5fOMSn/DsVb
# XNhNG6HY+i+ePy5VFmvJE6P9MIIHejCCBWKgAwIBAgIKYQ6Q0gAAAAAAAzANBgkq
# hkiG9w0BAQsFADCBiDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24x
# EDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlv
# bjEyMDAGA1UEAxMpTWljcm9zb2Z0IFJvb3QgQ2VydGlmaWNhdGUgQXV0aG9yaXR5
# IDIwMTEwHhcNMTEwNzA4MjA1OTA5WhcNMjYwNzA4MjEwOTA5WjB+MQswCQYDVQQG
# EwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwG
# A1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSgwJgYDVQQDEx9NaWNyb3NvZnQg
# Q29kZSBTaWduaW5nIFBDQSAyMDExMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIIC
# CgKCAgEAq/D6chAcLq3YbqqCEE00uvK2WCGfQhsqa+laUKq4BjgaBEm6f8MMHt03
# a8YS2AvwOMKZBrDIOdUBFDFC04kNeWSHfpRgJGyvnkmc6Whe0t+bU7IKLMOv2akr
# rnoJr9eWWcpgGgXpZnboMlImEi/nqwhQz7NEt13YxC4Ddato88tt8zpcoRb0Rrrg
# OGSsbmQ1eKagYw8t00CT+OPeBw3VXHmlSSnnDb6gE3e+lD3v++MrWhAfTVYoonpy
# 4BI6t0le2O3tQ5GD2Xuye4Yb2T6xjF3oiU+EGvKhL1nkkDstrjNYxbc+/jLTswM9
# sbKvkjh+0p2ALPVOVpEhNSXDOW5kf1O6nA+tGSOEy/S6A4aN91/w0FK/jJSHvMAh
# dCVfGCi2zCcoOCWYOUo2z3yxkq4cI6epZuxhH2rhKEmdX4jiJV3TIUs+UsS1Vz8k
# A/DRelsv1SPjcF0PUUZ3s/gA4bysAoJf28AVs70b1FVL5zmhD+kjSbwYuER8ReTB
# w3J64HLnJN+/RpnF78IcV9uDjexNSTCnq47f7Fufr/zdsGbiwZeBe+3W7UvnSSmn
# Eyimp31ngOaKYnhfsi+E11ecXL93KCjx7W3DKI8sj0A3T8HhhUSJxAlMxdSlQy90
# lfdu+HggWCwTXWCVmj5PM4TasIgX3p5O9JawvEagbJjS4NaIjAsCAwEAAaOCAe0w
# ggHpMBAGCSsGAQQBgjcVAQQDAgEAMB0GA1UdDgQWBBRIbmTlUAXTgqoXNzcitW2o
# ynUClTAZBgkrBgEEAYI3FAIEDB4KAFMAdQBiAEMAQTALBgNVHQ8EBAMCAYYwDwYD
# VR0TAQH/BAUwAwEB/zAfBgNVHSMEGDAWgBRyLToCMZBDuRQFTuHqp8cx0SOJNDBa
# BgNVHR8EUzBRME+gTaBLhklodHRwOi8vY3JsLm1pY3Jvc29mdC5jb20vcGtpL2Ny
# bC9wcm9kdWN0cy9NaWNSb29DZXJBdXQyMDExXzIwMTFfMDNfMjIuY3JsMF4GCCsG
# AQUFBwEBBFIwUDBOBggrBgEFBQcwAoZCaHR0cDovL3d3dy5taWNyb3NvZnQuY29t
# L3BraS9jZXJ0cy9NaWNSb29DZXJBdXQyMDExXzIwMTFfMDNfMjIuY3J0MIGfBgNV
# HSAEgZcwgZQwgZEGCSsGAQQBgjcuAzCBgzA/BggrBgEFBQcCARYzaHR0cDovL3d3
# dy5taWNyb3NvZnQuY29tL3BraW9wcy9kb2NzL3ByaW1hcnljcHMuaHRtMEAGCCsG
# AQUFBwICMDQeMiAdAEwAZQBnAGEAbABfAHAAbwBsAGkAYwB5AF8AcwB0AGEAdABl
# AG0AZQBuAHQALiAdMA0GCSqGSIb3DQEBCwUAA4ICAQBn8oalmOBUeRou09h0ZyKb
# C5YR4WOSmUKWfdJ5DJDBZV8uLD74w3LRbYP+vj/oCso7v0epo/Np22O/IjWll11l
# hJB9i0ZQVdgMknzSGksc8zxCi1LQsP1r4z4HLimb5j0bpdS1HXeUOeLpZMlEPXh6
# I/MTfaaQdION9MsmAkYqwooQu6SpBQyb7Wj6aC6VoCo/KmtYSWMfCWluWpiW5IP0
# wI/zRive/DvQvTXvbiWu5a8n7dDd8w6vmSiXmE0OPQvyCInWH8MyGOLwxS3OW560
# STkKxgrCxq2u5bLZ2xWIUUVYODJxJxp/sfQn+N4sOiBpmLJZiWhub6e3dMNABQam
# ASooPoI/E01mC8CzTfXhj38cbxV9Rad25UAqZaPDXVJihsMdYzaXht/a8/jyFqGa
# J+HNpZfQ7l1jQeNbB5yHPgZ3BtEGsXUfFL5hYbXw3MYbBL7fQccOKO7eZS/sl/ah
# XJbYANahRr1Z85elCUtIEJmAH9AAKcWxm6U/RXceNcbSoqKfenoi+kiVH6v7RyOA
# 9Z74v2u3S5fi63V4GuzqN5l5GEv/1rMjaHXmr/r8i+sLgOppO6/8MO0ETI7f33Vt
# Y5E90Z1WTk+/gFcioXgRMiF670EKsT/7qMykXcGhiJtXcVZOSEXAQsmbdlsKgEhr
# /Xmfwb1tbWrJUnMTDXpQzTGCBI4wggSKAgEBMIGVMH4xCzAJBgNVBAYTAlVTMRMw
# EQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVN
# aWNyb3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNp
# Z25pbmcgUENBIDIwMTECEzMAAAEDXiUcmR+jHrgAAAAAAQMwCQYFKw4DAhoFAKCB
# ojAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYK
# KwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUAYyEC0B5P5eZ6VzvSEOSbrQT9/Aw
# QgYKKwYBBAGCNwIBDDE0MDKgFIASAE0AaQBjAHIAbwBzAG8AZgB0oRqAGGh0dHA6
# Ly93d3cubWljcm9zb2Z0LmNvbTANBgkqhkiG9w0BAQEFAASCAQBSIjqAczRbmb14
# Wblzp132AmX4DvqqFmwdCqUxqFqKttA7FHu1haspM6ol2sa4hl9ix02/hk0afvu8
# l0Hr6jrfNK0VMUtWw99QFCfFwEJS39TSkHfYd3V1nzRulSX2UpDwdPdSkGBoV4NC
# hwJTIBsZ/gfDu7AZSzBEd+yLJnPn7PeXM7TL3FqzRa+g7t5zvxYF0JwsD6z+SR3D
# z9T6WH+tg6XxGIk1xfs+VKleAQ/4OWCLUa2wd2ptogrLVY1nX9a1UcUK++TkoiJf
# Y9UNM1zqrWDFEy0K6Dx4zuPbKDorEH5EJbgJSwGWM+jn+AobVhu8n/q2Ej3zHPcd
# pPJ+iCFQoYICKDCCAiQGCSqGSIb3DQEJBjGCAhUwggIRAgEBMIGOMHcxCzAJBgNV
# BAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4w
# HAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xITAfBgNVBAMTGE1pY3Jvc29m
# dCBUaW1lLVN0YW1wIFBDQQITMwAAAR4S9EGOKUc2xgAAAAABHjAJBgUrDgMCGgUA
# oF0wGAYJKoZIhvcNAQkDMQsGCSqGSIb3DQEHATAcBgkqhkiG9w0BCQUxDxcNMTkw
# NDAyMTkxOTAyWjAjBgkqhkiG9w0BCQQxFgQUROdO02QPb1WUt32MePviny0Uu5Yw
# DQYJKoZIhvcNAQEFBQAEggEAdXF9x2RIjyHLFPYr2oTxjWBbI7Rwl51kAJmXojeH
# 3BUIV2/+4JbmimdediHaTpDRA+geqPRW1Lm0uFYxUStwD/fWRU42GTeKbu9SYme1
# GmoCM4//SBUjmYdIwFal7/1QFT/RJwIW5wUchQCMeHgEz5ceW9Dp2OxJDvsDTT2c
# MQC8Sj8S+54nPu1oYaVVA2lNVSIWfjaTJPcMho0fHtmGn7cUGjU4st0IefAqnEYS
# +L96e2vwsXBP2TxlWtuJ5IjteETlJFwlHimuQjNQZ1dfJuzBY6N3O2JDcHlxJfHW
# HTyVlXRY8TJQGB0L9m9RmGZRukqPisDS5Hu8FC837WdLyg==
# SIG # End signature block
