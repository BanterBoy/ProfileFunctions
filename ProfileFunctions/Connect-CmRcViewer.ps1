<#
    .SYNOPSIS
        Spawns ConfigMgr Remote Control Viewer and launches a session to a remote computer.
    
    .DESCRIPTION
        The Connect-CmRcViewer function starts the ConfigMgr Remote Control Viewer and connects to a specified remote computer.
        This function is useful for administrators who need to remotely manage and troubleshoot computers using the ConfigMgr Remote Control Viewer.
    
    .PARAMETER ComputerName
        This parameter accepts the name of the computer you would like to connect to.
        Supports IP address, computer name, or fully qualified domain name (FQDN).
    
    .EXAMPLE
        Connect-CmRcViewer -ComputerName COMPUTERNAME
    
        This example starts a ConfigMgr Remote Control Viewer session to the computer named COMPUTERNAME.
    
    .EXAMPLE
        Get-ADComputer -Filter { Name -like '*SCCM*' } | ForEach-Object -Process { Connect-CmRcViewer -ComputerName $_.DNSHostName }
    
        This example starts a ConfigMgr Remote Control Viewer session to all computers in Active Directory with names that match the pattern '*SCCM*'.
    
    .EXAMPLE
        'COMPUTER1', 'COMPUTER2' | Connect-CmRcViewer
    
        This example starts ConfigMgr Remote Control Viewer sessions to COMPUTER1 and COMPUTER2 by piping the computer names to the function.
    
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
        Get-Date
        Start-Process
        Write-Output
    
    .REMARKS
        Ensure that the ConfigMgr Remote Control Viewer (CmRcViewer.exe) is installed at the specified path.
#>

Function Connect-CmRcViewer {

	[CmdletBinding(DefaultParameterSetName = 'Default',
		PositionalBinding = $true,
		SupportsShouldProcess = $true)]
	[OutputType([string], ParameterSetName = 'Default')]

	Param
	(
		[Parameter(ParameterSetName = 'Default',
			Mandatory = $false,
			ValueFromPipeline = $true,
			ValueFromPipelineByPropertyName = $true,
			HelpMessage = 'Enter a computer name or pipe input'
		)]
		[Alias('cn')]
		[string[]]$ComputerName
	)
	
	Begin {
		
	}
	
	Process {
		ForEach ($Computer In $ComputerName) {
			If ($PSCmdlet.ShouldProcess("$($Computer)", "Establish a ConfigMgr Remote Control Viewer connection")) {
				try {
					Start-Process "C:\Program Files (x86)\Microsoft Endpoint Manager\AdminConsole\bin\i386\CmRcViewer.exe" -ArgumentList "$Computer"
				}
				catch {
					Write-Output "$($Computer): is not reachable."
				}
			}
		}
	}
	
	End {
		
	}
}
