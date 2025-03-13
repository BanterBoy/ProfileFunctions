<#
    .SYNOPSIS
        Disables the Print Spooler service on one or more remote computers.
    
    .DESCRIPTION
        The Disable-PrintSpooler function stops and disables the Print Spooler service on one or more remote computers.
        This function is useful for administrators who need to disable printing capabilities on remote systems for security or maintenance purposes.
    
    .PARAMETER ComputerName
        Specifies the name of the computer(s) on which to disable the Print Spooler service.
        Supports IP address, computer name, or fully qualified domain name (FQDN).
    
    .EXAMPLE
        PS C:\> Disable-PrintSpooler -ComputerName 'COMPUTER1'
    
        This example stops and disables the Print Spooler service on the computer named COMPUTER1.
    
    .EXAMPLE
        PS C:\> 'COMPUTER1', 'COMPUTER2' | Disable-PrintSpooler
    
        This example stops and disables the Print Spooler service on the computers named COMPUTER1 and COMPUTER2 by piping the computer names to the function.
    
    .EXAMPLE
        PS C:\> Get-ADComputer -Filter { OperatingSystem -like '*Windows*' } | ForEach-Object { Disable-PrintSpooler -ComputerName $_.Name }
    
        This example stops and disables the Print Spooler service on all computers in Active Directory with an operating system that matches the pattern '*Windows*'.
    
    .OUTPUTS
        System.String
            Outputs a string indicating the status of the Print Spooler service for each computer.
    
    .NOTES
        Author:     Luke Leigh
        Website:    https://scripts.lukeleigh.com/
        LinkedIn:   https://www.linkedin.com/in/lukeleigh/
        GitHub:     https://github.com/BanterBoy/
        GitHubGist: https://gist.github.com/BanterBoy
        Date:       01/01/2022
        Version:    1.0
    
    .INPUTS
        System.String
            You can pipe computer names to this function.
    
    .LINK
        https://scripts.lukeleigh.com
        Get-Service
        Stop-Service
        Set-Service
        Invoke-Command
    
    .REMARKS
        Ensure that you have the necessary permissions to stop and disable services on the remote computers.
#>

function Disable-PrintSpooler
{
    [CmdletBinding(DefaultParameterSetName = 'Default',
                   HelpUri = 'https://github.com/BanterBoy')]
    [OutputType([string])]
    param
    (
        [Parameter(ParameterSetName = 'Default',
                   Mandatory = $true,
                   ValueFromPipeline = $true,
                   ValueFromPipelineByPropertyName = $true,
                   HelpMessage = 'Enter computer name or pipe input')]
        [Alias('cn')]
        [string[]]$ComputerName
    )
    BEGIN
    {
    }
    PROCESS
    {
        foreach ($Computer in $ComputerName)
        {
            Invoke-Command -ComputerName $Computer -ScriptBlock {
                Get-Service -Name Spooler | Stop-Service
                Set-Service -Name Spooler -StartupType Disabled
            }
            Write-Output "Print Spooler service disabled on $Computer"
        }
    }
    END
    {
    }
}