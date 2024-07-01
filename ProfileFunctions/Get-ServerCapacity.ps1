<#
.SYNOPSIS
Retrieves capacity information for a remote server.

.DESCRIPTION
The Get-ServerCapacity function retrieves various capacity information for a remote server, including disk space, CPU usage, memory usage, network configuration, operating system details, uptime, and current user.

.PARAMETER ComputerName
Specifies the name of the computer for which to retrieve information. If not specified, the local computer is used.

.PARAMETER Credential
Specifies the credentials to use when connecting to the remote computer.

.OUTPUTS
System.Management.Automation.PSCustomObject
The function returns a custom object with the following properties:
- ComputerName: The name of the computer.
- DeviceID: The ID of the logical disk.
- Size (GB): The size of the logical disk in gigabytes.
- Freespace (GB): The amount of free space on the logical disk in gigabytes.
- CPUUsage(%): The average CPU usage percentage.
- TotalMemory(GB): The total memory size in gigabytes.
- FreeMemory(GB): The amount of free memory in gigabytes.
- OperatingSystem: The caption of the operating system.
- OSVersion: The version of the operating system.
- OSArchitecture: The architecture of the operating system.
- IPAddress: The IP address of the network adapter.
- SubnetMask: The subnet mask of the network adapter.
- DefaultGateway: The default gateway of the network adapter.
- DNSServers: The DNS server search order.
- Uptime: The uptime of the computer.
- CurrentUser: The currently logged-in user.

.EXAMPLE
Get-ServerCapacity -ComputerName 'Server01'
Retrieves capacity information for the server named 'Server01'.

.EXAMPLE
Get-ServerCapacity -ComputerName 'Server01', 'Server02' -Credential $cred
Retrieves capacity information for the servers named 'Server01' and 'Server02' using the specified credentials.

.LINK
https://github.com/BanterBoy
The GitHub repository for more information and updates.

#>
function Get-ServerCapacity {
    [CmdletBinding(DefaultParameterSetName = 'Default',
        supportsShouldProcess = $false,
        HelpUri = 'https://github.com/BanterBoy'
    )]
    [OutputType([PSObject])]
    param
    (
        [Parameter(ParameterSetName = 'Default',
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Enter the name of the computer for which to retrieve information.'
        )]
        [Alias('cn')]
        [string[]]$ComputerName = $env:COMPUTERNAME,
        
        [Parameter(ParameterSetName = 'Default',
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Enter the credentials to use when connecting to the remote computer.'
        )]
        [Alias('cred')]
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential
    )
    PROCESS {
        foreach ($Computer in $ComputerName) {
            $diskInfo = Get-CimInstance -ClassName Win32_LogicalDisk -ComputerName $Computer -Filter DriveType=3 | Select-Object DeviceID, @{'Name'='Size (GB)'; 'Expression'={[string]::Format('{0:N0}',[math]::truncate($_.size / 1GB))}}, @{'Name'='Freespace (GB)'; 'Expression'={[string]::Format('{0:N0}',[math]::truncate($_.freespace / 1GB))}}
            $cpuUsage = Get-CimInstance -ClassName Win32_Processor -ComputerName $Computer | Measure-Object -Property LoadPercentage -Average | Select-Object Average
            $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem -ComputerName $Computer
            $memoryInfo = $osInfo | Select-Object @{Name = "TotalMemory(GB)"; Expression = {[Math]::Round(($_.TotalVisibleMemorySize / 1MB), 2)}}, @{Name = "FreeMemory(GB)"; Expression = {[Math]::Round(($_.FreePhysicalMemory / 1MB), 2)}}
            $networkInfo = Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration -ComputerName $Computer | Where-Object { $null -ne $_.IPAddress } | Select-Object -First 1 IPAddress, SubnetMask, DefaultIPGateway, DNSServerSearchOrder
            $uptime = (Get-Date) - $osInfo.LastBootUpTime
            $currentUser = Get-CimInstance -ClassName Win32_ComputerSystem -ComputerName $Computer | Select-Object -ExpandProperty UserName

            $output = [PSCustomObject]@{
                'ComputerName' = $Computer
                'DeviceID' = $diskInfo.DeviceID
                'Size (GB)' = $diskInfo.'Size (GB)'
                'Freespace (GB)' = $diskInfo.'Freespace (GB)'
                'CPUUsage(%)' = $cpuUsage.Average
                'TotalMemory(GB)' = $memoryInfo.'TotalMemory(GB)'
                'FreeMemory(GB)' = $memoryInfo.'FreeMemory(GB)'
                'OperatingSystem' = $osInfo.Caption
                'OSVersion' = $osInfo.Version
                'OSArchitecture' = $osInfo.OSArchitecture
                'IPAddress' = $networkInfo.IPAddress
                'SubnetMask' = $networkInfo.SubnetMask
                'DefaultGateway' = $networkInfo.DefaultIPGateway
                'DNSServers' = $networkInfo.DNSServerSearchOrder
                'Uptime' = $uptime
                'CurrentUser' = $currentUser
            }
            $output
        }
    }
}
