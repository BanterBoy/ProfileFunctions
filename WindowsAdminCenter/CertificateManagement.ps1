function Export-Certificate {
<#

.SYNOPSIS
Script that exports certificate.

.DESCRIPTION
Script that exports certificate.

.ROLE
Administrators

#>

 param (
		[Parameter(Mandatory = $true)]
	    [String]
        $certPath,
        [Parameter(Mandatory = $true)]
	    [String]
        $exportType,
        [String]
        $fileName,
		[string]
        $exportChain,
		[string]
		$exportProperties,
		[string]
		$usersAndGroups,
		[string]
		$password,
		[string]
		$invokeUserName,
		[string]
		$invokePassword
    )

# Notes: invokeUserName and invokePassword are not used on this version. Remained for future use.

$Script=@'
try {
	Import-Module PKI
	if ($exportChain -eq "CertificateChain")
	{
		$chainOption = "BuildChain";
	}
	else
	{
		$chainOption = "EndEntityCertOnly";
	}

	$ExportPfxCertParams = @{ Cert = $certPath; FilePath = $tempPath; ChainOption = $chainOption }
	if ($exportProperties -ne "Extended")
	{
		$ExportPfxCertParams.NoProperties = $true
	}

	if ($password)
	{
		Add-Type -AssemblyName System.Security
		$encode = new-object System.Text.UTF8Encoding
		$encrypted = [System.Convert]::FromBase64String($password)
		$decrypted = [System.Security.Cryptography.ProtectedData]::Unprotect($encrypted, $null, [System.Security.Cryptography.DataProtectionScope]::LocalMachine)
		$password = $encode.GetString($decrypted)
		$pwd = ConvertTo-SecureString -String $password -Force -AsPlainText;
		$ExportPfxCertParams.Password = $pwd
	}

	if ($usersAndGroups)
	{
		$ExportPfxCertParams.ProtectTo = $usersAndGroups
	}

	Export-PfxCertificate @ExportPfxCertParams | ConvertTo-Json -depth 10 | Out-File $ResultFile
} catch {
	$_.Exception.Message | ConvertTo-Json | Out-File $ErrorFile
}
'@

function CalculateFilePath
{
	param (
		[Parameter(Mandatory = $true)]
		[String]
		$exportType,
		[Parameter(Mandatory = $true)]
		[String]
		$certPath
	)

	$extension = $exportType.ToLower();
	if ($exportType.ToLower() -eq "cert")
	{
		$extension = "cer";
	}

    if (!$fileName)
    {
        $arr = $certPath.Split('\\');
        $fileName = $arr[3];
    }

	(Get-Childitem -Path Env:* | where-Object {$_.Name -eq "TEMP"}).value  + "\" + $fileName + "." + $extension
}

$tempPath = CalculateFilePath -exportType $exportType -certPath $certPath;
if ($exportType -ne "Pfx")
{
	Export-Certificate -Cert $certPath -FilePath $tempPath -Type $exportType -Force
	return;
}

# PFX private key handlings
if ($password) {
	# encrypt password with current user.
	Add-Type -AssemblyName System.Security
	$encode = new-object System.Text.UTF8Encoding
	$bytes = $encode.GetBytes($password)
	$encrypt = [System.Security.Cryptography.ProtectedData]::Protect($bytes, $null, [System.Security.Cryptography.DataProtectionScope]::LocalMachine)
	$password = [System.Convert]::ToBase64String($encrypt)
}

# Pass parameters to script and generate script file in temp folder
$ResultFile = $env:temp + "\export-certificate_result.json"
$ErrorFile = $env:temp + "\export-certificate_error.json"
if (Test-Path $ErrorFile) {
    Remove-Item $ErrorFile
}

if (Test-Path $ResultFile) {
    Remove-Item $ResultFile
}

$Script = '$certPath=' + "'$certPath';" +
		  '$tempPath=' + "'$tempPath';" +
          '$exportType=' + "'$exportType';" +
          '$exportChain=' + "'$exportChain';" +
    	  '$exportProperties=' + "'$exportProperties';" +
		  '$usersAndGroups=' + "'$usersAndGroups';" +
	      '$password=' + "'$password';" +
		  '$ResultFile=' + "'$ResultFile';" +
		  '$ErrorFile=' + "'$ErrorFile';" +
          $Script
$ScriptFile = $env:temp + "\export-certificate.ps1"
$Script | Out-File $ScriptFile

# Create a scheduled task
$TaskName = "SMEExportCertificate"

$User = [Security.Principal.WindowsIdentity]::GetCurrent()
$Role = (New-Object Security.Principal.WindowsPrincipal $User).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
$arg = "-NoProfile -NoLogo -NonInteractive -ExecutionPolicy Bypass -File $ScriptFile"
if (!$Role)
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
		if ($i -ge 3)
		{
			Write-EventLog -LogName Application -Source "SME Export certificate" -EntryType Error -EventID 1 -Message "Can't connect to Schedule service"
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
if ($RootFolder.GetTasks(0) | Where-Object {$_.Name -eq $TaskName})
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

$Action = $Task.Actions.Create(0)
$Action.Path = "powershell"
$Action.Arguments = $arg

#Tasks will be run with the highest privileges
$Task.Principal.RunLevel = 1

#### example Start the task with user specified invoke username and password
####$Task.Principal.LogonType = 1
####$RootFolder.RegisterTaskDefinition($TaskName, $Task, 6, $invokeUserName, $invokePassword, 1) | Out-Null

#### Start the task with SYSTEM creds
$RootFolder.RegisterTaskDefinition($TaskName, $Task, 6, "SYSTEM", $Null, 1) | Out-Null
#Wait for running task finished
$RootFolder.GetTask($TaskName).Run(0) | Out-Null
while ($Scheduler.GetRunningTasks(0) | Where-Object {$_.Name -eq $TaskName})
{
	Start-Sleep -s 2
}

#Clean up
$RootFolder.DeleteTask($TaskName,0)
Remove-Item $ScriptFile
#Return result
if (Test-Path $ErrorFile) {
	$result = Get-Content -Raw -Path $ErrorFile | ConvertFrom-Json
    Remove-Item $ErrorFile
    Remove-Item $ResultFile
	throw $result
}

if (Test-Path $ResultFile)
{
    $result = Get-Content -Raw -Path $ResultFile | ConvertFrom-Json
    Remove-Item $ResultFile
    return $result
}

}
## [END] Export-Certificate ##
function Get-CertificateOverview {
<#

.SYNOPSIS
Script that get the certificates overview (total, ex) in the system.

.DESCRIPTION
Script that get the certificates overview (total, ex) in the system.

.ROLE
Readers

#>

 param (
		[Parameter(Mandatory = $true)]
	    [String]
        $channel,
        [String]
        $path = "Cert:\",
        [int]
        $nearlyExpiredThresholdInDays = 60
    )

Import-Module Microsoft.PowerShell.Diagnostics -ErrorAction SilentlyContinue

# Notes: $channelList must be in this format:
#"Microsoft-Windows-CertificateServicesClient-Lifecycle-System*,Microsoft-Windows-CertificateServices-Deployment*,
#Microsoft-Windows-CertificateServicesClient-CredentialRoaming*,Microsoft-Windows-CertificateServicesClient-Lifecycle-User*,
#Microsoft-Windows-CAPI2*,Microsoft-Windows-CertPoleEng*"

function Get-ChildLeafRecurse
{
    param (
        [Parameter(Mandatory = $true)]
	    [String]
        $pspath
    )
    try
	{
    Get-ChildItem -Path $pspath -ErrorAction SilentlyContinue |Where-Object{!$_.PSIsContainer} | Write-Output
    Get-ChildItem -Path $pspath -ErrorAction SilentlyContinue |Where-Object{$_.PSIsContainer} | ForEach-Object{
            $location = "Cert:\$($_.location)";
            if ($_.psChildName -ne $_.location)
            {
                $location += "\$($_.PSChildName)";
            }
            Get-ChildLeafRecurse $location | ForEach-Object { Write-Output $_};
        }
	} catch {}
}

$certCounts = New-Object -TypeName psobject
$certs = Get-ChildLeafRecurse -pspath $path

$channelList = $channel.split(",")
$totalCount = 0
$x = Get-WinEvent -ListLog $channelList -Force -ErrorAction 'SilentlyContinue'
for ($i = 0; $i -le $x.Count; $i++){
    $totalCount += $x[$i].RecordCount;
}

$certCounts | add-member -Name "allCount" -Value $certs.length -MemberType NoteProperty
$certCounts | add-member -Name "expiredCount" -Value ($certs | Where-Object {$_.NotAfter -lt [DateTime]::Now }).length -MemberType NoteProperty
$certCounts | add-member -Name "nearExpiredCount" -Value ($certs | Where-Object { ($_.NotAfter -gt [DateTime]::Now ) -and ($_.NotAfter -lt [DateTime]::Now.AddDays($nearlyExpiredThresholdInDays) ) }).length -MemberType NoteProperty
$certCounts | add-member -Name "eventCount" -Value $totalCount -MemberType NoteProperty

$certCounts




}
## [END] Get-CertificateOverview ##
function Get-CertificateScopes {
<#

.SYNOPSIS
Script that enumerates all the certificate scopes/locations in the system.

.DESCRIPTION
Script that enumerates all the certificate scopes/locations in the system.

.ROLE
Readers

#>
Get-ChildItem | Microsoft.PowerShell.Utility\Select-Object -Property @{name ="Name";expression= {$($_.LocationName)}}


}
## [END] Get-CertificateScopes ##
function Get-CertificateStores {
<#

.SYNOPSIS
Script that enumerates all the certificate stores in the system inside the scope/location.

.DESCRIPTION
Script that enumerates all the certificate stores in the system inside the scope/location.

.ROLE
Readers

#>

Param([string]$scope)

Get-ChildItem $('Cert:' + $scope) | Microsoft.PowerShell.Utility\Select-Object Name, @{name ="Path";expression= {$($_.Location.toString() + '\' + $_.Name)}}

}
## [END] Get-CertificateStores ##
function Get-CertificateTreeNodes {
<#

.SYNOPSIS
Script that enumerates all the certificate scopes/locations in the system.

.DESCRIPTION
Script that enumerates all the certificate scopes/locations in the system.

.ROLE
Readers

#>
$treeNodes = @()
$treeNodes = Get-ChildItem $('Cert:\localMachine') | Microsoft.PowerShell.Utility\Select-Object Name, @{name ="Path";expression= {$($_.Location.toString() + '\' + $_.Name)}}
$treeNodes += Get-ChildItem $('Cert:\currentuser') | Microsoft.PowerShell.Utility\Select-Object Name, @{name ="Path";expression= {$($_.Location.toString() + '\' + $_.Name)}}
$treeNodes


}
## [END] Get-CertificateTreeNodes ##
function Get-Certificates {
<#

.SYNOPSIS
Script that enumerates all the certificates in the system.

.DESCRIPTION
Script that enumerates all the certificates in the system.

.ROLE
Readers

#>

 param (
        [String]
        $path = "Cert:\",
        [int]
        $nearlyExpiredThresholdInDays = 60
    )

<#############################################################################################

    Helper functions.

#############################################################################################>

<#
.Synopsis
    Name: Get-ChildLeafRecurse
    Description: Recursively enumerates each scope and store in Cert:\ drive.

.Parameters
    $pspath: The initial pspath to use for creating whole path to certificate store.

.Returns
    The constructed ps-path object.
#>
function Get-ChildLeafRecurse
{
    param (
        [Parameter(Mandatory = $true)]
	    [String]
        $pspath
    )
    try
	{
    Get-ChildItem -Path $pspath -ErrorAction SilentlyContinue |Where-Object{!$_.PSIsContainer} | Write-Output
    Get-ChildItem -Path $pspath -ErrorAction SilentlyContinue |Where-Object{$_.PSIsContainer} | ForEach-Object{
            $location = "Cert:\$($_.location)";
            if ($_.psChildName -ne $_.location)
            {
                $location += "\$($_.PSChildName)";
            }
            Get-ChildLeafRecurse $location | ForEach-Object { Write-Output $_};
        }
	} catch {}
}

<#
.Synopsis
    Name: Compute-PublicKey
    Description: Computes public key algorithm and public key parameters

.Parameters
    $cert: The original certificate object.

.Returns
    A hashtable object of public key algorithm and public key parameters.
#>
function Compute-PublicKey
{
    param (
        [Parameter(Mandatory = $true)]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]
        $cert
    )

    $publicKeyInfo = @{}

    $publicKeyInfo["PublicKeyAlgorithm"] = ""
    $publicKeyInfo["PublicKeyParameters"] = ""

    if ($cert.PublicKey)
    {
        $publicKeyInfo["PublicKeyAlgorithm"] =  $cert.PublicKey.Oid.FriendlyName
        $publicKeyInfo["PublicKeyParameters"] = $cert.PublicKey.EncodedParameters.Format($true)
    }

    $publicKeyInfo
}

<#
.Synopsis
    Name: Compute-SignatureAlgorithm
    Description: Computes signature algorithm out of original certificate object.

.Parameters
    $cert: The original certificate object.

.Returns
    The signature algorithm friendly name.
#>
function Compute-SignatureAlgorithm
{
    param (
        [Parameter(Mandatory = $true)]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]
        $cert
    )

    $signatureAlgorithm = [System.String]::Empty

    if ($cert.SignatureAlgorithm)
    {
        $signatureAlgorithm = $cert.SignatureAlgorithm.FriendlyName;
    }

    $signatureAlgorithm
}

<#
.Synopsis
    Name: Compute-PrivateKeyStatus
    Description: Computes private key exportable status.
.Parameters
    $hasPrivateKey: A flag indicating certificate has a private key or not.
    $canExportPrivateKey: A flag indicating whether certificate can export a private key.

.Returns
    Enum values "Exported" or "NotExported"
#>
function Compute-PrivateKeyStatus
{
    param (
        [Parameter(Mandatory = $true)]
        [bool]
        $hasPrivateKey,

        [Parameter(Mandatory = $true)]
        [bool]
        $canExportPrivateKey
    )

    if (-not ($hasPrivateKey))
    {
        $privateKeystatus = "None"
    }
    else
    {
        if ($canExportPrivateKey)
        {
            $privateKeystatus = "Exportable"
        }
        else
        {
            $privateKeystatus = "NotExportable"
        }
    }

    $privateKeystatus
}

<#
.Synopsis
    Name: Compute-ExpirationStatus
    Description: Computes expiration status based on notAfter date.
.Parameters
    $notAfter: A date object refering to certificate expiry date.

.Returns
    Enum values "Expired", "NearlyExpired" and "Healthy"
#>
function Compute-ExpirationStatus
{
    param (
        [Parameter(Mandatory = $true)]
        [DateTime]$notAfter
    )

    if ([DateTime]::Now -gt $notAfter)
    {
       $expirationStatus = "Expired"
    }
    else
    {
       $nearlyExpired = [DateTime]::Now.AddDays($nearlyExpiredThresholdInDays);

       if ($nearlyExpired -ge $notAfter)
       {
          $expirationStatus = "NearlyExpired"
       }
       else
       {
          $expirationStatus = "Healthy"
       }
    }

    $expirationStatus
}

<#
.Synopsis
    Name: Compute-ArchivedStatus
    Description: Computes archived status of certificate.
.Parameters
    $archived: A flag to represent archived status.

.Returns
    Enum values "Archived" and "NotArchived"
#>
function Compute-ArchivedStatus
{
    param (
        [Parameter(Mandatory = $true)]
        [bool]
        $archived
    )

    if ($archived)
    {
        $archivedStatus = "Archived"
    }
    else
    {
        $archivedStatus = "NotArchived"
    }

    $archivedStatus
}

<#
.Synopsis
    Name: Compute-IssuedTo
    Description: Computes issued to field out of the certificate subject.
.Parameters
    $subject: Full subject string of the certificate.

.Returns
    Issued To authority name.
#>
function Compute-IssuedTo
{
    param (
        [String]
        $subject
    )

    $issuedTo = [String]::Empty

    $issuedToRegex = "CN=(?<issuedTo>[^,?]+)"
    $matched = $subject -match $issuedToRegex

    if ($matched -and $Matches)
    {
       $issuedTo = $Matches["issuedTo"]
    }

    $issuedTo
}

<#
.Synopsis
    Name: Compute-IssuerName
    Description: Computes issuer name of certificate.
.Parameters
    $cert: The original cert object.

.Returns
    The Issuer authority name.
#>
function Compute-IssuerName
{
    param (
        [Parameter(Mandatory = $true)]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]
        $cert
    )

    $issuerName = $cert.GetNameInfo([System.Security.Cryptography.X509Certificates.X509NameType]::SimpleName, $true)

    $issuerName
}

<#
.Synopsis
    Name: Compute-CertificateName
    Description: Computes certificate name of certificate.
.Parameters
    $cert: The original cert object.

.Returns
    The certificate name.
#>
function Compute-CertificateName
{
    param (
        [Parameter(Mandatory = $true)]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]
        $cert
    )

    $certificateName = $cert.GetNameInfo([System.Security.Cryptography.X509Certificates.X509NameType]::SimpleName, $false)
    if (!$certificateName) {
        $certificateName = $cert.GetNameInfo([System.Security.Cryptography.X509Certificates.X509NameType]::DnsName, $false)
    }

    $certificateName
}

<#
.Synopsis
    Name: Compute-Store
    Description: Computes certificate store name.
.Parameters
    $pspath: The full certificate ps path of the certificate.

.Returns
    The certificate store name.
#>
function Compute-Store
{
    param (
        [Parameter(Mandatory = $true)]
        [String]
        $pspath
    )

    $pspath.Split('\')[2]
}

<#
.Synopsis
    Name: Compute-Scope
    Description: Computes certificate scope/location name.
.Parameters
    $pspath: The full certificate ps path of the certificate.

.Returns
    The certificate scope/location name.
#>
function Compute-Scope
{
    param (
        [Parameter(Mandatory = $true)]
        [String]
        $pspath
    )

    $pspath.Split('\')[1].Split(':')[2]
}

<#
.Synopsis
    Name: Compute-Path
    Description: Computes certificate path. E.g. CurrentUser\My\<thumbprint>
.Parameters
    $pspath: The full certificate ps path of the certificate.

.Returns
    The certificate path.
#>
function Compute-Path
{
    param (
        [Parameter(Mandatory = $true)]
        [String]
        $pspath
    )

    $pspath.Split(':')[2]
}


<#
.Synopsis
    Name: EnhancedKeyUsage-List
    Description: Enhanced KeyUsage
.Parameters
    $cert: The original cert object.

.Returns
    Enhanced Key Usage.
#>
function EnhancedKeyUsage-List
{
    param (
        [Parameter(Mandatory = $true)]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]
        $cert
    )

    $usageString = ''
    foreach ( $usage in $cert.EnhancedKeyUsageList){
       $usageString = $usageString + $usage.FriendlyName + ' ' + $usage.ObjectId + "`n"
    }

    $usageString
}

<#
.Synopsis
    Name: Compute-Template
    Description: Compute template infomation of a certificate
    $certObject: The original certificate object.

.Returns
    The certificate template if there is one otherwise empty string
#>
function Compute-Template
{
    param (
        [Parameter(Mandatory = $true)]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]
        $cert
    )

    $template = $cert.Extensions | Where-Object {$_.Oid.FriendlyName -match "Template"}
    if ($template) {
        $name = $template.Format(1).split('(')[0]
        if ($name) {
            $name -replace "Template="
        }
        else {
            ''
        }
    }
    else {
        ''
    }
}

<#
.Synopsis
    Name: Extract-CertInfo
    Description: Extracts certificate info by decoding different field and create a custom object.
.Parameters
    $certObject: The original certificate object.

.Returns
    The custom object for certificate.
#>
function Extract-CertInfo
{
    param (
        [Parameter(Mandatory = $true)]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]
        $certObject
    )

    $certInfo = @{}

    $certInfo["Archived"] = $(Compute-ArchivedStatus $certObject.Archived)
    $certInfo["CertificateName"] = $(Compute-CertificateName $certObject)

    $certInfo["EnhancedKeyUsage"] = $(EnhancedKeyUsage-List $certObject) #new
    $certInfo["FriendlyName"] = $certObject.FriendlyName
    $certInfo["IssuerName"] = $(Compute-IssuerName $certObject)
    $certInfo["IssuedTo"] = $(Compute-IssuedTo $certObject.Subject)
    $certInfo["Issuer"] = $certObject.Issuer #new

    $certInfo["NotAfter"] = $certObject.NotAfter
    $certInfo["NotBefore"] = $certObject.NotBefore

    $certInfo["Path"] = $(Compute-Path  $certObject.PsPath)
    $certInfo["PrivateKey"] =  $(Compute-PrivateKeyStatus -hasPrivateKey $certObject.CalculatedHasPrivateKey -canExportPrivateKey  $certObject.CanExportPrivateKey)
    $publicKeyInfo = $(Compute-PublicKey $certObject)
    $certInfo["PublicKey"] = $publicKeyInfo.PublicKeyAlgorithm
    $certInfo["PublicKeyParameters"] = $publicKeyInfo.PublicKeyParameters

    $certInfo["Scope"] = $(Compute-Scope  $certObject.PsPath)
    $certInfo["Store"] = $(Compute-Store  $certObject.PsPath)
    $certInfo["SerialNumber"] = $certObject.SerialNumber
    $certInfo["Subject"] = $certObject.Subject
    $certInfo["Status"] =  $(Compute-ExpirationStatus $certObject.NotAfter)
    $certInfo["SignatureAlgorithm"] = $(Compute-SignatureAlgorithm $certObject)

    $certInfo["Thumbprint"] = $certObject.Thumbprint
    $certInfo["Version"] = $certObject.Version

    $certInfo["Template"] = $(Compute-Template $certObject)

    $certInfo
}


<#############################################################################################

    Main script.

#############################################################################################>


$certificates =  @()

Get-ChildLeafRecurse $path | ForEach-Object {
    $cert = $_
    $cert | Add-Member -Force -NotePropertyName "CalculatedHasPrivateKey" -NotePropertyValue $_.HasPrivateKey
    $exportable = $false

    if ($cert.HasPrivateKey)
    {
        [System.Security.Cryptography.CspParameters] $cspParams = new-object System.Security.Cryptography.CspParameters
        $contextField = $cert.GetType().GetField("m_safeCertContext", [Reflection.BindingFlags]::NonPublic -bor [Reflection.BindingFlags]::Instance)
        $privateKeyMethod = $cert.GetType().GetMethod("GetPrivateKeyInfo", [Reflection.BindingFlags]::NonPublic -bor [Reflection.BindingFlags]::Static)
        if ($contextField -and $privateKeyMethod) {
        $contextValue = $contextField.GetValue($cert)
        $privateKeyInfoAvailable = $privateKeyMethod.Invoke($cert, @($ContextValue, $cspParams))
        if ($privateKeyInfoAvailable)
        {
            $PrivateKeyCount++
            $csp = new-object System.Security.Cryptography.CspKeyContainerInfo -ArgumentList @($cspParams)
            if ($csp.Exportable)
            {
                $exportable = $true
            }
        }
        }
        else
        {
                $exportable = $true
        }
    }

    $cert | Add-Member -Force -NotePropertyName "CanExportPrivateKey" -NotePropertyValue $exportable

    $certificates += Extract-CertInfo $cert

    }

$certificates

}
## [END] Get-Certificates ##
function Get-TempFolder {
<#

.SYNOPSIS
Script that gets temp folder based on the target node.

.DESCRIPTION
Script that gets temp folder based on the target node.

.ROLE
Readers

#>

#Get-ChildItem env: | where {$_.name -contains "temp"}
Get-Childitem -Path Env:* | where-Object {$_.Name -eq "TEMP"}

}
## [END] Get-TempFolder ##
function Import-Certificate {
<#

.SYNOPSIS
Script that imports certificate.

.DESCRIPTION
Script that imports certificate.

.ROLE
Administrators

#>

param (
		[Parameter(Mandatory = $true)]
	    [String]
        $storePath,
        [Parameter(Mandatory = $true)]
	    [String]
        $filePath,
		[string]
        $exportable,
		[string]
		$password,
		[string]
		$invokeUserName,
		[string]
		$invokePassword
    )

# Notes: invokeUserName and invokePassword are not used on this version. Remained for future use.

$Script=@'
try {
	Import-Module PKI
	$params = @{ CertStoreLocation=$storePath; FilePath=$filePath }
    if ($password)
	{
		Add-Type -AssemblyName System.Security
		$encode = new-object System.Text.UTF8Encoding
		$encrypted = [System.Convert]::FromBase64String($password)
		$decrypted = [System.Security.Cryptography.ProtectedData]::Unprotect($encrypted, $null, [System.Security.Cryptography.DataProtectionScope]::LocalMachine)
		$password = $encode.GetString($decrypted)
        $pwd = ConvertTo-SecureString -String $password -Force -AsPlainText
		$params.Password = $pwd
    }

    if($exportable -eq "Export")
	{
		$params.Exportable = $true;
    }

    Import-PfxCertificate @params | ConvertTo-Json | Out-File $ResultFile
} catch {
    $_.Exception.Message | ConvertTo-Json | Out-File $ErrorFile
}
'@

if ([System.IO.Path]::GetExtension($filePath) -ne ".pfx") {
	Import-Module PKI
	Import-Certificate -CertStoreLocation $storePath -FilePath $filePath
	return;
}

# PFX private key handlings
if ($password) {
	# encrypt password with current user.
	Add-Type -AssemblyName System.Security
	$encode =  new-object System.Text.UTF8Encoding
	$bytes = $encode.GetBytes($password)
	$encrypt = [System.Security.Cryptography.ProtectedData]::Protect($bytes, $null, [System.Security.Cryptography.DataProtectionScope]::LocalMachine)
	$password = [System.Convert]::ToBase64String($encrypt)
}

# Pass parameters to script and generate script file in temp folder
$ResultFile = $env:temp + "\import-certificate_result.json"
$ErrorFile = $env:temp + "\import-certificate_error.json"
if (Test-Path $ErrorFile) {
    Remove-Item $ErrorFile
}

if (Test-Path $ResultFile) {
    Remove-Item $ResultFile
}

$Script = '$storePath=' + "'$storePath';" +
          '$filePath=' + "'$filePath';" +
          '$exportable=' + "'$exportable';" +
    	  '$password=' + "'$password';" +
		  '$ResultFile=' + "'$ResultFile';" +
		  '$ErrorFile=' + "'$ErrorFile';" +
          $Script
$ScriptFile = $env:temp + "\import-certificate.ps1"
$Script | Out-File $ScriptFile

# Create a scheduled task
$TaskName = "SMEImportCertificate"

$User = [Security.Principal.WindowsIdentity]::GetCurrent()
$Role = (New-Object Security.Principal.WindowsPrincipal $User).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
$arg = "-NoProfile -NoLogo -NonInteractive -ExecutionPolicy Bypass -File $ScriptFile"
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
		if ($i -ge 3)
		{
			Write-EventLog -LogName Application -Source "SME Import certificate" -EntryType Error -EventID 1 -Message "Can't connect to Schedule service"
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
if ($RootFolder.GetTasks(0) | Where-Object {$_.Name -eq $TaskName})
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

$Action = $Task.Actions.Create(0)
$Action.Path = "powershell"
$Action.Arguments = $arg

#Tasks will be run with the highest privileges
$Task.Principal.RunLevel = 1

#### example Start the task with user specified invoke username and password
####$Task.Principal.LogonType = 1
####$RootFolder.RegisterTaskDefinition($TaskName, $Task, 6, $invokeUserName, $invokePassword, 1) | Out-Null

#### Start the task with SYSTEM creds
$RootFolder.RegisterTaskDefinition($TaskName, $Task, 6, "SYSTEM", $Null, 1) | Out-Null

#Wait for running task finished
$RootFolder.GetTask($TaskName).Run(0) | Out-Null
while ($Scheduler.GetRunningTasks(0) | Where-Object {$_.Name -eq $TaskName})
{
	Start-Sleep -s 2
}

#Clean up
$RootFolder.DeleteTask($TaskName,0)
Remove-Item $ScriptFile
#Return result
if (Test-Path $ErrorFile) {
	$result = Get-Content -Raw -Path $ErrorFile | ConvertFrom-Json
    Remove-Item $ErrorFile
    Remove-Item $ResultFile
	throw $result
}

if (Test-Path $ResultFile)
{
    $result = Get-Content -Raw -Path $ResultFile | ConvertFrom-Json
    Remove-Item $ResultFile
    return $result
}

}
## [END] Import-Certificate ##
function Remove-Certificate {
 <#

.SYNOPSIS
Script that deletes certificate.

.DESCRIPTION
Script that deletes certificate.

.ROLE
Administrators

#>

 param (
    [Parameter(Mandatory = $true)]
    [string]
    $thumbprintPath
    )

Get-ChildItem $thumbprintPath | Remove-Item


}
## [END] Remove-Certificate ##
function Remove-ItemByPath {
<#

.SYNOPSIS
Script that deletes certificate based on the path.

.DESCRIPTION
Script that deletes certificate based on the path.

.ROLE
Administrators

#>

 Param([string]$path)

 Remove-Item -Path $path;

}
## [END] Remove-ItemByPath ##
function Update-Certificate {
<#

.SYNOPSIS
Renew Certificate

.DESCRIPTION
Renew Certificate

.ROLE
Administrators

#>

param (
    [Parameter(Mandatory = $true)]
    [String]
    $username,
    [Parameter(Mandatory = $true)]
    [String]
    $password,
    [Parameter(Mandatory = $true)]
    [Boolean]
    $sameKey,
    [Parameter(Mandatory = $true)]
    [Boolean]
    $isRenew,
    [Parameter(Mandatory = $true)]
    [String]
    $Path,
    [Parameter(Mandatory = $true)]
    [String]
    $RemoteComputer
    )

$pw = ConvertTo-SecureString $password -AsPlainText -Force
$credential = New-Object PSCredential($username, $pw)

Invoke-Command -Computername $RemoteComputer -ScriptBlock {
    param($Path, $isRenew, $sameKey)
    $global:result = ""

    $Cert = Get-Item -Path $Path

    $Template = $Cert.Extensions | Where-Object {$_.Oid.FriendlyName -match "Template"}
    if (!$Template) {
        $global:result = "NoTemplate"
        $global:result
        exit
    }

    #https://msdn.microsoft.com/en-us/library/windows/desktop/aa379399(v=vs.85).aspx
    #X509CertificateEnrollmentContext
    $ContextUser                      = 0x1
    $ContextMachine                   = 0x2
    $ContextAdministratorForceMachine = 0x3

    #https://msdn.microsoft.com/en-us/library/windows/desktop/aa374936(v=vs.85).aspx
    #EncodingType
    $XCN_CRYPT_STRING_BASE64HEADER        = 0
    $XCN_CRYPT_STRING_BASE64              = 0x1
    $XCN_CRYPT_STRING_BINARY              = 0x2
    $XCN_CRYPT_STRING_BASE64REQUESTHEADER = 0x3
    $XCN_CRYPT_STRING_HEX                 = 0x4
    $XCN_CRYPT_STRING_HEXASCII            = 0x5
    $XCN_CRYPT_STRING_BASE64_ANY          = 0x6
    $XCN_CRYPT_STRING_ANY                 = 0x7
    $XCN_CRYPT_STRING_HEX_ANY             = 0x8
    $XCN_CRYPT_STRING_BASE64X509CRLHEADER = 0x9
    $XCN_CRYPT_STRING_HEXADDR             = 0xa
    $XCN_CRYPT_STRING_HEXASCIIADDR        = 0xb
    $XCN_CRYPT_STRING_HEXRAW              = 0xc
    $XCN_CRYPT_STRING_NOCRLF              = 0x40000000
    $XCN_CRYPT_STRING_NOCR                = 0x80000000

    #https://msdn.microsoft.com/en-us/library/windows/desktop/aa379430(v=vs.85).aspx
    #X509RequestInheritOptions
    $InheritDefault                = 0x00000000
    $InheritNewDefaultKey          = 0x00000001
    $InheritNewSimilarKey          = 0x00000002
    $InheritPrivateKey             = 0x00000003
    $InheritPublicKey              = 0x00000004
    $InheritKeyMask                = 0x0000000f
    $InheritNone                   = 0x00000010
    $InheritRenewalCertificateFlag = 0x00000020
    $InheritTemplateFlag           = 0x00000040
    $InheritSubjectFlag            = 0x00000080
    $InheritExtensionsFlag         = 0x00000100
    $InheritSubjectAltNameFlag     = 0x00000200
    $InheritValidityPeriodFlag     = 0x00000400
    $X509RequestInheritOptions = $InheritTemplateFlag
    if ($isRenew) {
        $X509RequestInheritOptions += $InheritRenewalCertificateFlag
    }
    if ($sameKey) {
        $X509RequestInheritOptions += $InheritPrivateKey
    }

    $Context = $ContextAdministratorForceMachine

    $PKCS10 = New-Object -ComObject X509Enrollment.CX509CertificateRequestPkcs10
    $PKCS10.Silent=$true

    $PKCS10.InitializeFromCertificate($Context,[System.Convert]::ToBase64String($Cert.RawData), $XCN_CRYPT_STRING_BASE64, $X509RequestInheritOptions)
    $PKCS10.AlternateSignatureAlgorithm=$false
    $PKCS10.SmimeCapabilities=$false
    $PKCS10.SuppressDefaults=$true
    $PKCS10.Encode()
    #https://msdn.microsoft.com/en-us/library/windows/desktop/aa377809(v=vs.85).aspx
    $Enroll = New-Object -ComObject X509Enrollment.CX509Enrollment
    $Enroll.InitializeFromRequest($PKCS10)
    $Enroll.Enroll()

    if ($Error.Count -eq 0) {
        $Cert = New-Object Security.Cryptography.X509Certificates.X509Certificate2
        $Cert.Import([System.Convert]::FromBase64String($Enroll.Certificate(1)))
        $global:result = $Cert.Thumbprint
    }

    $global:result

} -Credential $credential -ArgumentList $Path, $isRenew, $sameKey

}
## [END] Update-Certificate ##
function Clear-EventLogChannel {
<#

.SYNOPSIS
Clear the event log channel specified.

.DESCRIPTION
Clear the event log channel specified.
The supported Operating Systems are Window Server 2012, Windows Server 2012R2, Windows Server 2016.

.ROLE
Administrators

#>
 
Param(
    [string]$channel
)

[System.Diagnostics.Eventing.Reader.EventLogSession]::GlobalSession.ClearLog("$channel") 
}
## [END] Clear-EventLogChannel ##
function Clear-EventLogChannelAfterExport {
<#

.SYNOPSIS
Clear the event log channel after export the event log channel file (.evtx).

.DESCRIPTION
Clear the event log channel after export the event log channel file (.evtx).
The supported Operating Systems are Window Server 2012, Windows Server 2012R2, Windows Server 2016.

.ROLE
Administrators

#>

Param(
    [string]$channel
)

$segments = $channel.Split("-")
$name = $segments[-1]

$randomString = [GUID]::NewGuid().ToString()
$ResultFile = $env:temp + "\" + $name + "_" + $randomString + ".evtx"
$ResultFile = $ResultFile -replace "/", "-"

wevtutil epl "$channel" "$ResultFile" /ow:true

[System.Diagnostics.Eventing.Reader.EventLogSession]::GlobalSession.ClearLog("$channel") 

return $ResultFile

}
## [END] Clear-EventLogChannelAfterExport ##
function Export-EventLogChannel {
<#

.SYNOPSIS
Export the event log channel file (.evtx) with filter XML.

.DESCRIPTION
Export the event log channel file (.evtx) with filter XML.
The supported Operating Systems are Window Server 2012, Windows Server 2012R2, Windows Server 2016.

.ROLE
Administrators

#>

Param(
    [string]$channel,
    [string]$filterXml
)

$segments = $channel.Split("-")
$name = $segments[-1]

$randomString = [GUID]::NewGuid().ToString()
$ResultFile = $env:temp + "\" + $name + "_" + $randomString + ".evtx"
$ResultFile = $ResultFile -replace "/", "-"

wevtutil epl "$channel" "$ResultFile" /q:"$filterXml" /ow:true

return $ResultFile

}
## [END] Export-EventLogChannel ##
function Get-CimEventLogRecords {
<#

.SYNOPSIS
Get Log records of event channel by using Server Manager CIM provider.

.DESCRIPTION
Get Log records of event channel by using Server Manager CIM provider.

.ROLE
Readers

#>

Param(
    [string]$FilterXml,
    [bool]$ReverseDirection
)

import-module CimCmdlets

$machineName = [System.Net.DNS]::GetHostByName('').HostName
Invoke-CimMethod -Namespace root/Microsoft/Windows/ServerManager -ClassName MSFT_ServerManagerTasks -MethodName GetServerEventDetailEx -Arguments @{FilterXml = $FilterXml; ReverseDirection = $ReverseDirection; } |
    ForEach-Object {
        $result = $_
        if ($result.PSObject.Properties.Match('ItemValue').Count) {
            foreach ($item in $result.ItemValue) {
                @{
                    ItemValue = 
                    @{
                        Description  = $item.description
                        Id           = $item.id
                        Level        = $item.level
                        Log          = $item.log
                        Source       = $item.source
                        Timestamp    = $item.timestamp
                        __ServerName = $machineName
                    }
                }
            }
        }
    }

}
## [END] Get-CimEventLogRecords ##
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
function Get-EventLogDisplayName {
<#

.SYNOPSIS
Get the EventLog log name and display name by using Get-EventLog cmdlet.

.DESCRIPTION
Get the EventLog log name and display name by using Get-EventLog cmdlet.
The supported Operating Systems are Window Server 2012, Windows Server 2012R2, Windows Server 2016.

.ROLE
Readers

#>


return (Get-EventLog -LogName * | Microsoft.PowerShell.Utility\Select-Object Log,LogDisplayName)
}
## [END] Get-EventLogDisplayName ##
function Get-EventLogFilteredCount {
<#

.SYNOPSIS
Get the total amout of events that meet the filters selected by using Get-WinEvent cmdlet.

.DESCRIPTION
Get the total amout of events that meet the filters selected by using Get-WinEvent cmdlet.
The supported Operating Systems are Window Server 2012, Windows Server 2012R2, Windows Server 2016.

.ROLE
Readers

#>

Param(
    [string]$filterXml
)

return (Get-WinEvent -FilterXml "$filterXml" -ErrorAction 'SilentlyContinue').count
}
## [END] Get-EventLogFilteredCount ##
function Get-EventLogRecords {
<#

.SYNOPSIS
Get Log records of event channel by using Get-WinEvent cmdlet.

.DESCRIPTION
Get Log records of event channel by using Get-WinEvent cmdlet.
The supported Operating Systems are Window Server 2012, Windows Server 2012R2, Windows Server 2016.

.ROLE
Readers
#>

Param(
    [string]
    $filterXml,
    [bool]
    $reverseDirection
)

$ErrorActionPreference = 'SilentlyContinue'
Import-Module Microsoft.PowerShell.Diagnostics;

#
# Prepare parameters for command Get-WinEvent
#
$winEventscmdParams = @{
    FilterXml = $filterXml;
    Oldest    = !$reverseDirection;
}

Get-WinEvent  @winEventscmdParams -ErrorAction SilentlyContinue | Microsoft.PowerShell.Utility\Select-Object recordId,
id, 
@{Name = "Log"; Expression = {$_."logname"}}, 
level, 
timeCreated, 
machineName, 
@{Name = "Source"; Expression = {$_."ProviderName"}}, 
@{Name = "Description"; Expression = {$_."Message"}}



}
## [END] Get-EventLogRecords ##
function Get-EventLogSummary {
<#

.SYNOPSIS
Get the log summary (Name, Total) for the channel selected by using Get-WinEvent cmdlet.

.DESCRIPTION
Get the log summary (Name, Total) for the channel selected by using Get-WinEvent cmdlet.
The supported Operating Systems are Window Server 2012, Windows Server 2012R2, Windows Server 2016.

.ROLE
Readers

#>

Param(
    [string]$channel
)

$ErrorActionPreference = 'SilentlyContinue'

Import-Module Microsoft.PowerShell.Diagnostics;

$channelList = $channel.split(",")

Get-WinEvent -ListLog $channelList -Force -ErrorAction SilentlyContinue
}
## [END] Get-EventLogSummary ##
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
function Set-EventLogChannelStatus {
 <#

.SYNOPSIS
 Change the current status (Enabled/Disabled) for the selected channel.

.DESCRIPTION
Change the current status (Enabled/Disabled) for the selected channel.
The supported Operating Systems are Window Server 2012, Windows Server 2012R2, Windows Server 2016.

.ROLE
Administrators

#>

Param(
    [string]$channel,
    [boolean]$status
)

$ch = Get-WinEvent -ListLog $channel
$ch.set_IsEnabled($status)
$ch.SaveChanges()
}
## [END] Set-EventLogChannelStatus ##

# SIG # Begin signature block
# MIIdkgYJKoZIhvcNAQcCoIIdgzCCHX8CAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU9MevQ8rocBSHgbS0DLQmG31Q
# cfGgghhuMIIE3jCCA8agAwIBAgITMwAAAPlcySJVCsCdxAAAAAAA+TANBgkqhkiG
# 9w0BAQUFADB3MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4G
# A1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSEw
# HwYDVQQDExhNaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EwHhcNMTgwODIzMjAyMDA4
# WhcNMTkxMTIzMjAyMDA4WjCBzjELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hp
# bmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jw
# b3JhdGlvbjEpMCcGA1UECxMgTWljcm9zb2Z0IE9wZXJhdGlvbnMgUHVlcnRvIFJp
# Y28xJjAkBgNVBAsTHVRoYWxlcyBUU1MgRVNOOkY1MjgtMzc3Ny04QTc2MSUwIwYD
# VQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBTZXJ2aWNlMIIBIjANBgkqhkiG9w0B
# AQEFAAOCAQ8AMIIBCgKCAQEAwULSKQlDF0CYatQWPKeKZqcjcZVbshFm9cjpDlxv
# dRVOW42mvy76VaDOwYSBUzA7dTUTOs25JEW666UKMhFuqpR/2eUpf5XMSjSQyWz7
# jZ3dJHaw3m08IGh4FXYPSuAitvfMjLdhddcVI83u48wRG6crTY8cgAskysICfAen
# 3+grOkMKMEsYLbXKXl5vUfhLe7+3avzx3XBB1kPq9kwtwRw+RP5jZwL7NZJoyQAt
# ODdcPbmyKHXY+3qNT/l15UwOarP3/c+J/SAquNG0B7FkCplSjNAr2iitt5uU8BC5
# CJmOzUyBmomx0mTcoWkeGVcMvKFr6XQpEbZWfZuPGjv3WQIDAQABo4IBCTCCAQUw
# HQYDVR0OBBYEFIZYuuf0tcnN3wz72zkJtIH73FkbMB8GA1UdIwQYMBaAFCM0+NlS
# RnAK7UD7dvuzK7DDNbMPMFQGA1UdHwRNMEswSaBHoEWGQ2h0dHA6Ly9jcmwubWlj
# cm9zb2Z0LmNvbS9wa2kvY3JsL3Byb2R1Y3RzL01pY3Jvc29mdFRpbWVTdGFtcFBD
# QS5jcmwwWAYIKwYBBQUHAQEETDBKMEgGCCsGAQUFBzAChjxodHRwOi8vd3d3Lm1p
# Y3Jvc29mdC5jb20vcGtpL2NlcnRzL01pY3Jvc29mdFRpbWVTdGFtcFBDQS5jcnQw
# EwYDVR0lBAwwCgYIKwYBBQUHAwgwDQYJKoZIhvcNAQEFBQADggEBAFi+F7H2+9P4
# 0mjUwdOdtedhtTWgoZSiqbozdw7XUePTslaMTHs/w9cmmZax5Oyu7Hiwj/z6clC4
# GPLTdbY0GLkRYY8DkEtvw4So49C6FCGNFklFWrzsI2Juw4VFl9j4OwSGGgTXlfkw
# Cn5RV4wbF5gWNdC/ZlbvbSp1CS1zkCovBSK1lWfhSDVgnSAi+nfm+XFeAf0eg6h4
# BcufBqMkZkiXNnTuhHm77EBa9Q1EaijALUrtzYdnhttbZ0jRe8k0AQnDAxfpJChE
# IAc8oXeas2HSuVmWCPzFYPdxvjlHdLBiBctiUa6AimWCogZ7XVdx3LaRQNJ46ptk
# Pf6cZv3THCwwggX/MIID56ADAgECAhMzAAABA14lHJkfox64AAAAAAEDMA0GCSqG
# SIb3DQEBCwUAMH4xCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAw
# DgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24x
# KDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNpZ25pbmcgUENBIDIwMTEwHhcNMTgw
# NzEyMjAwODQ4WhcNMTkwNzI2MjAwODQ4WjB0MQswCQYDVQQGEwJVUzETMBEGA1UE
# CBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9z
# b2Z0IENvcnBvcmF0aW9uMR4wHAYDVQQDExVNaWNyb3NvZnQgQ29ycG9yYXRpb24w
# ggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDRlHY25oarNv5p+UZ8i4hQ
# y5Bwf7BVqSQdfjnnBZ8PrHuXss5zCvvUmyRcFrU53Rt+M2wR/Dsm85iqXVNrqsPs
# E7jS789Xf8xly69NLjKxVitONAeJ/mkhvT5E+94SnYW/fHaGfXKxdpth5opkTEbO
# ttU6jHeTd2chnLZaBl5HhvU80QnKDT3NsumhUHjRhIjiATwi/K+WCMxdmcDt66Va
# mJL1yEBOanOv3uN0etNfRpe84mcod5mswQ4xFo8ADwH+S15UD8rEZT8K46NG2/Ys
# AzoZvmgFFpzmfzS/p4eNZTkmyWPU78XdvSX+/Sj0NIZ5rCrVXzCRO+QUauuxygQj
# AgMBAAGjggF+MIIBejAfBgNVHSUEGDAWBgorBgEEAYI3TAgBBggrBgEFBQcDAzAd
# BgNVHQ4EFgQUR77Ay+GmP/1l1jjyA123r3f3QP8wUAYDVR0RBEkwR6RFMEMxKTAn
# BgNVBAsTIE1pY3Jvc29mdCBPcGVyYXRpb25zIFB1ZXJ0byBSaWNvMRYwFAYDVQQF
# Ew0yMzAwMTIrNDM3OTY1MB8GA1UdIwQYMBaAFEhuZOVQBdOCqhc3NyK1bajKdQKV
# MFQGA1UdHwRNMEswSaBHoEWGQ2h0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lv
# cHMvY3JsL01pY0NvZFNpZ1BDQTIwMTFfMjAxMS0wNy0wOC5jcmwwYQYIKwYBBQUH
# AQEEVTBTMFEGCCsGAQUFBzAChkVodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtp
# b3BzL2NlcnRzL01pY0NvZFNpZ1BDQTIwMTFfMjAxMS0wNy0wOC5jcnQwDAYDVR0T
# AQH/BAIwADANBgkqhkiG9w0BAQsFAAOCAgEAn/XJUw0/DSbsokTYDdGfY5YGSz8e
# XMUzo6TDbK8fwAG662XsnjMQD6esW9S9kGEX5zHnwya0rPUn00iThoj+EjWRZCLR
# ay07qCwVlCnSN5bmNf8MzsgGFhaeJLHiOfluDnjYDBu2KWAndjQkm925l3XLATut
# ghIWIoCJFYS7mFAgsBcmhkmvzn1FFUM0ls+BXBgs1JPyZ6vic8g9o838Mh5gHOmw
# GzD7LLsHLpaEk0UoVFzNlv2g24HYtjDKQ7HzSMCyRhxdXnYqWJ/U7vL0+khMtWGL
# sIxB6aq4nZD0/2pCD7k+6Q7slPyNgLt44yOneFuybR/5WcF9ttE5yXnggxxgCto9
# sNHtNr9FB+kbNm7lPTsFA6fUpyUSj+Z2oxOzRVpDMYLa2ISuubAfdfX2HX1RETcn
# 6LU1hHH3V6qu+olxyZjSnlpkdr6Mw30VapHxFPTy2TUxuNty+rR1yIibar+YRcdm
# stf/zpKQdeTr5obSyBvbJ8BblW9Jb1hdaSreU0v46Mp79mwV+QMZDxGFqk+av6pX
# 3WDG9XEg9FGomsrp0es0Rz11+iLsVT9qGTlrEOlaP470I3gwsvKmOMs1jaqYWSRA
# uDpnpAdfoP7YO0kT+wzh7Qttg1DO8H8+4NkI6IwhSkHC3uuOW+4Dwx1ubuZUNWZn
# cnwa6lL2IsRyP64wggYHMIID76ADAgECAgphFmg0AAAAAAAcMA0GCSqGSIb3DQEB
# BQUAMF8xEzARBgoJkiaJk/IsZAEZFgNjb20xGTAXBgoJkiaJk/IsZAEZFgltaWNy
# b3NvZnQxLTArBgNVBAMTJE1pY3Jvc29mdCBSb290IENlcnRpZmljYXRlIEF1dGhv
# cml0eTAeFw0wNzA0MDMxMjUzMDlaFw0yMTA0MDMxMzAzMDlaMHcxCzAJBgNVBAYT
# AlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYD
# VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xITAfBgNVBAMTGE1pY3Jvc29mdCBU
# aW1lLVN0YW1wIFBDQTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAJ+h
# bLHf20iSKnxrLhnhveLjxZlRI1Ctzt0YTiQP7tGn0UytdDAgEesH1VSVFUmUG0KS
# rphcMCbaAGvoe73siQcP9w4EmPCJzB/LMySHnfL0Zxws/HvniB3q506jocEjU8qN
# +kXPCdBer9CwQgSi+aZsk2fXKNxGU7CG0OUoRi4nrIZPVVIM5AMs+2qQkDBuh/NZ
# MJ36ftaXs+ghl3740hPzCLdTbVK0RZCfSABKR2YRJylmqJfk0waBSqL5hKcRRxQJ
# gp+E7VV4/gGaHVAIhQAQMEbtt94jRrvELVSfrx54QTF3zJvfO4OToWECtR0Nsfz3
# m7IBziJLVP/5BcPCIAsCAwEAAaOCAaswggGnMA8GA1UdEwEB/wQFMAMBAf8wHQYD
# VR0OBBYEFCM0+NlSRnAK7UD7dvuzK7DDNbMPMAsGA1UdDwQEAwIBhjAQBgkrBgEE
# AYI3FQEEAwIBADCBmAYDVR0jBIGQMIGNgBQOrIJgQFYnl+UlE/wq4QpTlVnkpKFj
# pGEwXzETMBEGCgmSJomT8ixkARkWA2NvbTEZMBcGCgmSJomT8ixkARkWCW1pY3Jv
# c29mdDEtMCsGA1UEAxMkTWljcm9zb2Z0IFJvb3QgQ2VydGlmaWNhdGUgQXV0aG9y
# aXR5ghB5rRahSqClrUxzWPQHEy5lMFAGA1UdHwRJMEcwRaBDoEGGP2h0dHA6Ly9j
# cmwubWljcm9zb2Z0LmNvbS9wa2kvY3JsL3Byb2R1Y3RzL21pY3Jvc29mdHJvb3Rj
# ZXJ0LmNybDBUBggrBgEFBQcBAQRIMEYwRAYIKwYBBQUHMAKGOGh0dHA6Ly93d3cu
# bWljcm9zb2Z0LmNvbS9wa2kvY2VydHMvTWljcm9zb2Z0Um9vdENlcnQuY3J0MBMG
# A1UdJQQMMAoGCCsGAQUFBwMIMA0GCSqGSIb3DQEBBQUAA4ICAQAQl4rDXANENt3p
# tK132855UU0BsS50cVttDBOrzr57j7gu1BKijG1iuFcCy04gE1CZ3XpA4le7r1ia
# HOEdAYasu3jyi9DsOwHu4r6PCgXIjUji8FMV3U+rkuTnjWrVgMHmlPIGL4UD6ZEq
# JCJw+/b85HiZLg33B+JwvBhOnY5rCnKVuKE5nGctxVEO6mJcPxaYiyA/4gcaMvnM
# MUp2MT0rcgvI6nA9/4UKE9/CCmGO8Ne4F+tOi3/FNSteo7/rvH0LQnvUU3Ih7jDK
# u3hlXFsBFwoUDtLaFJj1PLlmWLMtL+f5hYbMUVbonXCUbKw5TNT2eb+qGHpiKe+i
# myk0BncaYsk9Hm0fgvALxyy7z0Oz5fnsfbXjpKh0NbhOxXEjEiZ2CzxSjHFaRkMU
# vLOzsE1nyJ9C/4B5IYCeFTBm6EISXhrIniIh0EPpK+m79EjMLNTYMoBMJipIJF9a
# 6lbvpt6Znco6b72BJ3QGEe52Ib+bgsEnVLaxaj2JoXZhtG6hE6a/qkfwEm/9ijJs
# sv7fUciMI8lmvZ0dhxJkAj0tr1mPuOQh5bWwymO0eFQF1EEuUKyUsKV4q7OglnUa
# 2ZKHE3UiLzKoCG6gW4wlv6DvhMoh1useT8ma7kng9wFlb4kLfchpyOZu6qeXzjEp
# /w7FW1zYTRuh2Povnj8uVRZryROj/TCCB3owggVioAMCAQICCmEOkNIAAAAAAAMw
# DQYJKoZIhvcNAQELBQAwgYgxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5n
# dG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9y
# YXRpb24xMjAwBgNVBAMTKU1pY3Jvc29mdCBSb290IENlcnRpZmljYXRlIEF1dGhv
# cml0eSAyMDExMB4XDTExMDcwODIwNTkwOVoXDTI2MDcwODIxMDkwOVowfjELMAkG
# A1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQx
# HjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEoMCYGA1UEAxMfTWljcm9z
# b2Z0IENvZGUgU2lnbmluZyBQQ0EgMjAxMTCCAiIwDQYJKoZIhvcNAQEBBQADggIP
# ADCCAgoCggIBAKvw+nIQHC6t2G6qghBNNLrytlghn0IbKmvpWlCquAY4GgRJun/D
# DB7dN2vGEtgL8DjCmQawyDnVARQxQtOJDXlkh36UYCRsr55JnOloXtLfm1OyCizD
# r9mpK656Ca/XllnKYBoF6WZ26DJSJhIv56sIUM+zRLdd2MQuA3WraPPLbfM6XKEW
# 9Ea64DhkrG5kNXimoGMPLdNAk/jj3gcN1Vx5pUkp5w2+oBN3vpQ97/vjK1oQH01W
# KKJ6cuASOrdJXtjt7UORg9l7snuGG9k+sYxd6IlPhBryoS9Z5JA7La4zWMW3Pv4y
# 07MDPbGyr5I4ftKdgCz1TlaRITUlwzluZH9TupwPrRkjhMv0ugOGjfdf8NBSv4yU
# h7zAIXQlXxgotswnKDglmDlKNs98sZKuHCOnqWbsYR9q4ShJnV+I4iVd0yFLPlLE
# tVc/JAPw0XpbL9Uj43BdD1FGd7P4AOG8rAKCX9vAFbO9G9RVS+c5oQ/pI0m8GLhE
# fEXkwcNyeuBy5yTfv0aZxe/CHFfbg43sTUkwp6uO3+xbn6/83bBm4sGXgXvt1u1L
# 50kppxMopqd9Z4DmimJ4X7IvhNdXnFy/dygo8e1twyiPLI9AN0/B4YVEicQJTMXU
# pUMvdJX3bvh4IFgsE11glZo+TzOE2rCIF96eTvSWsLxGoGyY0uDWiIwLAgMBAAGj
# ggHtMIIB6TAQBgkrBgEEAYI3FQEEAwIBADAdBgNVHQ4EFgQUSG5k5VAF04KqFzc3
# IrVtqMp1ApUwGQYJKwYBBAGCNxQCBAweCgBTAHUAYgBDAEEwCwYDVR0PBAQDAgGG
# MA8GA1UdEwEB/wQFMAMBAf8wHwYDVR0jBBgwFoAUci06AjGQQ7kUBU7h6qfHMdEj
# iTQwWgYDVR0fBFMwUTBPoE2gS4ZJaHR0cDovL2NybC5taWNyb3NvZnQuY29tL3Br
# aS9jcmwvcHJvZHVjdHMvTWljUm9vQ2VyQXV0MjAxMV8yMDExXzAzXzIyLmNybDBe
# BggrBgEFBQcBAQRSMFAwTgYIKwYBBQUHMAKGQmh0dHA6Ly93d3cubWljcm9zb2Z0
# LmNvbS9wa2kvY2VydHMvTWljUm9vQ2VyQXV0MjAxMV8yMDExXzAzXzIyLmNydDCB
# nwYDVR0gBIGXMIGUMIGRBgkrBgEEAYI3LgMwgYMwPwYIKwYBBQUHAgEWM2h0dHA6
# Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvZG9jcy9wcmltYXJ5Y3BzLmh0bTBA
# BggrBgEFBQcCAjA0HjIgHQBMAGUAZwBhAGwAXwBwAG8AbABpAGMAeQBfAHMAdABh
# AHQAZQBtAGUAbgB0AC4gHTANBgkqhkiG9w0BAQsFAAOCAgEAZ/KGpZjgVHkaLtPY
# dGcimwuWEeFjkplCln3SeQyQwWVfLiw++MNy0W2D/r4/6ArKO79HqaPzadtjvyI1
# pZddZYSQfYtGUFXYDJJ80hpLHPM8QotS0LD9a+M+By4pm+Y9G6XUtR13lDni6WTJ
# RD14eiPzE32mkHSDjfTLJgJGKsKKELukqQUMm+1o+mgulaAqPyprWEljHwlpblqY
# luSD9MCP80Yr3vw70L01724lruWvJ+3Q3fMOr5kol5hNDj0L8giJ1h/DMhji8MUt
# zluetEk5CsYKwsatruWy2dsViFFFWDgycScaf7H0J/jeLDogaZiyWYlobm+nt3TD
# QAUGpgEqKD6CPxNNZgvAs0314Y9/HG8VfUWnduVAKmWjw11SYobDHWM2l4bf2vP4
# 8hahmifhzaWX0O5dY0HjWwechz4GdwbRBrF1HxS+YWG18NzGGwS+30HHDiju3mUv
# 7Jf2oVyW2ADWoUa9WfOXpQlLSBCZgB/QACnFsZulP0V3HjXG0qKin3p6IvpIlR+r
# +0cjgPWe+L9rt0uX4ut1eBrs6jeZeRhL/9azI2h15q/6/IvrC4DqaTuv/DDtBEyO
# 3991bWORPdGdVk5Pv4BXIqF4ETIheu9BCrE/+6jMpF3BoYibV3FWTkhFwELJm3Zb
# CoBIa/15n8G9bW1qyVJzEw16UM0xggSOMIIEigIBATCBlTB+MQswCQYDVQQGEwJV
# UzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UE
# ChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSgwJgYDVQQDEx9NaWNyb3NvZnQgQ29k
# ZSBTaWduaW5nIFBDQSAyMDExAhMzAAABA14lHJkfox64AAAAAAEDMAkGBSsOAwIa
# BQCggaIwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEO
# MAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFCGEijKyfB3wLbgmyIGaLkhT
# 8yvDMEIGCisGAQQBgjcCAQwxNDAyoBSAEgBNAGkAYwByAG8AcwBvAGYAdKEagBho
# dHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20wDQYJKoZIhvcNAQEBBQAEggEAcJy+Cnpf
# GY9qOWFIulrmSgoWjaA0rf2rZQzcy5HrI7v19/M3E0QQ23edybSpGP/I8mEbv22t
# dYz2oWA/NndWZjLcwj3LMIcQ83NJuue3jCUVrkJagiGNxg5e1Eki5NmeqKvCWOcC
# /+xw02pePGTnjd7hFkNxvGFXArX+ldce0r/SOiQ1bEXUF+P5U7WnEtw08IXrox1w
# Sn3Xx+sl+fUQf83O7D9rgwdc3XmHf3b8ooNFFqzniASS3+bg/MEi1qWDt+AKtV+B
# HAvn1kzjW0nLcO7JgucEyrRRNv/L6Jp3fddVH94P6SoBrw5gBdvyfoM4HOzc805u
# 8FhTZzx7T4d2+6GCAigwggIkBgkqhkiG9w0BCQYxggIVMIICEQIBATCBjjB3MQsw
# CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
# ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSEwHwYDVQQDExhNaWNy
# b3NvZnQgVGltZS1TdGFtcCBQQ0ECEzMAAAD5XMkiVQrAncQAAAAAAPkwCQYFKw4D
# AhoFAKBdMBgGCSqGSIb3DQEJAzELBgkqhkiG9w0BBwEwHAYJKoZIhvcNAQkFMQ8X
# DTE5MDQwMjIwMjE1MVowIwYJKoZIhvcNAQkEMRYEFO2rljfHyY5MmjmwbU3RMDU8
# tOmWMA0GCSqGSIb3DQEBBQUABIIBAGXz+m6QXVetOcnPd5p7uC8DNfwREHKZHJJA
# OkI1JR0EDBBOjjvN4MCvG6qCseWoBpw1D8Ky3DePJfoHs4Haq7eGPsM0gGV1N4kl
# uSskTZQsPBqslc+fjp4h8f8yN6i48XVh0jVN6JpQzdSJnXAWbwCmrcOpL/HiNOHj
# o1v1dP+qwAJeV3Q/cAxIKVwaBhTNISd/CrylFvmKd4+ONyqcEv1n9mf4CqNNu+wx
# NOkCmIxn3WbH7KFIIdd88RdF7dcDpTD1R2OloJWtuPHhyhwt+6p9xu+dQOAMiWq7
# bnegTbYS0VVol/XkDJy0gAgDtKzlkZXHJQMuUI9A3v1W5GCrApU=
# SIG # End signature block
