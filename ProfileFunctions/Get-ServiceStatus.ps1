<#
.SYNOPSIS
    Retrieves the status of specified services on one or more computers, with options to filter by service name, display name, and various predefined service categories.

.DESCRIPTION
    The Get-ServiceStatus function retrieves the status of specified services on one or more remote or local computers. This function allows administrators to monitor and check the status of critical services across multiple systems efficiently. You can specify the computer name(s) and filter the services by their name or display name. Additionally, the function provides several switches to quickly check predefined groups of services, such as agent services, DNS, DHCP, file services, Exchange, Windows Update, Active Directory, print spooler, IIS, SQL Server, Remote Desktop, and Hyper-V services.

    The function's parameters include:

    -ComputerName: Specifies the name of the computer or computers to check. This is a mandatory parameter.
    -ServiceName: Filters the services by their service name.
    -DisplayName: Filters the services by their display name.
    -SearchByDisplayName: Indicates whether to search services based on their display name.
    -Agents: Checks default agent services if no specific service name is provided.
    -DNS: Checks default DNS services if no specific service name is provided.
    -DHCP: Checks default DHCP services if no specific service name is provided.
    -FileServices: Checks default file services if no specific service name is provided.
    -Exchange: Checks default Exchange services if no specific service name is provided.
    -WindowsUpdate: Checks default Windows Update services if no specific service name is provided.
    -ActiveDirectory: Checks default Active Directory services if no specific service name is provided.
    -PrintSpooler: Checks default print spooler services if no specific service name is provided.
    -IIS: Checks default IIS services if no specific service name is provided.
    -SQLServer: Checks default SQL Server services if no specific service name is provided.
    -RemoteDesktop: Checks default Remote Desktop services if no specific service name is provided.
    -HyperV: Checks default Hyper-V services if no specific service name is provided.

    The function outputs detailed service status information, including the service name, status, display name, start mode, and other relevant properties. This helps administrators quickly assess and respond to service status issues across their network.

.PARAMETER ComputerName
    Specifies the name of the computer or computers on which to check the service status. This parameter is mandatory.

.PARAMETER ServiceName
    Specifies the name of the service or services to check. This parameter is optional.

.PARAMETER DisplayName
    Specifies the display name of the service or services to check. This parameter is optional.

.PARAMETER SearchByDisplayName
    Indicates whether to search for services based on their display name. If this switch is used, the DisplayName parameter will be used to filter the services.

.PARAMETER Agents
    Specifies that agent services should be checked. If this switch is used and the ServiceName parameter is not provided, the default agent services will be checked.

.PARAMETER DNS
    Specifies that DNS services should be checked. If this switch is used and the ServiceName parameter is not provided, the default DNS services will be checked.

.PARAMETER DHCP
    Specifies that DHCP services should be checked. If this switch is used and the ServiceName parameter is not provided, the default DHCP services will be checked.

.PARAMETER FileServices
    Specifies that file services should be checked. If this switch is used and the ServiceName parameter is not provided, the default file services will be checked.

.PARAMETER Exchange
    Specifies that Exchange services should be checked. If this switch is used and the ServiceName parameter is not provided, the default Exchange services will be checked.

.PARAMETER WindowsUpdate
    Specifies that Windows Update services should be checked. If this switch is used and the ServiceName parameter is not provided, the default Windows Update services will be checked.

.PARAMETER ActiveDirectory
    Specifies that Active Directory services should be checked. If this switch is used and the ServiceName parameter is not provided, the default Active Directory services will be checked.

.PARAMETER PrintSpooler
    Specifies that print spooler services should be checked. If this switch is used and the ServiceName parameter is not provided, the default print spooler services will be checked.

.PARAMETER IIS
    Specifies that IIS (Internet Information Services) services should be checked. If this switch is used and the ServiceName parameter is not provided, the default IIS services will be checked.

.PARAMETER SQLServer
    Specifies that SQL Server services should be checked. If this switch is used and the ServiceName parameter is not provided, the default SQL Server services will be checked.

.PARAMETER RemoteDesktop
    Specifies that Remote Desktop services should be checked. If this switch is used and the ServiceName parameter is not provided, the default Remote Desktop services will be checked.

.PARAMETER HyperV
    Specifies that Hyper-V services should be checked. If this switch is used and the ServiceName parameter is not provided, the default Hyper-V services will be checked.

.OUTPUTS
    The function outputs a collection of objects representing the service status. The object properties include PSComputerName, ServiceName, Status, DisplayName, StartMode, AcceptPause, AcceptStop, Caption, CheckPoint, CreationClassName, DelayedAutoStart, Description, DesktopInteract, ErrorControl, ExitCode, InstallDate, Name, PathName, ProcessId, ServiceSpecificExitCode, ServiceType, Started, StartName, State, SystemCreationClassName, TagId, and WaitHint.

.EXAMPLE
    Get-ServiceStatus -ComputerName @("Server01", "Server02") -Agents | Format-Table -AutoSize

    Retrieves and formats the status of agent services on the specified computers.

.EXAMPLE
    Get-ServiceStatus -ComputerName @("Server01", "Server02") -ServiceName "*ir_agent*" | Format-Table -AutoSize

    Retrieves and formats the status of services matching the name pattern "*ir_agent*" on the specified computers.

.EXAMPLE
    Get-ServiceStatus -ComputerName @("Server01", "Server02") -DisplayName "*Cisco*" -SearchByDisplayName | Format-Table -AutoSize

    Retrieves and formats the status of services with display names matching the pattern "*Cisco*" on the specified computers.
#>

function Get-ServiceStatus {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]$ComputerName,

        [Parameter(Mandatory = $false)]
        [string[]]$ServiceName,

        [Parameter(Mandatory = $false)]
        [string[]]$DisplayName,

        [Parameter(Mandatory = $false)]
        [switch]$SearchByDisplayName,

        [Parameter(Mandatory = $false)]
        [switch]$Agents,

        [Parameter(Mandatory = $false)]
        [switch]$DNS,

        [Parameter(Mandatory = $false)]
        [switch]$DHCP,

        [Parameter(Mandatory = $false)]
        [switch]$FileServices,

        [Parameter(Mandatory = $false)]
        [switch]$Exchange,

        [Parameter(Mandatory = $false)]
        [switch]$WindowsUpdate,

        [Parameter(Mandatory = $false)]
        [switch]$ActiveDirectory,

        [Parameter(Mandatory = $false)]
        [switch]$PrintSpooler,

        [Parameter(Mandatory = $false)]
        [switch]$IIS,

        [Parameter(Mandatory = $false)]
        [switch]$SQLServer,

        [Parameter(Mandatory = $false)]
        [switch]$RemoteDesktop,

        [Parameter(Mandatory = $false)]
        [switch]$HyperV
    )

    BEGIN {
        # Default services to check if respective switches are provided and ServiceName or DisplayName is not
        $defaultAgentsServices = @(
            "ir_agent",
            "NinjaRMMAgent",
            "csc_vpnagent",
            "csc_umbrellaagent",
            "csc_swgagent",
            "CiscoAMP",
            "CiscoSCMS"
        )

        $defaultDNSServices = @(
            "DNS",
            "Dnscache"
        )

        $defaultDHCPServices = @(
            "DHCPServer",
            "Dhcp"
        )

        $defaultFileServices = @(
            "LanmanServer",
            "LanmanWorkstation"
        )

        $defaultExchangeServices = @(
            "MSExchangeADTopology",
            "MSExchangeIS",
            "MSExchangeMailboxAssistants",
            "MSExchangeTransport",
            "MSExchangeTransportLogSearch",
            "MSExchangeServiceHost",
            "MSExchangeMailSubmission"
        )

        $defaultWindowsUpdateServices = @(
            "wuauserv",
            "UsoSvc"
        )

        $defaultADServices = @(
            "NTDS",
            "DNS",
            "kdc",
            "Netlogon",
            "W32Time"
        )

        $defaultPrintSpoolerServices = @(
            "Spooler"
        )

        $defaultIISServices = @(
            "W3SVC",
            "WAS",
            "IISADMIN"
        )

        $defaultSQLServerServices = @(
            "MSSQLSERVER",
            "SQLSERVERAGENT"
        )

        $defaultRemoteDesktopServices = @(
            "TermService",
            "SessionEnv",
            "UmRdpService"
        )

        $defaultHyperVServices = @(
            "vmms",
            "vmcompute",
            "VmSwitch"
        )

        # Determine services to check based on provided parameters
        if ($SearchByDisplayName) {
            $servicesToCheck = if ($DisplayName) { $DisplayName } else { @() }
        } elseif ($Agents -and -not $ServiceName) {
            $servicesToCheck = $defaultAgentsServices
        } elseif ($DNS -and -not $ServiceName) {
            $servicesToCheck = $defaultDNSServices
        } elseif ($DHCP -and -not $ServiceName) {
            $servicesToCheck = $defaultDHCPServices
        } elseif ($FileServices -and -not $ServiceName) {
            $servicesToCheck = $defaultFileServices
        } elseif ($Exchange -and -not $ServiceName) {
            $servicesToCheck = $defaultExchangeServices
        } elseif ($WindowsUpdate -and -not $ServiceName) {
            $servicesToCheck = $defaultWindowsUpdateServices
        } elseif ($ActiveDirectory -and -not $ServiceName) {
            $servicesToCheck = $defaultADServices
        } elseif ($PrintSpooler -and -not $ServiceName) {
            $servicesToCheck = $defaultPrintSpoolerServices
        } elseif ($IIS -and -not $ServiceName) {
            $servicesToCheck = $defaultIISServices
        } elseif ($SQLServer -and -not $ServiceName) {
            $servicesToCheck = $defaultSQLServerServices
        } elseif ($RemoteDesktop -and -not $ServiceName) {
            $servicesToCheck = $defaultRemoteDesktopServices
        } elseif ($HyperV -and -not $ServiceName) {
            $servicesToCheck = $defaultHyperVServices
        } else {
            $servicesToCheck = if ($ServiceName) { $ServiceName } else { @() }
        }

        # Output collection
        $results = @()
    }

    PROCESS {
        foreach ($computer in $ComputerName) {
            foreach ($servicePattern in $servicesToCheck) {
                try {
                    if ($SearchByDisplayName) {
                        $filter = "DisplayName LIKE '$servicePattern'".Replace('*', '%')
                    } else {
                        $filter = "Name LIKE '$servicePattern'".Replace('*', '%')
                    }

                    $serviceStatuses = Get-CimInstance -ComputerName $computer -ClassName Win32_Service -Filter $filter -ErrorAction Stop

                    if ($serviceStatuses) {
                        foreach ($serviceStatus in $serviceStatuses) {
                            $properties = @{
                                PSComputerName          = $computer
                                ServiceName             = $serviceStatus.Name
                                Status                  = if ($serviceStatus.Started) { "Running" } else { "Stopped" }
                                DisplayName             = $serviceStatus.DisplayName
                                StartMode               = $serviceStatus.StartMode
                                AcceptPause             = $serviceStatus.AcceptPause
                                AcceptStop              = $serviceStatus.AcceptStop
                                Caption                 = $serviceStatus.Caption
                                CheckPoint              = $serviceStatus.CheckPoint
                                CreationClassName       = $serviceStatus.CreationClassName
                                DelayedAutoStart        = $serviceStatus.DelayedAutoStart
                                Description             = $serviceStatus.Description
                                DesktopInteract         = $serviceStatus.DesktopInteract
                                ErrorControl            = $serviceStatus.ErrorControl
                                ExitCode                = $serviceStatus.ExitCode
                                InstallDate             = $serviceStatus.InstallDate
                                Name                    = $serviceStatus.Name
                                PathName                = $serviceStatus.PathName
                                ProcessId               = $serviceStatus.ProcessId
                                ServiceSpecificExitCode = $serviceStatus.ServiceSpecificExitCode
                                ServiceType             = $serviceStatus.ServiceType
                                Started                 = $serviceStatus.Started
                                StartName               = $serviceStatus.StartName
                                State                   = $serviceStatus.State
                                SystemCreationClassName = $serviceStatus.SystemCreationClassName
                                TagId                   = $serviceStatus.TagId
                                WaitHint                = $serviceStatus.WaitHint
                            }
                            $obj = New-Object -TypeName PSObject -Property $properties
                            $obj.PSObject.TypeNames.Insert(0, 'Selected.Microsoft.Management.Infrastructure.CimInstance#root/cimv2/Win32_Service')
                            Write-Output $obj
                        }
                    }
                } catch [Microsoft.Management.Infrastructure.CimException] {
                    if ($_.Message -match "Not found" -or $_.Message -match "No instances found") {
                        Write-Verbose "Service matching pattern '$servicePattern' does not exist on $($computer)"
                    } else {
                        Write-Verbose "Error checking service matching pattern '$servicePattern' on $($computer): $_"
                    }
                } catch {
                    Write-Verbose "Unexpected error checking service matching pattern '$servicePattern' on $($computer): $_"
                }
            }
        }
    }

    END {
        # Output all results at once
        $results
    }
}

Update-FormatData -PrependPath "$PSScriptRoot\GetServiceStatus.Format.ps1xml"
