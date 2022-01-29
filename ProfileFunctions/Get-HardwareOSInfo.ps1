function Get-HardwareOSInfo {

    <#
.SYNOPSIS
List all properties and values of the CIM_SoftwareElement class in WMI's root/CIMV2 namespace

.DESCRIPTION
This PowerShell 7 script was generated using WMIGen (formerly known as WMI Code Generator), Version 10.0.15.2.
It queries WMI to list all properties and values of the CIM_SoftwareElement class in the root/CIMV2 namepace, for the local or a remote computer.

.PARAMETER Computer
The optional name of a remote computer to be queried.
If not specified, the local computer will be queried.

.LINK
WMIGen multi-language code generator by Rob van der Woude
https://www.robvanderwoude.com/wmigen.php
#>

    [CmdletBinding()]
    param (
        [Parameter()]
        [string[]]
        $ComputerName
    )

    begin {

    }

    process {
        foreach ( $Computer in $ComputerName ) {
            Get-CimInstance -ClassName CIM_LogicalDevice -Namespace "root/CIMV2" -ComputerName $Computer -Property * -ErrorAction Stop
            try {
                $properties = @{
                    Availability                = $Computer.Availability
                    Caption                     = $Computer.Caption
                    ConfigManagerErrorCode      = $Computer.ConfigManagerErrorCode
                    ConfigManagerUserConfig     = $Computer.ConfigManagerUserConfig
                    CreationClassName           = $Computer.CreationClassName
                    Description                 = $Computer.Description
                    DeviceID                    = $Computer.DeviceID
                    DMABufferSize               = $Computer.DMABufferSize
                    ErrorCleared                = $Computer.ErrorCleared
                    ErrorDescription            = $Computer.ErrorDescription
                    InstallDate                 = $Computer.InstallDate
                    LastErrorCode               = $Computer.LastErrorCode
                    Manufacturer                = $Computer.Manufacturer
                    MPU401Address               = $Computer.MPU401Address
                    Name                        = $Computer.Name
                    PNPDeviceID                 = $Computer.PNPDeviceID
                    PowerManagementCapabilities = $Computer.PowerManagementCapabilities
                    PowerManagementSupported    = $Computer.PowerManagementSupported
                    ProductName                 = $Computer.ProductName
                    PSComputerName              = $Computer.PSComputerName
                    Status                      = $Computer.Status
                    StatusInfo                  = $Computer.StatusInfo
                    SystemCreationClassName     = $Computer.SystemCreationClassName
                    SystemName                  = $Computer.SystemName
                    PSStatus                    = $Computer.PSStatus
                }
        
            }
            catch {
                Write-Error $_       
            }
            finally {
                $obj = New-Object -TypeName psobject -Property $properties
                Write-Output -InputObject $obj
            }
        }
    }
        
    end {
        
    }
    
}
