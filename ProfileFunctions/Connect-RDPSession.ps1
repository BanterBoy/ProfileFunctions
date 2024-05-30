<#
.SYNOPSIS
Connects to remote computers using Remote Desktop Protocol (RDP).

.DESCRIPTION
The Connect-RDPSession function allows you to connect to one or more remote computers using the Remote Desktop Protocol (RDP). It starts an RDP session for each specified computer.

.PARAMETER ComputerName
Specifies the name or IP address of the remote computer(s) to connect to. You can provide multiple computer names separated by commas.

.EXAMPLE
Connect-RDPSession -ComputerName "Server01"
Connects to a single remote computer named "Server01" using RDP.

.EXAMPLE
Connect-RDPSession -ComputerName "Server01", "Server02", "Server03"
Connects to multiple remote computers named "Server01", "Server02", and "Server03" using RDP.

#>
function Connect-RDPSession {
    [CmdletBinding(DefaultParameterSetName = 'Default',
        PositionalBinding = $true)]
    [OutputType([string], ParameterSetName = 'Default')]
    param
    (
        [Parameter(ParameterSetName = 'Default',
            Mandatory = $true,
            Position = 1)]
        [string[]]$ComputerName
    )

    foreach ($Computer in $ComputerName) {
            Start-Process "$env:windir\system32\mstsc.exe" -ArgumentList "/v:$Computer"
    }
}
