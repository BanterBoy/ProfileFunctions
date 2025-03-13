<#
    .SYNOPSIS
        Connect-PSExec - Spawn PSEXEC and launches a PSEXEC PowerShell or Command Console session to a remote computer.
    
    .DESCRIPTION
        The Connect-PSExec function spawns PSEXEC and launches a PSEXEC PowerShell or Command Console session to a remote computer. 
        It sets the remote computer's ExecutionPolicy to Unrestricted in the PowerShell session.
        This function is useful for administrators who need to remotely manage and troubleshoot computers using PSEXEC.
    
    .PARAMETER ComputerName
        This parameter accepts the name of the computer you would like to connect to.
        Supports IP address, computer name, or fully qualified domain name (FQDN).
    
    .PARAMETER Prompt
        This parameter allows you to select which prompt you would like to connect to.
        Valid values are 'PowerShell' and 'Command'.
    
    .EXAMPLE
        Connect-PSExec -ComputerName COMPUTERNAME
    
        This example starts a PSEXEC PowerShell session to the computer named COMPUTERNAME.
    
    .EXAMPLE
        Connect-PSExec -ComputerName COMPUTERNAME -Prompt Command
    
        This example starts a PSEXEC Command Prompt session to the computer named COMPUTERNAME.
    
    .EXAMPLE
        'COMPUTER1', 'COMPUTER2' | Connect-PSExec -Prompt PowerShell
    
        This example starts PSEXEC PowerShell sessions to COMPUTER1 and COMPUTER2 by piping the computer names to the function.
    
    .OUTPUTS
        System.String
            Outputs a string indicating the connection status for each computer.
    
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
        PsExec.exe
        powershell.exe
        cmd.exe
    
    .REMARKS
        Ensure that PsExec.exe is available in the script directory or in the system PATH.
#>

function Connect-PSExec {
    
    [CmdletBinding(DefaultParameterSetName = 'Default',
        PositionalBinding = $true,
        SupportsShouldProcess = $true)]
    [OutputType([string], ParameterSetName = 'Default')]

    Param
    (
        [Parameter(ParameterSetName = 'Default',
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0,
            HelpMessage = 'Enter the Name of the computer you would like to connect to.')]
        [Alias('cn')]
        [string[]]$ComputerName,

        [Parameter(ParameterSetName = 'Default',
            Mandatory = $false,
            Position = 1,
            HelpMessage = 'Select which Prompt you would like to connect to.')]
        [ValidateSet('PowerShell', 'Command')]
        [string]$Prompt = 'PowerShell'
    )

    BEGIN {
    }

    PROCESS {
        switch ($Prompt) {
            'PowerShell' {
                foreach ($Computer in $ComputerName) {
                    if ($PSCmdlet.ShouldProcess("$Computer", "Establishing PSEXEC PowerShell Console session")) {
                        try {
                            & "$PSScriptRoot\PsExec.exe" \\$Computer powershell.exe -ExecutionPolicy Unrestricted
                        }
                        catch {
                            Write-Error "Unable to connect to $($Computer)"
                        }
                    }
                }
            }
            'Command' {
                foreach ($Computer in $ComputerName) {
                    if ($PSCmdlet.ShouldProcess("$Computer", "Establishing PSEXEC Command Prompt session")) {
                        try {
                            & "$PSScriptRoot\PsExec.exe" \\$Computer cmd.exe
                        }
                        catch {
                            Write-Error "Unable to connect to $($Computer)"
                        }
                    }
                }
            }
        }
    }

    END {
    }
}