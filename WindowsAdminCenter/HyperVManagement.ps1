function Get-AntimalwareSoftwareStatus {
<#

.SYNOPSIS
Gets the status of antimalware software on the computer.

.DESCRIPTION
Gets the status of antimalware software on the computer.

.ROLE
Readers

#>

if (Get-Command Get-MpComputerStatus -ErrorAction SilentlyContinue)
{
    return (Get-MpComputerStatus -ErrorAction SilentlyContinue);
}
else{
    return $Null;
}


}
## [END] Get-AntimalwareSoftwareStatus ##
function Get-AzureProtectionStatus {
<#

.SYNOPSIS
Gets the status of Azure Backup on the target.

.DESCRIPTION
Checks whether azure backup is installed on target node, and is the machine protected by azure backup.
Returns the state of azure backup.

.ROLE
Readers

#>

Function Test-RegistryValue($path, $value) {
    if (Test-Path $path) {
        $Key = Get-Item -LiteralPath $path
        if ($Key.GetValue($value, $null) -ne $null) {
            $true
        }
        else {
            $false
        }
    }
    else {
        $false
    }
}

Set-StrictMode -Version 5.0
$path = 'HKLM:\System\CurrentControlSet\Control\Session Manager\Environment'
$value = 'PSModulePath'
if ((Test-RegistryValue $path $value) -eq $false) {
    @{ Registered = $false }
} else {
    $env:PSModulePath = (Get-ItemProperty -Path $path -Name PSModulePath).PSModulePath
    $AzureBackupModuleName = 'MSOnlineBackup'
    $DpmModuleName = 'DataProtectionManager'
    $DpmModule = Get-Module -ListAvailable -Name $DpmModuleName
    $AzureBackupModule = Get-Module -ListAvailable -Name $AzureBackupModuleName
    $IsAdmin = $false;

    $CurrentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $IsAdmin = $CurrentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if (!$IsAdmin) {
        @{ Registered = $false }
    }
    elseif ($DpmModule) {
        @{ Registered = $false }
    } 
    elseif ($AzureBackupModule) {
        try {
            Import-Module $AzureBackupModuleName
            $registrationstatus = [Microsoft.Internal.CloudBackup.Client.Common.CBClientCommon]::GetMachineRegistrationStatus(0)
            if ($registrationstatus -eq $true) {
                @{ Registered = $true }
            }
            else {
                @{ Registered = $false }
            }
        }
        catch {
            @{ Registered = $false }
        }
    }
    else {
        @{ Registered = $false }
    }
}
}
## [END] Get-AzureProtectionStatus ##
function Get-BmcInfo {
<#

.SYNOPSIS
Gets current information on the baseboard management controller (BMC).

.DESCRIPTION
Gets information such as manufacturer, serial number, last known IP
address, model, and network configuration to show to user.

.ROLE
Readers

#>

$error.Clear()

$bmcInfo = Get-PcsvDevice -ErrorAction SilentlyContinue
$result = New-Object -TypeName PSObject
$result | Add-Member -MemberType NoteProperty -Name "Error" $error.Count

if ($error.Count -EQ 0) {
    $result | Add-Member -MemberType NoteProperty -Name "Ip" $bmcInfo.IPv4Address
    $result | Add-Member -MemberType NoteProperty -Name "Serial" $bmcInfo.SerialNumber
}

$result

}
## [END] Get-BmcInfo ##
function Get-CimMemorySummary {
<#

.SYNOPSIS
Get Memory summary by using ManagementTools CIM provider.

.DESCRIPTION
Get Memory summary by using ManagementTools CIM provider.

.ROLE
Readers

#>
##SkipCheck=true##


import-module CimCmdlets

Get-CimInstance -Namespace root/Microsoft/Windows/ManagementTools -ClassName Msft_MTMemorySummary

}
## [END] Get-CimMemorySummary ##
function Get-CimNetworkAdapterSummary {
<#

.SYNOPSIS
Get Network Adapter summary by using ManagementTools CIM provider.

.DESCRIPTION
Get Network Adapter summary by using ManagementTools CIM provider.

.ROLE
Readers

#>
##SkipCheck=true##


import-module CimCmdlets

Get-CimInstance -Namespace root/Microsoft/Windows/ManagementTools -ClassName Msft_MTNetworkAdapter

}
## [END] Get-CimNetworkAdapterSummary ##
function Get-CimProcessorSummary {
<#

.SYNOPSIS
Get Processor summary by using ManagementTools CIM provider.

.DESCRIPTION
Get Processor summary by using ManagementTools CIM provider.

.ROLE
Readers

#>
##SkipCheck=true##


import-module CimCmdlets

Get-CimInstance -Namespace root/Microsoft/Windows/ManagementTools -ClassName Msft_MTProcessorSummary

}
## [END] Get-CimProcessorSummary ##
function Get-ClientConnectionStatus {
<#

.SYNOPSIS
Gets status of the connection to the client computer.

.DESCRIPTION
Gets status of the connection to the client computer.

.ROLE
Readers

#>

import-module CimCmdlets
$OperatingSystem = Get-CimInstance Win32_OperatingSystem
$Caption = $OperatingSystem.Caption
$ProductType = $OperatingSystem.ProductType
$Version = $OperatingSystem.Version
$Status = @{ Label = $null; Type = 0; Details = $null; }
$Result = @{ Status = $Status; Caption = $Caption; ProductType = $ProductType; Version = $Version; }

if ($Version -and $ProductType -eq 1) {
    $V = [version]$Version
    $V10 = [version]'10.0'
    if ($V -ge $V10) {
        return $Result;
    } 
}

$Status.Label = 'unsupported-label'
$Status.Type = 3
$Status.Details = 'unsupported-details'
return $Result;

}
## [END] Get-ClientConnectionStatus ##
function Get-ComputerIdentification {
<#

.SYNOPSIS
Gets the local computer domain/workplace information.

.DESCRIPTION
Gets the local computer domain/workplace information.
Returns the computer identification information.

.ROLE
Readers

#>

import-module CimCmdlets

$ComputerSystem = Get-CimInstance -Class Win32_ComputerSystem;
$ComputerName = $ComputerSystem.DNSHostName
if ($ComputerName -eq $null) {
    $ComputerName = $ComputerSystem.Name
}

$fqdn = ([System.Net.Dns]::GetHostByName($ComputerName)).HostName

$ComputerSystem | Microsoft.PowerShell.Utility\Select-Object `
@{ Name = "ComputerName"; Expression = { $ComputerName }},
@{ Name = "Domain"; Expression = { if ($_.PartOfDomain) { $_.Domain } else { $null } }},
@{ Name = "DomainJoined"; Expression = { $_.PartOfDomain }},
@{ Name = "FullComputerName"; Expression = { $fqdn }},
@{ Name = "Workgroup"; Expression = { if ($_.PartOfDomain) { $null } else { $_.Workgroup } }}


}
## [END] Get-ComputerIdentification ##
function Get-DiskSummary {
<#

.SYNOPSIS
Get Disk summary by using ManagementTools CIM provider.

.DESCRIPTION
Get Disk summary by using ManagementTools CIM provider.

.ROLE
Readers

#>


import-module CimCmdlets

$ReadResult = (get-itemproperty -path HKLM:\SYSTEM\CurrentControlSet\Services\partmgr -Name EnableCounterForIoctl -ErrorAction SilentlyContinue)
if (!$ReadResult -or $ReadResult.EnableCounterForIoctl -ne 1) {
    # no disk performance counters enabled.
    return
}

$instances = Get-CimInstance -Namespace root/Microsoft/Windows/ManagementTools -ClassName Msft_MTDisk
if ($instances -ne $null) {
    $instances | ForEach-Object {
        $instance = ($_ | Microsoft.PowerShell.Utility\Select-Object ActiveTime, AverageResponseTime, Capacity, CurrentIndex, DiskNumber, IntervalSeconds, Name, ReadTransferRate, WriteTransferRate)
        $volumes = ($_.Volumes | Microsoft.PowerShell.Utility\Select-Object FormattedSize, PageFile, SystemDisk, VolumePath)
        $instance | Add-Member -NotePropertyName Volumes -NotePropertyValue $volumes
        $instance
    }
}


}
## [END] Get-DiskSummary ##
function Get-DiskSummaryDownlevel {
<#

.SYNOPSIS
Gets disk summary information by performance counter WMI object on downlevel computer.

.DESCRIPTION
Gets disk summary information by performance counter WMI object on downlevel computer.

.ROLE
Readers

#>

param
(
)

import-module CimCmdlets

function ResetDiskData($diskResults) {
    $Global:DiskResults = @{}
    $Global:DiskDelta = 0

    foreach ($item in $diskResults) {
        $diskRead = New-Object System.Collections.ArrayList
        $diskWrite = New-Object System.Collections.ArrayList
        for ($i = 0; $i -lt 60; $i++) {
            $diskRead.Insert(0, 0)
            $diskWrite.Insert(0, 0)
        }

        $Global:DiskResults.Item($item.name) = @{
            ReadTransferRate  = $diskRead
            WriteTransferRate = $diskWrite
        }
    }
}

function UpdateDiskData($diskResults) {
    $Global:DiskDelta += ($Global:DiskSampleTime - $Global:DiskLastTime).TotalMilliseconds

    foreach ($diskResult in $diskResults) {
        $localDelta = $Global:DiskDelta

        # update data for each disk
        $item = $Global:DiskResults.Item($diskResult.name)

        if ($item -ne $null) {
            while ($localDelta -gt 1000) {
                $localDelta -= 1000
                $item.ReadTransferRate.Insert(0, $diskResult.DiskReadBytesPersec)
                $item.WriteTransferRate.Insert(0, $diskResult.DiskWriteBytesPersec)
            }

            $item.ReadTransferRate = $item.ReadTransferRate.GetRange(0, 60)
            $item.WriteTransferRate = $item.WriteTransferRate.GetRange(0, 60)

            $Global:DiskResults.Item($diskResult.name) = $item
        }
    }

    $Global:DiskDelta = $localDelta
}

$counterValue = Get-CimInstance win32_perfFormattedData_PerfDisk_PhysicalDisk -Filter "name!='_Total'" | Microsoft.PowerShell.Utility\Select-Object name, DiskReadBytesPersec, DiskWriteBytesPersec
$now = get-date

# get sampling time and remember last sample time.
if (-not $Global:DiskSampleTime) {
    $Global:DiskSampleTime = $now
    $Global:DiskLastTime = $Global:DiskSampleTime
    ResetDiskData($counterValue)
}
else {
    $Global:DiskLastTime = $Global:DiskSampleTime
    $Global:DiskSampleTime = $now
    if ($Global:DiskSampleTime - $Global:DiskLastTime -gt [System.TimeSpan]::FromSeconds(30)) {
        ResetDiskData($counterValue)
    }
    else {
        UpdateDiskData($counterValue)
    }
}

$Global:DiskResults
}
## [END] Get-DiskSummaryDownlevel ##
function Get-EnvironmentVariables {
<#

.SYNOPSIS
Gets 'Machine' and 'User' environment variables.

.DESCRIPTION
Gets 'Machine' and 'User' environment variables.

.ROLE
Readers

#>

Set-StrictMode -Version 5.0

$data = @()

$system = [Environment]::GetEnvironmentVariables([EnvironmentVariableTarget]::Machine)
$user = [Environment]::GetEnvironmentVariables([EnvironmentVariableTarget]::User)

foreach ($h in $system.GetEnumerator()) {
    $obj = @{"Name" = $h.Name; "Value" = $h.Value; "Type" = "Machine"}
    $data += $obj
}

foreach ($h in $user.GetEnumerator()) {
    $obj = @{"Name" = $h.Name; "Value" = $h.Value; "Type" = "User"}
    $data += $obj
}

$data
}
## [END] Get-EnvironmentVariables ##
function Get-HyperVEnhancedSessionModeSettings {
<#

.SYNOPSIS
Gets a computer's Hyper-V Host Enhanced Session Mode settings.

.DESCRIPTION
Gets a computer's Hyper-V Host Enhnaced Session Mode settings.

.ROLE
Readers

#>

Set-StrictMode -Version 5.0
Import-Module Hyper-V

Get-VMHost | Microsoft.PowerShell.Utility\Select-Object `
    EnableEnhancedSessionMode

}
## [END] Get-HyperVEnhancedSessionModeSettings ##
function Get-HyperVGeneralSettings {
<#

.SYNOPSIS
Gets a computer's Hyper-V Host General settings.

.DESCRIPTION
Gets a computer's Hyper-V Host General settings.

.ROLE
Readers

#>

Set-StrictMode -Version 5.0
Import-Module Hyper-V

Get-VMHost | Microsoft.PowerShell.Utility\Select-Object `
    VirtualHardDiskPath, `
    VirtualMachinePath

}
## [END] Get-HyperVGeneralSettings ##
function Get-HyperVHostPhysicalGpuSettings {
<#

.SYNOPSIS
Gets a computer's Hyper-V Host Physical GPU settings.

.DESCRIPTION
Gets a computer's Hyper-V Host Physical GPU settings.

.ROLE
Readers

#>

Set-StrictMode -Version 5.0
Import-Module CimCmdlets

Get-CimInstance -Namespace "root\virtualization\v2" -Class "Msvm_Physical3dGraphicsProcessor" | `
    Microsoft.PowerShell.Utility\Select-Object EnabledForVirtualization, `
    Name, `
    DriverDate, `
    DriverInstalled, `
    DriverModelVersion, `
    DriverProvider, `
    DriverVersion, `
    DirectXVersion, `
    PixelShaderVersion, `
    DedicatedVideoMemory, `
    DedicatedSystemMemory, `
    SharedSystemMemory, `
    TotalVideoMemory

}
## [END] Get-HyperVHostPhysicalGpuSettings ##
function Get-HyperVLiveMigrationSettings {
<#

.SYNOPSIS
Gets a computer's Hyper-V Host Live Migration settings.

.DESCRIPTION
Gets a computer's Hyper-V Host Live Migration settings.

.ROLE
Readers

#>

Set-StrictMode -Version 5.0
Import-Module Hyper-V

Get-VMHost | Microsoft.PowerShell.Utility\Select-Object `
    maximumVirtualMachineMigrations, `
    VirtualMachineMigrationAuthenticationType, `
    VirtualMachineMigrationEnabled, `
    VirtualMachineMigrationPerformanceOption

}
## [END] Get-HyperVLiveMigrationSettings ##
function Get-HyperVMigrationSupport {
<#

.SYNOPSIS
Gets a computer's Hyper-V migration support.

.DESCRIPTION
Gets a computer's Hyper-V  migration support.

.ROLE
Readers

#>

Set-StrictMode -Version 5.0

$migrationSettingsDatas=Microsoft.PowerShell.Management\Get-WmiObject -Namespace root\virtualization\v2 -Query "associators of {Msvm_VirtualSystemMigrationCapabilities.InstanceID=""Microsoft:MigrationCapabilities""} where resultclass = Msvm_VirtualSystemMigrationSettingData"

$live = $false;
$storage = $false;

foreach ($migrationSettingsData in $migrationSettingsDatas) {
    if ($migrationSettingsData.MigrationType -eq 32768) {
        $live = $true;
    }

    if ($migrationSettingsData.MigrationType -eq 32769) {
        $storage = $true;
    }
}

$result = New-Object -TypeName PSObject
$result | Add-Member -MemberType NoteProperty -Name "liveMigrationSupported" $live;
$result | Add-Member -MemberType NoteProperty -Name "storageMigrationSupported" $storage;
$result
}
## [END] Get-HyperVMigrationSupport ##
function Get-HyperVNumaSpanningSettings {
<#

.SYNOPSIS
Gets a computer's Hyper-V Host settings.

.DESCRIPTION
Gets a computer's Hyper-V Host settings.

.ROLE
Readers

#>

Set-StrictMode -Version 5.0
Import-Module Hyper-V

Get-VMHost | Microsoft.PowerShell.Utility\Select-Object `
    NumaSpanningEnabled

}
## [END] Get-HyperVNumaSpanningSettings ##
function Get-HyperVRoleInstalled {
<#

.SYNOPSIS
Gets a computer's Hyper-V role installation state.

.DESCRIPTION
Gets a computer's Hyper-V role installation state.

.ROLE
Readers

#>

Set-StrictMode -Version 5.0
 
$service = Microsoft.PowerShell.Management\get-service -Name "VMMS" -ErrorAction SilentlyContinue;

return ($service -and $service.Name -eq "VMMS");

}
## [END] Get-HyperVRoleInstalled ##
function Get-HyperVStorageMigrationSettings {
<#

.SYNOPSIS
Gets a computer's Hyper-V Host settings.

.DESCRIPTION
Gets a computer's Hyper-V Host settings.

.ROLE
Readers

#>

Set-StrictMode -Version 5.0
Import-Module Hyper-V

Get-VMHost | Microsoft.PowerShell.Utility\Select-Object `
    MaximumStorageMigrations

}
## [END] Get-HyperVStorageMigrationSettings ##
function Get-MemorySummaryDownLevel {
<#

.SYNOPSIS
Gets memory summary information by performance counter WMI object on downlevel computer.

.DESCRIPTION
Gets memory summary information by performance counter WMI object on downlevel computer.

.ROLE
Readers

#>

import-module CimCmdlets

# reset counter reading only first one.
function Reset($counter) {
    $Global:Utilization = [System.Collections.ArrayList]@()
    for ($i = 0; $i -lt 59; $i++) {
        $Global:Utilization.Insert(0, 0)
    }

    $Global:Utilization.Insert(0, $counter)
    $Global:Delta = 0
}

$memory = Get-CimInstance Win32_PerfFormattedData_PerfOS_Memory
$now = get-date
$system = Get-CimInstance Win32_ComputerSystem
$percent = 100 * ($system.TotalPhysicalMemory - $memory.AvailableBytes) / $system.TotalPhysicalMemory
$cached = $memory.StandbyCacheCoreBytes + $memory.StandbyCacheNormalPriorityBytes + $memory.StandbyCacheReserveBytes + $memory.ModifiedPageListBytes

# get sampling time and remember last sample time.
if (-not $Global:SampleTime) {
    $Global:SampleTime = $now
    $Global:LastTime = $Global:SampleTime
    Reset($percent)
}
else {
    $Global:LastTime = $Global:SampleTime
    $Global:SampleTime = $now
    if ($Global:SampleTime - $Global:LastTime -gt [System.TimeSpan]::FromSeconds(30)) {
        Reset($percent)
    }
    else {
        $Global:Delta += ($Global:SampleTime - $Global:LastTime).TotalMilliseconds
        while ($Global:Delta -gt 1000) {
            $Global:Delta -= 1000
            $Global:Utilization.Insert(0, $percent)
        }

        $Global:Utilization = $Global:Utilization.GetRange(0, 60)
    }
}

$result = New-Object -TypeName PSObject
$result | Add-Member -MemberType NoteProperty -Name "Available" $memory.AvailableBytes
$result | Add-Member -MemberType NoteProperty -Name "Cached" $cached
$result | Add-Member -MemberType NoteProperty -Name "Total" $system.TotalPhysicalMemory
$result | Add-Member -MemberType NoteProperty -Name "InUse" ($system.TotalPhysicalMemory - $memory.AvailableBytes)
$result | Add-Member -MemberType NoteProperty -Name "Committed" $memory.CommittedBytes
$result | Add-Member -MemberType NoteProperty -Name "PagedPool" $memory.PoolPagedBytes
$result | Add-Member -MemberType NoteProperty -Name "NonPagedPool" $memory.PoolNonpagedBytes
$result | Add-Member -MemberType NoteProperty -Name "Utilization" $Global:Utilization
$result
}
## [END] Get-MemorySummaryDownLevel ##
function Get-MmaStatus {
<#

.SYNOPSIS
Script that returns if Microsoft Monitoring Agent is running or not.

.DESCRIPTION
Script that returns if Microsoft Monitoring Agent is running or not.

.ROLE
Readers

#>

Import-Module Microsoft.PowerShell.Management

$status = Get-Service -Name HealthService -ErrorAction SilentlyContinue
if ($status -eq $null) {
    # which means no such service is found.
    @{ Installed = $false; Running = $false }
}
elseif ($status.Status -eq "Running") {
    @{ Installed = $true; Running = $true }
}
else {
    @{ Installed = $true; Running = $false }
}

}
## [END] Get-MmaStatus ##
function Get-NetworkSummaryDownlevel {
<#

.SYNOPSIS
Gets network adapter summary information by performance counter WMI object on downlevel computer.

.DESCRIPTION
Gets network adapter summary information by performance counter WMI object on downlevel computer.

.ROLE
Readers

#>

import-module CimCmdlets
function ResetData($adapterResults) {
    $Global:NetworkResults = @{}
    $Global:PrevAdapterData = @{}
    $Global:Delta = 0

    foreach ($key in $adapterResults.Keys) {
        $adapterResult = $adapterResults.Item($key)
        $sentBytes = New-Object System.Collections.ArrayList
        $receivedBytes = New-Object System.Collections.ArrayList
        for ($i = 0; $i -lt 60; $i++) {
            $sentBytes.Insert(0, 0)
            $receivedBytes.Insert(0, 0)
        }

        $networkResult = @{
            SentBytes = $sentBytes
            ReceivedBytes = $receivedBytes
        }
        $Global:NetworkResults.Item($key) = $networkResult
    }
}

function UpdateData($adapterResults) {
    $Global:Delta += ($Global:SampleTime - $Global:LastTime).TotalMilliseconds

    foreach ($key in $adapterResults.Keys) {
        $localDelta = $Global:Delta

        # update data for each adapter
        $adapterResult = $adapterResults.Item($key)
        $item = $Global:NetworkResults.Item($key)
        if ($item -ne $null) {
            while ($localDelta -gt 1000) {
                $localDelta -= 1000
                $item.SentBytes.Insert(0, $adapterResult.SentBytes)
                $item.ReceivedBytes.Insert(0, $adapterResult.ReceivedBytes)
            }

            $item.SentBytes = $item.SentBytes.GetRange(0, 60)
            $item.ReceivedBytes = $item.ReceivedBytes.GetRange(0, 60)

            $Global:NetworkResults.Item($key) = $item
        }
    }

    $Global:Delta = $localDelta
}

$adapters = Get-CimInstance -Namespace root/standardCimV2 MSFT_NetAdapter | Where-Object MediaConnectState -eq 1 | Microsoft.PowerShell.Utility\Select-Object Name, InterfaceIndex, InterfaceDescription
$activeAddresses = get-CimInstance -Namespace root/standardCimV2 MSFT_NetIPAddress | Microsoft.PowerShell.Utility\Select-Object interfaceIndex

$adapterResults = @{}
foreach ($adapter in $adapters) {
    foreach ($activeAddress in $activeAddresses) {
        # Find a match between the 2
        if ($adapter.InterfaceIndex -eq $activeAddress.interfaceIndex) {
            $description = $adapter | Microsoft.PowerShell.Utility\Select-Object -ExpandProperty interfaceDescription

            if ($Global:UsePerfData -EQ $NULL) {
                $adapterData = Get-CimInstance -Namespace root/StandardCimv2 MSFT_NetAdapterStatisticsSettingData -Filter "Description='$description'" | Microsoft.PowerShell.Utility\Select-Object ReceivedBytes, SentBytes

                if ($adapterData -EQ $null) {
                    # If above doesnt return data use slower perf data below
                    $Global:UsePerfData = $true
                }
            }

            if ($Global:UsePerfData -EQ $true) {
                # Need to replace the '#' to ascii since we parse anything after # as a comment
                $sanitizedDescription = $description -replace [char]35, "_"
                $adapterData = Get-CimInstance Win32_PerfFormattedData_Tcpip_NetworkAdapter | Where-Object name -EQ $sanitizedDescription | Microsoft.PowerShell.Utility\Select-Object BytesSentPersec, BytesReceivedPersec

                $sentBytes = $adapterData.BytesSentPersec
                $receivedBytes = $adapterData.BytesReceivedPersec
            }
            else {
                # set to 0 because we dont have a baseline to subtract from
                $sentBytes = 0
                $receivedBytes = 0

                if ($Global:PrevAdapterData -ne $null) {
                    $prevData = $Global:PrevAdapterData.Item($description)
                    if ($prevData -ne $null) {
                        $sentBytes = $adapterData.SentBytes - $prevData.SentBytes
                        $receivedBytes = $adapterData.ReceivedBytes - $prevData.ReceivedBytes
                    }
                }
                else {
                    $Global:PrevAdapterData = @{}
                }

                # Now that we have data, set current data as previous data as baseline
                $Global:PrevAdapterData.Item($description) = $adapterData
            }

            $adapterResult = @{
                SentBytes = $sentBytes
                ReceivedBytes = $receivedBytes
            }
            $adapterResults.Item($description) = $adapterResult
            break;
        }
    }
}

$now = get-date

if (-not $Global:SampleTime) {
    $Global:SampleTime = $now
    $Global:LastTime = $Global:SampleTime
    ResetData($adapterResults)
}
else {
    $Global:LastTime = $Global:SampleTime
    $Global:SampleTime = $now
    if ($Global:SampleTime - $Global:LastTime -gt [System.TimeSpan]::FromSeconds(30)) {
        ResetData($adapterResults)
    }
    else {
        UpdateData($adapterResults)
    }
}

$Global:NetworkResults
}
## [END] Get-NetworkSummaryDownlevel ##
function Get-NumberOfLoggedOnUsers {
<#

.SYNOPSIS
Gets the number of logged on users.

.DESCRIPTION
Gets the number of logged on users including active and disconnected users.
Returns a count of users.

.ROLE
Readers

#>

$count = 0
$error.Clear();

# query user may return an uncatchable error. We need to redirect it.
# Sends errors (2) and success output (1) to the success output stream.
$result = query user 2>&1

if ($error.Count -EQ 0)
{
    # query user does not return a valid ps object and includes the header.
    # subtract 1 to get actual count.
    $count = $result.count -1
}

@{Count = $count}
}
## [END] Get-NumberOfLoggedOnUsers ##
function Get-PowerConfigurationPlan {
<#

.SYNOPSIS
Gets the power plans on the machine.

.DESCRIPTION
Gets the power plans on the machine.

.ROLE
Readers

#>

$GuidLength = 36
$plans = Get-CimInstance -Namespace root\cimv2\power -ClassName Win32_PowerPlan

if ($plans) {
  $result = New-Object 'System.Collections.Generic.List[System.Object]'

  foreach ($plan in $plans) {
    $currentPlan = New-Object -TypeName PSObject

    $currentPlan | Add-Member -MemberType NoteProperty -Name 'Name' -Value $plan.ElementName
    $currentPlan | Add-Member -MemberType NoteProperty -Name 'DisplayName' -Value $plan.ElementName
    $currentPlan | Add-Member -MemberType NoteProperty -Name 'IsActive' -Value $plan.IsActive
    $startBrace = $plan.InstanceID.IndexOf("{")
    $currentPlan | Add-Member -MemberType NoteProperty -Name 'Guid' -Value $plan.InstanceID.SubString($startBrace + 1, $GuidLength)

    $result.Add($currentPlan)
  }

  return $result.ToArray()
}

return $null

}
## [END] Get-PowerConfigurationPlan ##
function Get-ProcessorSummaryDownlevel {
<#

.SYNOPSIS
Gets processor summary information by performance counter WMI object on downlevel computer.

.DESCRIPTION
Gets processor summary information by performance counter WMI object on downlevel computer.

.ROLE
Readers

#>

import-module CimCmdlets

# reset counter reading only first one.
function Reset($counter) {
    $Global:Utilization = [System.Collections.ArrayList]@()
    for ($i = 0; $i -lt 59; $i++) {
        $Global:Utilization.Insert(0, 0)
    }

    $Global:Utilization.Insert(0, $counter)
    $Global:Delta = 0
}

$processorCounter = Get-CimInstance Win32_PerfFormattedData_Counters_ProcessorInformation -Filter "name='_Total'"
$now = get-date
$processor = Get-CimInstance Win32_Processor
$os = Get-CimInstance Win32_OperatingSystem
$processes = Get-CimInstance Win32_Process
$percent = $processorCounter.PercentProcessorTime
$handles = 0
$threads = 0
$processes | ForEach-Object { $handles += $_.HandleCount; $threads += $_.ThreadCount }
$uptime = ($now - $os.LastBootUpTime).TotalMilliseconds * 10000

# get sampling time and remember last sample time.
if (-not $Global:SampleTime) {
    $Global:SampleTime = $now
    $Global:LastTime = $Global:SampleTime
    Reset($percent)
}
else {
    $Global:LastTime = $Global:SampleTime
    $Global:SampleTime = $now
    if ($Global:SampleTime - $Global:LastTime -gt [System.TimeSpan]::FromSeconds(30)) {
        Reset($percent)
    }
    else {
        $Global:Delta += ($Global:SampleTime - $Global:LastTime).TotalMilliseconds
        while ($Global:Delta -gt 1000) {
            $Global:Delta -= 1000
            $Global:Utilization.Insert(0, $percent)
        }

        $Global:Utilization = $Global:Utilization.GetRange(0, 60)
    }
}

$result = New-Object -TypeName PSObject
$result | Add-Member -MemberType NoteProperty -Name "Name" $processor[0].Name
$result | Add-Member -MemberType NoteProperty -Name "AverageSpeed" ($processor[0].CurrentClockSpeed / 1000)
$result | Add-Member -MemberType NoteProperty -Name "Processes" $processes.Length
$result | Add-Member -MemberType NoteProperty -Name "Uptime" $uptime
$result | Add-Member -MemberType NoteProperty -Name "Handles" $handles
$result | Add-Member -MemberType NoteProperty -Name "Threads" $threads
$result | Add-Member -MemberType NoteProperty -Name "Utilization" $Global:Utilization
$result
}
## [END] Get-ProcessorSummaryDownlevel ##
function Get-RbacEnabled {
<#

.SYNOPSIS
Gets the state of the Get-PSSessionConfiguration command

.DESCRIPTION
Gets the state of the Get-PSSessionConfiguration command

.ROLE
Readers

#>

if ($null -ne (Get-Command Get-PSSessionConfiguration -ErrorAction SilentlyContinue)) {
  @{ State = 'Available' }
} else {
  @{ State = 'NotSupported' }
}

}
## [END] Get-RbacEnabled ##
function Get-RbacSessionConfiguration {
<#

.SYNOPSIS
Gets a Microsoft.Sme.PowerShell endpoint configuration.

.DESCRIPTION
Gets a Microsoft.Sme.PowerShell endpoint configuration.

.ROLE
Administrators

#>

param(
    [Parameter(Mandatory = $false)]
    [String]
    $configurationName = "Microsoft.Sme.PowerShell"
)

## check if it's full administrators
if ((Get-Command Get-PSSessionConfiguration -ErrorAction SilentlyContinue) -ne $null) {
    @{
        Administrators = $true
        Configured = (Get-PSSessionConfiguration $configurationName -ErrorAction SilentlyContinue) -ne $null
    }
} else {
    @{
        Administrators = $false
        Configured = $false
    }
}
}
## [END] Get-RbacSessionConfiguration ##
function Get-RemoteDesktop {
<#
.SYNOPSIS
Gets the Remote Desktop settings of the system.

.DESCRIPTION
Gets the Remote Desktop settings of the system.

.ROLE
Readers
#>

Set-StrictMode -Version 5.0

Import-Module Microsoft.PowerShell.Management
Import-Module Microsoft.PowerShell.Utility
Import-Module NetSecurity -ErrorAction SilentlyContinue
Import-Module ServerManager -ErrorAction SilentlyContinue

Set-Variable -Option Constant -Name OSRegistryKey -Value "HKLM:\Software\Microsoft\Windows NT\CurrentVersion" -ErrorAction SilentlyContinue
Set-Variable -Option Constant -Name OSTypePropertyName -Value "InstallationType" -ErrorAction SilentlyContinue
Set-Variable -Option Constant -Name OSVersion -Value [Environment]::OSVersion.Version -ErrorAction SilentlyContinue
Set-Variable -Option Constant -Name RdpSystemRegistryKey -Value "HKLM:\\SYSTEM\CurrentControlSet\Control\Terminal Server" -ErrorAction SilentlyContinue
Set-Variable -Option Constant -Name RdpGroupPolicyProperty -Value "fDenyTSConnections" -ErrorAction SilentlyContinue
Set-Variable -Option Constant -Name RdpNlaGroupPolicyProperty -Value "UserAuthentication" -ErrorAction SilentlyContinue
Set-Variable -Option Constant -Name RdpGroupPolicyRegistryKey -Value "HKLM:\\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" -ErrorAction SilentlyContinue
Set-Variable -Option Constant -Name RdpListenerRegistryKey -Value "$RdpSystemRegistryKey\WinStations" -ErrorAction SilentlyContinue
Set-Variable -Option Constant -Name RdpProtocolTypeUM -Value "{5828227c-20cf-4408-b73f-73ab70b8849f}" -ErrorAction SilentlyContinue
Set-Variable -Option Constant -Name RdpProtocolTypeKM -Value "{18b726bb-6fe6-4fb9-9276-ed57ce7c7cb2}" -ErrorAction SilentlyContinue
Set-Variable -Option Constant -Name RdpWdfSubDesktop -Value 0x00008000 -ErrorAction SilentlyContinue
Set-Variable -Option Constant -Name RdpFirewallGroup -Value "@FirewallAPI.dll,-28752" -ErrorAction SilentlyContinue
Set-Variable -Option Constant -Name RemoteAppRegistryKey -Value "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Terminal Server\TSAppAllowList" -ErrorAction SilentlyContinue

<#
.SYNOPSIS
Gets the Remote Desktop Network Level Authentication settings of the current machine.

.DESCRIPTION
Gets the Remote Desktop Network Level Authentication settings of the system.

.ROLE
Readers
#>
function Get-RdpNlaGroupPolicySettings {
    $nlaGroupPolicySettings = @{}
    $nlaGroupPolicySettings.GroupPolicyIsSet = $false
    $nlaGroupPolicySettings.GroupPolicyIsEnabled = $false
    $registryKey = Get-ItemProperty -Path $RdpGroupPolicyRegistryKey -ErrorAction SilentlyContinue
    if (!!$registryKey) {
        if ((Get-Member -InputObject $registryKey -name $RdpNlaGroupPolicyProperty -MemberType Properties) -and ($null -ne $registryKey.$RdpNlaGroupPolicyProperty)) {
            $nlaGroupPolicySettings.GroupPolicyIsSet = $true
            $nlaGroupPolicySettings.GroupPolicyIsEnabled = $registryKey.$RdpNlaGroupPolicyProperty -eq 1
        }
    }

    return $nlaGroupPolicySettings
}

<#
.SYNOPSIS
Gets the Remote Desktop settings of the system related to Group Policy.

.DESCRIPTION
Gets the Remote Desktop settings of the system related to Group Policy.

.ROLE
Readers
#>
function Get-RdpGroupPolicySettings {
    $rdpGroupPolicySettings = @{}
    $rdpGroupPolicySettings.GroupPolicyIsSet = $false
    $rdpGroupPolicySettings.GroupPolicyIsEnabled = $false
    $registryKey = Get-ItemProperty -Path $RdpGroupPolicyRegistryKey -ErrorAction SilentlyContinue
    if (!!$registryKey) {
        if ((Get-Member -InputObject $registryKey -name $RdpGroupPolicyProperty -MemberType Properties) -and ($null -ne $registryKey.$RdpGroupPolicyProperty)) {
            $rdpGroupPolicySettings.groupPolicyIsSet = $true
            $rdpGroupPolicySettings.groupPolicyIsEnabled = $registryKey.$RdpGroupPolicyProperty -eq 0
        }
    }

    return $rdpGroupPolicySettings
}

<#
.SYNOPSIS
Gets all of the valid Remote Desktop Protocol listeners.

.DESCRIPTION
Gets all of the valid Remote Desktop Protocol listeners.

.ROLE
Readers
#>
function Get-RdpListener {
    $listeners = @()
    Get-ChildItem -Name $RdpListenerRegistryKey | Where-Object { $_.PSChildName.ToLower() -ne "console" } | ForEach-Object {
        $registryKeyValues = Get-ItemProperty -Path "$RdpListenerRegistryKey\$_" -ErrorAction SilentlyContinue
        if ($null -ne $registryKeyValues) {
            $protocol = $registryKeyValues.LoadableProtocol_Object
            $isProtocolRDP = ($null -ne $protocol) -and ($protocol -eq $RdpProtocolTypeUM -or $protocol -eq $RdpProtocolTypeKM)

            $wdFlag = $registryKeyValues.WdFlag
            $isSubDesktop = ($null -ne $wdFlag) -and ($wdFlag -band $RdpWdfSubDesktop)

            $isRDPListener = $isProtocolRDP -and !$isSubDesktop
            if ($isRDPListener) {
                $listeners += $registryKeyValues
            }
        }
    }

    return ,$listeners
}

<#
.SYNOPSIS
Gets the number of the ports that the Remote Desktop Protocol is operating over.

.DESCRIPTION
Gets the number of the ports that the Remote Desktop Protocol is operating over.

.ROLE
Readers
#>
function Get-RdpPortNumber {
    $portNumbers = @()
    Get-RdpListener | Where-Object { $null -ne $_.PortNumber } | ForEach-Object { $portNumbers += $_.PortNumber }
    return ,$portNumbers
}

<#
.SYNOPSIS
Gets the Remote Desktop settings of the system.

.DESCRIPTION
Gets the Remote Desktop settings of the system.

.ROLE
Readers
#>
function Get-RdpSettings {
    $remoteDesktopSettings = New-Object -TypeName PSObject
    $rdpEnabledSource = $null
    $rdpIsEnabled = Test-RdpEnabled
    $rdpRequiresNla = Test-RdpUserAuthentication
    $remoteAppAllowed = Test-RemoteApp
    $rdpPortNumbers = Get-RdpPortNumber
    if ($rdpIsEnabled) {
        $rdpGroupPolicySettings = Get-RdpGroupPolicySettings
        if ($rdpGroupPolicySettings.groupPolicyIsEnabled) {
            $rdpEnabledSource = "GroupPolicy"
        } else {
            $rdpEnabledSource = "System"
        }
    }
    $operatingSystemType = Get-OperatingSystemType
    $desktopFeatureAvailable = Test-DesktopFeature($operatingSystemType)
    $versionIsSupported = Test-OSVersion($operatingSystemType)

    $remoteDesktopSettings | Add-Member -MemberType NoteProperty -Name "IsEnabled" -Value $rdpIsEnabled
    $remoteDesktopSettings | Add-Member -MemberType NoteProperty -Name "RequiresNLA" -Value $rdpRequiresNla
    $remoteDesktopSettings | Add-Member -MemberType NoteProperty -Name "Ports" -Value $rdpPortNumbers
    $remoteDesktopSettings | Add-Member -MemberType NoteProperty -Name "EnabledSource" -Value $rdpEnabledSource
    $remoteDesktopSettings | Add-Member -MemberType NoteProperty -Name "RemoteAppAllowed" -Value $remoteAppAllowed
    $remoteDesktopSettings | Add-Member -MemberType NoteProperty -Name "DesktopFeatureAvailable" -Value $desktopFeatureAvailable
    $remoteDesktopSettings | Add-Member -MemberType NoteProperty -Name "VersionIsSupported" -Value $versionIsSupported

    return $remoteDesktopSettings
}

<#
.SYNOPSIS
Tests whether Remote Desktop Protocol is enabled.

.DESCRIPTION
Tests whether Remote Desktop Protocol is enabled.

.ROLE
Readers
#>
function Test-RdpEnabled {
    $rdpEnabledWithGP = $false
    $rdpEnabledLocally = $false
    $rdpGroupPolicySettings = Get-RdpGroupPolicySettings
    $rdpEnabledWithGP = $rdpGroupPolicySettings.GroupPolicyIsSet -and $rdpGroupPolicySettings.GroupPolicyIsEnabled
    $rdpEnabledLocally = !($rdpGroupPolicySettings.GroupPolicyIsSet) -and (Test-RdpSystem)

    return (Test-RdpListener) -and (Test-RdpFirewall) -and ($rdpEnabledWithGP -or $rdpEnabledLocally)
}

<#
.SYNOPSIS
Tests whether the Remote Desktop Firewall rules are enabled.

.DESCRIPTION
Tests whether the Remote Desktop Firewall rules are enabled.

.ROLE
Readers
#>
function Test-RdpFirewall {
    $firewallRulesEnabled = $true
    Get-NetFirewallRule -Group $RdpFirewallGroup | Where-Object { $_.Profile -match "Domain" } | ForEach-Object {
        if ($_.Enabled -eq "False") {
            $firewallRulesEnabled = $false
        }
    }

    return $firewallRulesEnabled
}

<#
.SYNOPSIS
Tests whether or not a Remote Desktop Protocol listener exists.

.DESCRIPTION
Tests whether or not a Remote Desktop Protocol listener exists.

.ROLE
Readers
#>
function Test-RdpListener {
    $listeners = Get-RdpListener
    return ($listeners | Microsoft.PowerShell.Utility\Measure-Object).Count -gt 0
}

<#
.SYNOPSIS
Tests whether Remote Desktop Protocol is enabled via local system settings.

.DESCRIPTION
Tests whether Remote Desktop Protocol is enabled via local system settings.

.ROLE
Readers
#>
function Test-RdpSystem {
    $registryKey = Get-ItemProperty -Path $RdpSystemRegistryKey -ErrorAction SilentlyContinue

    if ($registryKey) {
        return $registryKey.fDenyTSConnections -eq 0
    } else {
        return $false
    }
}

<#
.SYNOPSIS
Tests whether Remote Desktop connections require Network Level Authentication while enabled via local system settings.

.DESCRIPTION
Tests whether Remote Desktop connections require Network Level Authentication while enabled via local system settings.

.ROLE
Readers
#>
function Test-RdpSystemUserAuthentication {
    $listener = Get-RdpListener | Where-Object { $null -ne $_.UserAuthentication } | Microsoft.PowerShell.Utility\Select-Object -First 1

    if ($listener) {
        return $listener.UserAuthentication -eq 1
    } else {
        return $false
    }
}

<#
.SYNOPSIS
Tests whether Remote Desktop connections require Network Level Authentication.

.DESCRIPTION
Tests whether Remote Desktop connections require Network Level Authentication.

.ROLE
Readers
#>
function Test-RdpUserAuthentication {
    $nlaEnabledWithGP = $false
    $nlaEnabledLocally = $false
    $nlaGroupPolicySettings = Get-RdpNlaGroupPolicySettings
    $nlaEnabledWithGP = $nlaGroupPolicySettings.GroupPolicyIsSet -and $nlaGroupPolicySettings.GroupPolicyIsEnabled
    $nlaEnabledLocally = !($nlaGroupPolicySettings.GroupPolicyIsSet) -and (Test-RdpSystemUserAuthentication)

    return $nlaEnabledWithGP -or $nlaEnabledLocally
}

<#
.SYNOPSIS
Tests whether Remote App connections are allowed.

.DESCRIPTION
Tests whether Remote App connections are allowed.

.ROLE
Readers
#>
function Test-RemoteApp {
  $registryKey = Get-ItemProperty -Path $RemoteAppRegistryKey -Name fDisabledAllowList -ErrorAction SilentlyContinue
  if ($registryKey)
  {
      $remoteAppEnabled = $registryKey.fDisabledAllowList
      return $remoteAppEnabled -eq 1
  } else {
      return $false;
  }
}

<#
.SYNOPSIS
Gets the Windows OS installation type.

.DESCRIPTION
Gets the Windows OS installation type.

.ROLE
Readers
#>
function Get-OperatingSystemType {
    $osResult = Get-ItemProperty -Path $OSRegistryKey -Name $OSTypePropertyName -ErrorAction SilentlyContinue

    if ($osResult -and $osResult.$OSTypePropertyName) {
        return $osResult.$OSTypePropertyName
    } else {
        return $null
    }
}

<#
.SYNOPSIS
Tests the availability of desktop features based on the system's OS type.

.DESCRIPTION
Tests the availability of desktop features based on the system's OS type.

.ROLE
Readers
#>
function Test-DesktopFeature ([string] $osType) {
    $featureAvailable = $false

    switch ($osType) {
        'Client' {
            $featureAvailable = $true
        }
        'Server' {
            $DesktopFeature = Get-DesktopFeature
            if ($DesktopFeature) {
                $featureAvailable = $DesktopFeature.Installed
            }
        }
    }

    return $featureAvailable
}

<#
.SYNOPSIS
Checks for feature cmdlet availability and returns the installation state of the Desktop Experience feature.

.DESCRIPTION
Checks for feature cmdlet availability and returns the installation state of the Desktop Experience feature.

.ROLE
Readers
#>
function Get-DesktopFeature {
    $moduleAvailable = Get-Module -ListAvailable -Name ServerManager -ErrorAction SilentlyContinue
    if ($moduleAvailable) {
        return Get-WindowsFeature -Name Desktop-Experience -ErrorAction SilentlyContinue
    } else {
        return $null
    }
}

<#
.SYNOPSIS
Tests whether the current OS type/version is supported for Remote App.

.DESCRIPTION
Tests whether the current OS type/version is supported for Remote App.

.ROLE
Readers
#>
function Test-OSVersion ([string] $osType) {
    switch ($osType) {
        'Client' {
            return (Get-OSVersion) -ge (new-object 'Version' 6,2)
        }
        'Server' {
            return (Get-OSVersion) -ge (new-object 'Version' 6,3)
        }
        default {
            return $false
        }
    }
}

<#
.SYNOPSIS
Retrieves the system version information from the system's environment variables.

.DESCRIPTION
Retrieves the system version information from the system's environment variables.

.ROLE
Readers
#>
function Get-OSVersion {
    return [Environment]::OSVersion.Version
}

#########
# Main
#########

$module = Get-Module -Name NetSecurity -ErrorAction SilentlyContinue

if ($module) {
    Get-RdpSettings
}
}
## [END] Get-RemoteDesktop ##
function Get-SQLServerEndOfSupportVersion {
<#

.SYNOPSIS
Gets information about SQL Server installation on the server.

.DESCRIPTION
Gets information about SQL Server installation on the server.

.ROLE
Readers

#>

import-module CimCmdlets

$V2008 = [version]'10.0.0.0'
$V2008R2 = [version]'10.50.0.0'

Set-Variable -Name SQLRegistryRoot64Bit -Option ReadOnly -Value "HKLM:\\SOFTWARE\\Microsoft\\Microsoft SQL Server" -ErrorAction SilentlyContinue
Set-Variable -Name SQLRegistryRoot32Bit -Option ReadOnly -Value "HKLM:\\SOFTWARE\\Wow6432Node\\Microsoft\\Microsoft SQL Server" -ErrorAction SilentlyContinue
Set-Variable -Name InstanceNamesSubKey -Option ReadOnly -Value "Instance Names"-ErrorAction SilentlyContinue
Set-Variable -Name SQLSubKey -Option ReadOnly -Value "SQL" -ErrorAction SilentlyContinue
Set-Variable -Name CurrentVersionSubKey -Option ReadOnly -Value "CurrentVersion" -ErrorAction SilentlyContinue
Set-Variable -Name Running -Option ReadOnly -Value "Running" -ErrorAction SilentlyContinue

function Get-KeyPropertiesAndValues($path) {
  Get-Item $path -ErrorAction SilentlyContinue |
  Microsoft.PowerShell.Utility\Select-Object -ExpandProperty property |
  ForEach-Object {
    New-Object psobject -Property @{"Property"=$_; "Value" = (Get-ItemProperty -Path $path -Name $_ -ErrorAction SilentlyContinue).$_}
  }
}

function IsEndofSupportVersion($SQLRegistryPath) {
  $result = $false
  if (Test-Path -Path $SQLRegistryPath) {
    # construct reg key path to lead up to instances.
    $InstanceNamesKeyPath = Join-Path $SQLRegistryPath -ChildPath $InstanceNamesSubKey | Join-Path -ChildPath $SQLSubKey

    if (Test-Path -Path $InstanceNamesKeyPath) {
      # get properties and their values
      $InstanceCollection = Get-KeyPropertiesAndValues($InstanceNamesKeyPath)
      if ($InstanceCollection) {
        foreach ($Instance in $InstanceCollection) {
          if (Get-Service | Where-Object { $_.Status -eq $Running } | Where-Object { $_.Name -eq $Instance.Property }) {
            $VersionPath = Join-Path $SQLRegistryPath -ChildPath $Instance.Value | Join-Path -ChildPath $Instance.Property | Join-Path -ChildPath $CurrentVersionSubKey
            if (Test-Path -Path $VersionPath) {
              $CurrentVersion = [version] (Get-ItemPropertyValue $VersionPath $CurrentVersionSubKey -ErrorAction SilentlyContinue)
              if ($CurrentVersion -ge $V2008 -and $CurrentVersion -le $V2008R2) {
                $result = $true
                break
              }
            }
          }
        }
      }
    }
  }

  return $result
}

$Result64Bit = IsEndofSupportVersion($SQLRegistryRoot64Bit)
$Result32Bit = IsEndofSupportVersion($SQLRegistryRoot32Bit)

return $Result64Bit -OR $Result32Bit

}
## [END] Get-SQLServerEndOfSupportVersion ##
function Get-ServerConnectionStatus {
<#

.SYNOPSIS
Gets status of the connection to the server.

.DESCRIPTION
Gets status of the connection to the server.

.ROLE
Readers

#>

import-module CimCmdlets

$OperatingSystem = Get-CimInstance Win32_OperatingSystem
$Caption = $OperatingSystem.Caption
$ProductType = $OperatingSystem.ProductType
$Version = $OperatingSystem.Version
$Status = @{ Label = $null; Type = 0; Details = $null; }
$Result = @{ Status = $Status; Caption = $Caption; ProductType = $ProductType; Version = $Version; }
if ($Version -and ($ProductType -eq 2 -or $ProductType -eq 3)) {
    $V = [version]$Version
    $V2016 = [version]'10.0'
    $V2012 = [version]'6.2'
    $V2008r2 = [version]'6.1'

    if ($V -ge $V2016) {
        return $Result;
    }

    if ($V -ge $V2008r2) {
        $Key = 'HKLM:\\SOFTWARE\\Microsoft\\PowerShell\\3\\PowerShellEngine'
        $WmfStatus = $false;
        $Exists = Get-ItemProperty -Path $Key -Name PowerShellVersion -ErrorAction SilentlyContinue
        if (![String]::IsNullOrEmpty($Exists)) {
            $WmfVersionInstalled = $exists.PowerShellVersion
            if ($WmfVersionInstalled.StartsWith('5.')) {
                $WmfStatus = $true;
            }
        }

        if (!$WmfStatus) {
            $status.Label = 'wmfMissing-label'
            $status.Type = 3
            $status.Details = 'wmfMissing-details'
        }

        return $result;
    }
}

$status.Label = 'unsupported-label'
$status.Type = 3
$status.Details = 'unsupported-details'
return $result;

}
## [END] Get-ServerConnectionStatus ##
function New-EnvironmentVariable {
<#

.SYNOPSIS
Creates a new environment variable specified by name, type and data.

.DESCRIPTION
Creates a new environment variable specified by name, type and data.

.ROLE
Administrators

#>

param(
    [Parameter(Mandatory = $True)]
    [String]
    $name,

    [Parameter(Mandatory = $True)]
    [String]
    $value,

    [Parameter(Mandatory = $True)]
    [String]
    $type
)

Set-StrictMode -Version 5.0
$strings = 
ConvertFrom-StringData @'
EnvironmentErrorAlreadyExists=An environment variable of this name and type already exists.
EnvironmentErrorDoesNotExists=An environment variable of this name and type does not exist.
'@


If ([Environment]::GetEnvironmentVariable($name, $type) -eq $null) {
    return [Environment]::SetEnvironmentVariable($name, $value, $type)
}
Else {
    Write-Error $strings.EnvironmentErrorAlreadyExists
}
}
## [END] New-EnvironmentVariable ##
function Remove-EnvironmentVariable {
<#

.SYNOPSIS
Removes an environment variable specified by name and type.

.DESCRIPTION
Removes an environment variable specified by name and type.

.ROLE
Administrators

#>

param(
    [Parameter(Mandatory = $True)]
    [String]
    $name,

    [Parameter(Mandatory = $True)]
    [String]
    $type
)

Set-StrictMode -Version 5.0
$strings = 
ConvertFrom-StringData @'
EnvironmentErrorAlreadyExists=An environment variable of this name and type already exists.
EnvironmentErrorDoesNotExists=An environment variable of this name and type does not exist.
'@


If ([Environment]::GetEnvironmentVariable($name, $type) -eq $null) {
    Write-Error $strings.EnvironmentErrorDoesNotExists
}
Else {
    [Environment]::SetEnvironmentVariable($name, $null, $type)
}
}
## [END] Remove-EnvironmentVariable ##
function Restart-CimOperatingSystem {
<#

.SYNOPSIS
Reboot Windows Operating System by using Win32_OperatingSystem provider.

.DESCRIPTION
Reboot Windows Operating System by using Win32_OperatingSystem provider.

.ROLE
Administrators

#>
##SkipCheck=true##

Param(
)

import-module CimCmdlets

Invoke-CimMethod -Namespace root/cimv2 -ClassName Win32_OperatingSystem -MethodName Reboot

}
## [END] Restart-CimOperatingSystem ##
function Set-ComputerIdentification {
<#

.SYNOPSIS
Sets a computer and/or its domain/workgroup information.

.DESCRIPTION
Sets a computer and/or its domain/workgroup information.

.ROLE
Administrators

#>

param(
    [Parameter(Mandatory = $False)]
    [string]
    $ComputerName = '',

    [Parameter(Mandatory = $False)]
    [string]
    $NewComputerName = '',

    [Parameter(Mandatory = $False)]
    [string]
    $Domain = '',

    [Parameter(Mandatory = $False)]
    [string]
    $NewDomain = '',

    [Parameter(Mandatory = $False)]
    [string]
    $Workgroup = '',

    [Parameter(Mandatory = $False)]
    [string]
    $UserName = '',

    [Parameter(Mandatory = $False)]
    [string]
    $Password = '',

    [Parameter(Mandatory = $False)]
    [string]
    $UserNameNew = '',

    [Parameter(Mandatory = $False)]
    [string]
    $PasswordNew = '',

    [Parameter(Mandatory = $False)]
    [switch]
    $Restart)

function CreateDomainCred($username, $password) {
    $secureString = ConvertTo-SecureString $password -AsPlainText -Force
    $domainCreds = New-Object System.Management.Automation.PSCredential($username, $secureString)

    return $domainCreds
}

function UnjoinDomain($domain) {
    If ($domain) {
        $unjoinCreds = CreateDomainCred $UserName $Password
        Remove-Computer -UnjoinDomainCredential $unjoinCreds -PassThru -Force
    }
}

If ($NewDomain) {
    $newDomainCreds = $null
    If ($Domain) {
        UnjoinDomain $Domain
        $newDomainCreds = CreateDomainCred $UserNameNew $PasswordNew
    }
    else {
        $newDomainCreds = CreateDomainCred $UserName $Password
    }

    If ($NewComputerName) {
        Add-Computer -ComputerName $ComputerName -DomainName $NewDomain -Credential $newDomainCreds -Force -PassThru -NewName $NewComputerName -Restart:$Restart
    }
    Else {
        Add-Computer -ComputerName $ComputerName -DomainName $NewDomain -Credential $newDomainCreds -Force -PassThru -Restart:$Restart
    }
}
ElseIf ($Workgroup) {
    UnjoinDomain $Domain

    If ($NewComputerName) {
        Add-Computer -WorkGroupName $Workgroup -Force -PassThru -NewName $NewComputerName -Restart:$Restart
    }
    Else {
        Add-Computer -WorkGroupName $Workgroup -Force -PassThru -Restart:$Restart
    }
}
ElseIf ($NewComputerName) {
    If ($Domain) {
        $domainCreds = CreateDomainCred $UserName $Password
        Rename-Computer -NewName $NewComputerName -DomainCredential $domainCreds -Force -PassThru -Restart:$Restart
    }
    Else {
        Rename-Computer -NewName $NewComputerName -Force -PassThru -Restart:$Restart
    }
}
}
## [END] Set-ComputerIdentification ##
function Set-EnvironmentVariable {
<#

.SYNOPSIS
Updates or renames an environment variable specified by name, type, data and previous data.

.DESCRIPTION
Updates or Renames an environment variable specified by name, type, data and previrous data.

.ROLE
Administrators

#>

param(
    [Parameter(Mandatory = $True)]
    [String]
    $oldName,

    [Parameter(Mandatory = $True)]
    [String]
    $newName,

    [Parameter(Mandatory = $True)]
    [String]
    $value,

    [Parameter(Mandatory = $True)]
    [String]
    $type
)

Set-StrictMode -Version 5.0

$nameChange = $false
if ($newName -ne $oldName) {
    $nameChange = $true
}

If (-not [Environment]::GetEnvironmentVariable($oldName, $type)) {
    @{ Status = "currentMissing" }
    return
}

If ($nameChange -and [Environment]::GetEnvironmentVariable($newName, $type)) {
    @{ Status = "targetConflict" }
    return
}

If ($nameChange) {
    [Environment]::SetEnvironmentVariable($oldName, $null, $type)
    [Environment]::SetEnvironmentVariable($newName, $value, $type)
    @{ Status = "success" }
}
Else {
    [Environment]::SetEnvironmentVariable($newName, $value, $type)
    @{ Status = "success" }
}


}
## [END] Set-EnvironmentVariable ##
function Set-HyperVEnhancedSessionModeSettings {
<#

.SYNOPSIS
Sets a computer's Hyper-V Host Enhanced Session Mode settings.

.DESCRIPTION
Sets a computer's Hyper-V Host Enhanced Session Mode settings.

.ROLE
Hyper-V-Administrators

#>

param (
    [Parameter(Mandatory = $true)]
    [bool]
    $enableEnhancedSessionMode
    )

Set-StrictMode -Version 5.0
Import-Module Hyper-V

# Create arguments
$args = @{'EnableEnhancedSessionMode' = $enableEnhancedSessionMode};

Set-VMHost @args

Get-VMHost | Microsoft.PowerShell.Utility\Select-Object `
    EnableEnhancedSessionMode

}
## [END] Set-HyperVEnhancedSessionModeSettings ##
function Set-HyperVHostGeneralSettings {
<#

.SYNOPSIS
Sets a computer's Hyper-V Host General settings.

.DESCRIPTION
Sets a computer's Hyper-V Host General settings.

.ROLE
Hyper-V-Administrators

#>

param (
    [Parameter(Mandatory = $true)]
    [String]
    $virtualHardDiskPath,
    [Parameter(Mandatory = $true)]
    [String]
    $virtualMachinePath
    )

Set-StrictMode -Version 5.0
Import-Module Hyper-V

# Create arguments
$args = @{'VirtualHardDiskPath' = $virtualHardDiskPath};
$args += @{'VirtualMachinePath' = $virtualMachinePath};

Set-VMHost @args

Get-VMHost | Microsoft.PowerShell.Utility\Select-Object `
    VirtualHardDiskPath, `
    VirtualMachinePath

}
## [END] Set-HyperVHostGeneralSettings ##
function Set-HyperVHostLiveMigrationSettings {
<#

.SYNOPSIS
Sets a computer's Hyper-V Host Live Migration settings.

.DESCRIPTION
Sets a computer's Hyper-V Host Live Migration settings.

.ROLE
Hyper-V-Administrators

#>

param (
    [Parameter(Mandatory = $true)]
    [bool]
    $virtualMachineMigrationEnabled,
    [Parameter(Mandatory = $true)]
    [int]
    $maximumVirtualMachineMigrations,
    [Parameter(Mandatory = $true)]
    [int]
    $virtualMachineMigrationPerformanceOption,
    [Parameter(Mandatory = $true)]
    [int]
    $virtualMachineMigrationAuthenticationType
    )

Set-StrictMode -Version 5.0
Import-Module Hyper-V

if ($virtualMachineMigrationEnabled) {
    $isServer2012 = [Environment]::OSVersion.Version.Major -eq 6 -and [Environment]::OSVersion.Version.Minor -eq 2;
    
    Enable-VMMigration;

    # Create arguments
    $args = @{'MaximumVirtualMachineMigrations' = $maximumVirtualMachineMigrations};
    $args += @{'VirtualMachineMigrationAuthenticationType' = $virtualMachineMigrationAuthenticationType; };

    if (!$isServer2012) {
        $args += @{'VirtualMachineMigrationPerformanceOption' = $virtualMachineMigrationPerformanceOption; };
    }

    Set-VMHost @args;
} else {
    Disable-VMMigration;
}

Get-VMHost | Microsoft.PowerShell.Utility\Select-Object `
    maximumVirtualMachineMigrations, `
    VirtualMachineMigrationAuthenticationType, `
    VirtualMachineMigrationEnabled, `
    VirtualMachineMigrationPerformanceOption

}
## [END] Set-HyperVHostLiveMigrationSettings ##
function Set-HyperVHostNumaSpanningSettings {
<#

.SYNOPSIS
Sets a computer's Hyper-V Host settings.

.DESCRIPTION
Sets a computer's Hyper-V Host settings.

.ROLE
Hyper-V-Administrators

#>

param (
    [Parameter(Mandatory = $true)]
    [bool]
    $numaSpanningEnabled
    )

Set-StrictMode -Version 5.0
Import-Module Hyper-V

# Create arguments
$args = @{'NumaSpanningEnabled' = $numaSpanningEnabled};

Set-VMHost @args

Get-VMHost | Microsoft.PowerShell.Utility\Select-Object `
    NumaSpanningEnabled

}
## [END] Set-HyperVHostNumaSpanningSettings ##
function Set-HyperVHostStorageMigrationSettings {
<#

.SYNOPSIS
Sets a computer's Hyper-V Host Storage Migration settings.

.DESCRIPTION
Sets a computer's Hyper-V Host Storage Migrtion settings.

.ROLE
Hyper-V-Administrators

#>

param (
    [Parameter(Mandatory = $true)]
    [int]
    $maximumStorageMigrations
    )

Set-StrictMode -Version 5.0
Import-Module Hyper-V

# Create arguments
$args = @{'MaximumStorageMigrations' = $maximumStorageMigrations; };

Set-VMHost @args

Get-VMHost | Microsoft.PowerShell.Utility\Select-Object `
    MaximumStorageMigrations

}
## [END] Set-HyperVHostStorageMigrationSettings ##
function Set-PowerConfigurationPlan {
<#

.SYNOPSIS
Sets the new power plan

.DESCRIPTION
Sets the new power plan using powercfg when changes are saved by user

.ROLE
Administrators

#>

param(
	[Parameter(Mandatory = $true)]
	[String]
	$PlanGuid
)

$Error.clear()
$message = ""

# If executing an external command, then the following steps need to be done to produce correctly formatted errors:
# Use 2>&1 to store the error to the variable. FD 2 is stderr. FD 1 is stdout.
# Watch $Error.Count to determine the execution result.
# Concatenate the error message to a single string and print it out with Write-Error.
$result = & 'powercfg' /S $PlanGuid 2>&1

# $LASTEXITCODE here does not return error code, so we have to use $Error
if ($Error.Count -ne 0) {
	foreach($item in $result) {
		if ($item.Exception.Message.Length -gt 0) {
			$message += $item.Exception.Message
		}
	}
	$Error.Clear()
	Write-Error $message
}

}
## [END] Set-PowerConfigurationPlan ##
function Set-RemoteDesktop {
<#

.SYNOPSIS
Sets a computer's remote desktop settings.

.DESCRIPTION
Sets a computer's remote desktop settings.

.ROLE
Administrators

#>

param(
    [Parameter(Mandatory = $False)]
    [boolean]
    $AllowRemoteDesktop,

    [Parameter(Mandatory = $False)]
    [boolean]
    $AllowRemoteDesktopWithNLA,

    [Parameter(Mandatory=$False)]
    [boolean]
    $EnableRemoteApp)

    Import-Module NetSecurity
    Import-Module Microsoft.PowerShell.Management

function Set-DenyTSConnectionsValue {
    Set-Variable RegistryKey -Option Constant -Value 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server'
    Set-Variable RegistryKeyProperty -Option Constant -Value 'fDenyTSConnections'

    $KeyPropertyValue = $(if ($AllowRemoteDesktop -eq $True) { 0 } else { 1 })

    if (!(Test-Path $RegistryKey)) {
        New-Item -Path $RegistryKey -Force | Out-Null
    }

    New-ItemProperty -Path $RegistryKey -Name $RegistryKeyProperty -Value $KeyPropertyValue -PropertyType DWORD -Force | Out-Null
}

function Set-UserAuthenticationValue {
    Set-Variable RegistryKey -Option Constant -Value 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp'
    Set-Variable RegistryKeyProperty -Option Constant -Value 'UserAuthentication'

    $KeyPropertyValue = $(if ($AllowRemoteDesktopWithNLA -eq $True) { 1 } else { 0 })

    if (!(Test-Path $RegistryKey)) {
        New-Item -Path $RegistryKey -Force | Out-Null
    }

    New-ItemProperty -Path $RegistryKey -Name $RegistryKeyProperty -Value $KeyPropertyValue -PropertyType DWORD -Force | Out-Null
}

function Set-RemoteAppSetting {
    Set-Variable RegistryKey -Option Constant -Value 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Terminal Server\TSAppAllowList'
    Set-Variable RegistryKeyProperty -Option Constant -Value 'fDisabledAllowList'

    $KeyPropertyValue = $(if ($EnableRemoteApp -eq $True) { 1 } else { 0 })

    if (!(Test-Path $RegistryKey)) {
        New-Item -Path $RegistryKey -Force | Out-Null
    }

    New-ItemProperty -Path $RegistryKey -Name $RegistryKeyProperty -Value $KeyPropertyValue -PropertyType DWORD -Force | Out-Null
}

Set-DenyTSConnectionsValue
Set-UserAuthenticationValue
Set-RemoteAppSetting

Enable-NetFirewallRule -Group "@FirewallAPI.dll,-28752" -ErrorAction SilentlyContinue

}
## [END] Set-RemoteDesktop ##
function Start-DiskPerf {
<#

.SYNOPSIS
Start Disk Performance monitoring.

.DESCRIPTION
Start Disk Performance monitoring.

.ROLE
Administrators

#>

# Update the registry key at HKLM:SYSTEM\\CurrentControlSet\\Services\\Partmgr
#   EnableCounterForIoctl = DWORD 3
& diskperf -Y

}
## [END] Start-DiskPerf ##
function Stop-CimOperatingSystem {
<#

.SYNOPSIS
Shutdown Windows Operating System by using Win32_OperatingSystem provider.

.DESCRIPTION
Shutdown Windows Operating System by using Win32_OperatingSystem provider.

.ROLE
Administrators

#>
##SkipCheck=true##

Param(
)

import-module CimCmdlets

Invoke-CimMethod -Namespace root/cimv2 -ClassName Win32_OperatingSystem -MethodName Shutdown

}
## [END] Stop-CimOperatingSystem ##
function Stop-DiskPerf {
<#

.SYNOPSIS
Stop Disk Performance monitoring.

.DESCRIPTION
Stop Disk Performance monitoring.

.ROLE
Administrators

#>

# Update the registry key at HKLM:SYSTEM\\CurrentControlSet\\Services\\Partmgr
#   EnableCounterForIoctl = DWORD 1
& diskperf -N


}
## [END] Stop-DiskPerf ##
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
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUmvLq9DG1I9eytDdEqNeuYXKR
# bzigghhqMIIE2jCCA8KgAwIBAgITMwAAASMwQ40kSDyg1wAAAAABIzANBgkqhkiG
# 9w0BAQUFADB3MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4G
# A1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSEw
# HwYDVQQDExhNaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EwHhcNMTgxMDI0MjEwNzQw
# WhcNMjAwMTEwMjEwNzQwWjCByjELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hp
# bmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jw
# b3JhdGlvbjElMCMGA1UECxMcTWljcm9zb2Z0IEFtZXJpY2EgT3BlcmF0aW9uczEm
# MCQGA1UECxMdVGhhbGVzIFRTUyBFU046MUE4Ri1FM0MzLUQ2OUQxJTAjBgNVBAMT
# HE1pY3Jvc29mdCBUaW1lLVN0YW1wIFNlcnZpY2UwggEiMA0GCSqGSIb3DQEBAQUA
# A4IBDwAwggEKAoIBAQCyYt3Mdjll12pYYKRUadMqDK0tJrlPK1MhEo75C/BI1y2i
# r4HnxDl/BSAvi44lI4IKUFDS40WJPlnCHfEuwgvEUNuFrseh7bDkaWezo6W/F7i9
# PO7GAxmM139zh5p2a1XwfzqYpZE2hEucIkiOR82fg7I0s8itzwl1jWQmdAI4XAZN
# LeeXXof9Qm80uuUfEn6x/pANst2N+WKLRLnCqWLR7o6ZKqofshoYFpPukVLPsvU/
# ik/ch1kj2Ja53Zb+KHctMCk/CpN2p7fNArpLcUA3H7/mdJjlaUFYLY9yy5TBndFF
# I1kBbZEB/Z1kYVnjRsIsV8W2CCp1RCxiIkx6AhIzAgMBAAGjggEJMIIBBTAdBgNV
# HQ4EFgQU2zl1LgtoHHcQXPImRhW0WL0hxPAwHwYDVR0jBBgwFoAUIzT42VJGcArt
# QPt2+7MrsMM1sw8wVAYDVR0fBE0wSzBJoEegRYZDaHR0cDovL2NybC5taWNyb3Nv
# ZnQuY29tL3BraS9jcmwvcHJvZHVjdHMvTWljcm9zb2Z0VGltZVN0YW1wUENBLmNy
# bDBYBggrBgEFBQcBAQRMMEowSAYIKwYBBQUHMAKGPGh0dHA6Ly93d3cubWljcm9z
# b2Z0LmNvbS9wa2kvY2VydHMvTWljcm9zb2Z0VGltZVN0YW1wUENBLmNydDATBgNV
# HSUEDDAKBggrBgEFBQcDCDANBgkqhkiG9w0BAQUFAAOCAQEAauzxVwcRLuLSItcW
# CHqZFtDSR5Ci4pgS+WrhLSmhfKXQRJekrOwZR7keC/bS7lyqai7y4NK9+ZHc2+F7
# dG3Ngym/92H45M/fRYtP63ObzWY9SNXBxEaZ1l8UP/hvv3uJnPf5/92mws50THX8
# tlvKAkBMWikcuA5y4s6yYy2GBFZIypm+ChZGtswTCst+uZhG8SBeE+U342Tbb3fG
# 5MLS+xuHrvSWdRqVHrWHpPKESBTStNPzR/dJ7pgtmF7RFKAWYLcEpPhr9hjUcf9q
# SJa7D5aghTY2UNFmn3BvKBSON+Dy5nDJA81RyZ/lU9iCOG+hGdpsGsJfvKT5WxsJ
# vEwdjzCCBf8wggPnoAMCAQICEzMAAAEDXiUcmR+jHrgAAAAAAQMwDQYJKoZIhvcN
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
# KwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUfmdYXoMXuvY6Ld+djtqURRVqpmow
# QgYKKwYBBAGCNwIBDDE0MDKgFIASAE0AaQBjAHIAbwBzAG8AZgB0oRqAGGh0dHA6
# Ly93d3cubWljcm9zb2Z0LmNvbTANBgkqhkiG9w0BAQEFAASCAQAFfq4IjK/JHtEE
# xnBzG1g4Icib/VW4VjWwTQ2z/K9SRUSxitV2POcVwd8H+x/BKw4ODKnYxLdJhAgj
# 8u9fhcfNlK+4UZgmeCdjWNitppJckL9RPgZqj97vz63azXUJjk9l8P7csJDp8Are
# e5CbHle7CKDni1gGCiGoYIOC3qNaxDkUKCJrsNHRB/UNCpX3Sn9KubHCMD7H88Y2
# sKyywcWjWpOYHdGdPyNorOZdapsIuoyMvkkpvKnPNi2+/RxR95pFcok6esatdVuq
# LX7SGFB6ffKQhdMU9ogmxtfYYDkUbOECa0+sFksW0nyJ9PZGOgC/NyIJ+FoR1c8w
# KGfY68zuoYICKDCCAiQGCSqGSIb3DQEJBjGCAhUwggIRAgEBMIGOMHcxCzAJBgNV
# BAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4w
# HAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xITAfBgNVBAMTGE1pY3Jvc29m
# dCBUaW1lLVN0YW1wIFBDQQITMwAAASMwQ40kSDyg1wAAAAABIzAJBgUrDgMCGgUA
# oF0wGAYJKoZIhvcNAQkDMQsGCSqGSIb3DQEHATAcBgkqhkiG9w0BCQUxDxcNMTkw
# NDA1MjA1MTE1WjAjBgkqhkiG9w0BCQQxFgQUU+qFD5NpMQqDHv06iIADunx80jIw
# DQYJKoZIhvcNAQEFBQAEggEAPBPOH8SmIINrJ7f2qeRSu6OO6OMC8lELGR6RflIR
# gs3ZmUjjM4BjgmKdgtMEvaQxKMlF5l/kQzU1xB54OSLDYGlngWHuISg/gMOBL/87
# YRNkYrhleZNKkReCI2zI/phYDe5IFgvEx5khvEistYEBguQIaXNaIDmIxhiki3rJ
# cWD5g/bXgG6QDLWs+JPfpRAfcfhxKJH2Nf/WckwbfY5Ux5c9S5+i0zOLMgo/3pq9
# Ic/j807Q3kt6QNoqBX9NFFlrZxHGMi1tjw+tI6geXX2L8bIrX9eS5O+d3zVTJStS
# Xlkg5J0qK4+i2bpCximMM9qm8Ui0w7xLokbCDbTVrWbK9Q==
# SIG # End signature block
