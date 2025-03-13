<#
    .SYNOPSIS
        Disables Remote Desktop Protocol (RDP) on remote computers.
    
    .DESCRIPTION
        The Disable-RDPRemotely function disables Remote Desktop Protocol (RDP) on one or more remote computers. It uses either CIM or WMI to perform the operation, depending on the version of PowerShell.
        This function is useful for administrators who need to disable RDP access on remote systems for security or maintenance purposes.
    
    .PARAMETER ComputerName
        Specifies the name of the computer(s) on which to disable RDP. This parameter accepts an array of strings, allowing you to specify multiple computer names.
        Supports IP address, computer name, or fully qualified domain name (FQDN).
    
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
        - If the computer is running PowerShell version 6 or later, CIM is used to disable RDP. Otherwise, WMI is used.
        - For more information, visit the help URI: http://scripts.lukeleigh.com/
    
    .EXAMPLE
        PS C:\> Disable-RDPRemotely -ComputerName 'Server01', 'Server02'
    
        This example stops and disables RDP on the computers named 'Server01' and 'Server02'.
    
    .EXAMPLE
        PS C:\> 'Desktop01', 'Desktop02' | Disable-RDPRemotely
    
        This example stops and disables RDP on the computers named 'Desktop01' and 'Desktop02' using pipeline input.
    
    .LINK
        https://scripts.lukeleigh.com
        Get-CimInstance
        Invoke-CimMethod
        Get-WmiObject
    
    .REMARKS
        Ensure that you have the necessary permissions to disable RDP on the remote computers.
#>

function Disable-RDPRemotely {
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
        if ($PSCmdlet.ShouldProcess("$Computer", "Disable RDP")) {
            try {
                # Disable RDP using CIM
                if ($PSVersionTable.PSVersion.Major -ge 6) {
                    $Win32TerminalServiceSettings = Get-CimInstance -Namespace root/cimv2/TerminalServices -ClassName Win32_TerminalServiceSetting -ComputerName $Computer
                    $Win32TerminalServiceSettings | Invoke-CimMethod -MethodName SetAllowTSConnections -Arguments @{AllowTSConnections = 0; ModifyFirewallException = 0 } -ComputerName $Computer
                }
                # Disable RDP using WMI
                else {
                    $tsobj = Get-WmiObject -Class Win32_TerminalServiceSetting -Namespace Root\CimV2\TerminalServices -ComputerName $Computer
                    $tsobj.SetAllowTSConnections(0, 0)
                }
                Write-Output "RDP disabled on $Computer"
            }
            catch {
                Write-Error "Failed to disable RDP on &{$Computer}: $_"
            }
        }
    }
}