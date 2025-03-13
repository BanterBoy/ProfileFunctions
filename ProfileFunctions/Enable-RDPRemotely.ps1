<#
    .SYNOPSIS
    Enables Remote Desktop Protocol (RDP) on one or more remote computers.

    .DESCRIPTION
    The Enable-RDPRemotely function enables Remote Desktop Protocol (RDP) on one or more remote computers. It uses CIM (Common Information Model) to enable RDP on computers running PowerShell version 6 or later, and WMI (Windows Management Instrumentation) for older versions of PowerShell.
    This function is useful for administrators who need to enable RDP access on remote systems for operational purposes.
    
    .PARAMETER ComputerName
    Specifies the name of the computer(s) on which to enable RDP. This parameter accepts an array of strings, allowing you to specify multiple computer names.
    Supports IP address, computer name, or fully qualified domain name (FQDN).
    
    .EXAMPLE
    PS C:\> Enable-RDPRemotely -ComputerName 'Computer01', 'Computer02'
    
    This example enables RDP on the computers named 'Computer01' and 'Computer02'.
    
    .EXAMPLE
    PS C:\> 'Computer01', 'Computer02' | Enable-RDPRemotely
    
    This example enables RDP on the computers named 'Computer01' and 'Computer02' using pipeline input.
    
    .EXAMPLE
    PS C:\> Get-ADComputer -Filter { OperatingSystem -like '*Windows*' } | ForEach-Object { Enable-RDPRemotely -ComputerName $_.Name }
    
    This example enables RDP on all computers in Active Directory with an operating system that matches the pattern '*Windows*'.
    
    .INPUTS
    System.String
    You can pipe computer names to this function.
    
    .OUTPUTS
    System.String
        The function returns a string indicating the success or failure of the operation.

    .NOTES
    Author:     Luke Leigh
    Website:    https://scripts.lukeleigh.com/
    LinkedIn:   https://www.linkedin.com/in/lukeleigh/
    GitHub:     https://github.com/BanterBoy/
    GitHubGist: https://gist.github.com/BanterBoy
    Date:       01/01/2022
    Version:    1.0
    - This function requires administrative privileges on the remote computers.
    - If the computer is running PowerShell version 6 or later, CIM is used to enable RDP. Otherwise, WMI is used.
    - For more information, visit the help URI: http://scripts.lukeleigh.com/
        
    .LINK
    https://scripts.lukeleigh.com
    Get-CimInstance
    Invoke-CimMethod
    Get-WmiObject
        
    .REMARKS
    Ensure that you have the necessary permissions to enable RDP on the remote computers.
#>

function Enable-RDPRemotely {
    [CmdletBinding(DefaultParameterSetName = 'Default',
        ConfirmImpact = 'Medium',
        SupportsShouldProcess = $true,
        HelpUri = 'http://scripts.lukeleigh.com/')]
    [OutputType([string], ParameterSetName = 'Default')]

    param
    (
        [Parameter(ParameterSetName = 'Default',
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $true,
            HelpMessage = 'Enter the Name of the computer you would like to connect to.')]
        [Alias('cn')]
        [string[]]$ComputerName
    )

    foreach ($Computer in $ComputerName) {
        if ($PSCmdlet.ShouldProcess("$Computer", "Enable RDP")) {
            try {
                # Enable RDP using CIM
                if ($PSVersionTable.PSVersion.Major -ge 6) {
                    $Win32TerminalServiceSettings = Get-CimInstance -Namespace root/cimv2/TerminalServices -ClassName Win32_TerminalServiceSetting -ComputerName $Computer
                    $Win32TerminalServiceSettings | Invoke-CimMethod -MethodName SetAllowTSConnections -Arguments @{AllowTSConnections = 1; ModifyFirewallException = 1 } -ComputerName $Computer
                }
                # Enable RDP using WMI
                else {
                    $tsobj = Get-WmiObject -Class Win32_TerminalServiceSetting -Namespace Root\CimV2\TerminalServices -ComputerName $Computer
                    $tsobj.SetAllowTSConnections(1, 1)
                }
                Write-Output "RDP enabled on $Computer"
            }
            catch {
                Write-Error "Failed to enable RDP on ${$Computer}: $_"
            }
        }
    }
}