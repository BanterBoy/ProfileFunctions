<#
.SYNOPSIS
    Retrieves detailed information about one or more servers.

.DESCRIPTION
    The Get-ServerInfo function retrieves detailed information about one or more servers, including IP addresses, operating system, running services, scheduled tasks, scheduled scripts, running processes, and listening ports.

.PARAMETER ComputerName
    Specifies the servers to retrieve information from. This parameter is mandatory and accepts pipeline input.

.INPUTS
    System.String. You can pipe strings representing server names to this function.

.OUTPUTS
    System.Object. Returns a custom object with server details.

.EXAMPLE
    Get-ServerInfo -ComputerName "Server1", "Server2"
    Retrieves detailed information about Server1 and Server2.

.EXAMPLE
    "Server1", "Server2" | Get-ServerInfo
    Retrieves detailed information about Server1 and Server2 using pipeline input.

.LINK
    http://scripts.lukeleigh.com/
#>
function Get-ServerInfo {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string[]]$ComputerName
    )

    process {
        $results = @()

        foreach ($computer in $ComputerName) {
            Write-Verbose "Processing computer: $computer"

            $serverInfo = [PSCustomObject]@{
                IPAddress    = @()
                ComputerName = $computer
                Type         = if ($computer -eq $env:COMPUTERNAME) { "Local" } else { "Remote" }
                OS           = ""
                Services     = @()
                Tasks        = @()
                Scripts      = @()
                Processes    = @()
                Ports        = @()
            }

            try {
                $session = New-CimSession -ComputerName $computer

                # IP Addresses
                $ipAddresses = Get-CimInstance -CimSession $session -ClassName Win32_NetworkAdapterConfiguration | Where-Object { $_.IPAddress }
                $serverInfo.IPAddress = $ipAddresses.IPAddress

                # OS
                $os = Get-CimInstance -CimSession $session -ClassName Win32_OperatingSystem
                $serverInfo.OS = $os.Caption

                # Processes
                $processes = Get-ProcessStatus -ProcessName '*' -ComputerName $computer
                if ($processes) {
                    $serverInfo.Processes = $processes | Select-Object -ExpandProperty ProcessName
                }
                else {
                    Write-Verbose "No processes found or 'ProcessName' property is missing."
                }

                # Services
                $services = Get-ServiceStatus -ComputerName $computer
                if ($services) {
                    $serverInfo.Services = $services | Select-Object -ExpandProperty DisplayName
                }
                else {
                    Write-Verbose "No services found or 'DisplayName' property is missing."
                }

                # Tasks
                $tasks = Get-ScheduledTasks -ComputerName $computer
                if ($tasks) {
                    $serverInfo.Tasks = $tasks | Select-Object -ExpandProperty TaskName
                }
                else {
                    Write-Verbose "No tasks found or 'TaskName' property is missing."
                }

                # Scripts
                $scripts = Get-ScheduledScripts -ComputerName $computer
                if ($scripts) {
                    $serverInfo.Scripts = $scripts | Select-Object -ExpandProperty TaskName
                }
                else {
                    Write-Verbose "No scripts found or 'TaskName' property is missing."
                }

                # Ports
                $ports = Get-NetTCPConnection -CimSession $session | Where-Object { $_.State -eq 'Listen' -and $_.LocalAddress -eq '::' }
                if ($ports) {
                    $serverInfo.Ports = $ports | Select-Object -ExpandProperty LocalPort
                }
                else {
                    Write-Verbose "No ports found."
                }

                $results += $serverInfo

            }
            catch {
                Write-Error "Error processing computer {$computer}: $_"
            }
        }

        $results
    }
}

# Example usage
# Get-ServerInfo -ComputerName EXCHANGE01 -Verbose
