function Copy-FilestoComputer {
    <#
    .SYNOPSIS
    Copies files to or from a remote computer.
    
    .DESCRIPTION
    The Copy-FilestoComputer function copies files to or from a remote computer using PowerShell remoting.
    
    .PARAMETER ComputerName
    Specifies the name of the remote computer.
    
    .PARAMETER LocalPath
    Specifies the local path of the directory to copy.
    
    .PARAMETER RemotePath
    Specifies the remote path of the directory to copy.
    
    .PARAMETER Credentials
    Specifies the credentials to use for the remote session.
    
    .PARAMETER Direction
    Specifies the direction of the copy operation. Valid values are 'ToRemote' and 'FromRemote'.
    
    .EXAMPLE
    Copy-FilestoComputer -ComputerName "Server01" -LocalPath "C:\Temp" -RemotePath "C:\Temp" -Credentials (Get-Credential) -Direction "ToRemote"
    
    This example copies the contents of the local C:\Temp directory to the remote C:\Temp directory on Server01.
    
    .EXAMPLE
    Copy-FilestoComputer -ComputerName "Server01" -LocalPath "C:\Temp" -RemotePath "C:\Temp" -Credentials (Get-Credential) -Direction "FromRemote"
    
    This example copies the contents of the remote C:\Temp directory on Server01 to the local C:\Temp directory.
    
    .NOTES
    Author: Luke Leigh/GitHub Copilot
    Date:   2023-10-01
    #>
    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = 'Medium'
    )]
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$ComputerName,

        [Parameter(Mandatory = $true)]
        [string]$LocalPath,

        [Parameter(Mandatory = $true)]
        [string]$RemotePath,

        [Parameter()]
        [System.Management.Automation.PSCredential]$Credentials,

        [Parameter()]
        [ValidateSet('ToRemote', 'FromRemote')]
        [string]$Direction = 'ToRemote'
    )

    begin {
    }

    process {
        foreach ($Computer in $ComputerName) {
            try {
                if ($PSCmdlet.ShouldProcess($Computer, "Copy $LocalPath to remote computer")) {
                    # Create a remote session to the destination computer.
                    if ($Credentials) {
                        $NewPSSession = New-PSSession -ComputerName $Computer -Credential $Credentials -ErrorAction Stop
                    }
                    else {
                        $NewPSSession = New-PSSession -ComputerName $Computer -ErrorAction Stop
                    }

                    if ($Direction -eq 'ToRemote') {
                        # Copy the directory to the remote session.
                        $Files = Get-ChildItem -Path $LocalPath -Recurse
                        foreach ($File in $Files) {
                            $Destination = $File.FullName.Replace($LocalPath, $RemotePath)
                            Copy-Item -Path $File.FullName -Destination $Destination -ToSession $NewPSSession -Recurse -ErrorAction Stop
                        }
                    }
                    else {
                        # Copy the directory from the remote session.
                        $Files = Get-ChildItem -Path $RemotePath -Recurse -Session $NewPSSession
                        foreach ($File in $Files) {
                            $Destination = $File.FullName.Replace($RemotePath, $LocalPath)
                            Copy-Item -Path $File.FullName -Destination $Destination -FromSession $NewPSSession -Recurse -ErrorAction Stop
                        }
                    }

                    # Terminate the remote session.
                    Remove-PSSession -Session $NewPSSession
                }
            }
            catch {
                Write-Error $_.Exception.Message
                if ($NewPSSession) {
                    Remove-PSSession -Session $NewPSSession
                }
            }
        }
    }

    end {
    }
}
