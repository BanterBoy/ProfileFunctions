function Get-StorePrinter {

    <#
    Look for MFP printer Properties
    Look for MFP Pre Printed/MFP Plain
    Configure Port
    Change the Printer Name or IP address to the IP address of the Printer example above
    And untick SNMP Status Enabled
    #>

    [CmdletBinding()]
    param (
        [Parameter()]
        [string[]] $ComputerName,
        [Parameter()]
        [string] $PrinterName,
        [Parameter()]
        [string] $PrinterPort,
        [Parameter()]
        [string] $SNMPStatus,
        [Parameter()]
        [string] $PrinterIP
    )
    
    foreach ($Computer in $ComputerName ) {
    Get-Printer -ComputerName $Computer -Full | Where-Object -Property Name -Like $PrinterName
    }

}

<#
$StoreComputers = Get-ADComputer -Filter { Name -like '0084*' } -Properties *
$StorePrinters = foreach ($Computer in $StoreComputers) {
$Test = Get-PrintSpooler -ComputerName $Computer.Name
if ($Test.Status -eq 'Stopped') {
    Enable-PrintSpooler -ComputerName $Computer.Name
}
}
    
}
Get-Printer -ComputerName $Computer.Name | Where-Object Name -Like MFP*
}
$StorePrinters
#>
