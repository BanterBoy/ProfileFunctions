function Connect-RDPSession {

    <#
        .SYNOPSIS
            Connect-RDPSession
        .DESCRIPTION
            Connect-RDPSession - Spawn MSTSC and launch an RDP session to a remote computer.
        .PARAMETER
            ComputerName
            The name of the remote computer to connect to.
        .EXAMPLE
            Connect-RDPSession -ComputerName COMPUTERNAME
            Starts an RDP session to COMPUTERNAME
        .OUTPUTS
            System.String. Connect-RDPSession
        .NOTES
            Author:     Luke Leigh
            Website:    https://scripts.lukeleigh.com/
            LinkedIn:   https://www.linkedin.com/in/lukeleigh/
            GitHub:     https://github.com/BanterBoy/
            GitHubGist: https://gist.github.com/BanterBoy
        .INPUTS
            ComputerName - You can pipe objects to this perameters.
        .LINK
            https://scripts.lukeleigh.com
            Get-Date
            Write-Output
    #>
    
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
