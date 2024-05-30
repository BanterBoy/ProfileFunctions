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
            $networkInfo = Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration -ComputerName $Computer | Where-Object { $_.IPAddress -ne $null } | Select-Object -First 1 IPAddress, SubnetMask, DefaultIPGateway, DNSServerSearchOrder
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
