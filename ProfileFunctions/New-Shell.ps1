<#
.SYNOPSIS
    Starts an elevated PowerShell console or Windows Terminal.

.DESCRIPTION
    Opens a new PowerShell console elevated as Administrator or launches a specified shell in Windows Terminal.
    If the user is already running an elevated administrator shell, a message is displayed in the console session.

.PARAMETER User
    Specifies the type of shell to start. Options are 'PowerShell' for Windows PowerShell and 'pwsh' for PowerShell Core.

.PARAMETER RunAs
    Specifies to run the shell as an administrator. Options are 'PowerShellRunAs' for Windows PowerShell and 'pwshRunAs' for PowerShell Core.

.PARAMETER RunAsUser
    Specifies to run the shell as a different user. Options are 'PowerShellRunAsUser' for Windows PowerShell and 'pwshRunAsUser' for PowerShell Core.

.PARAMETER Credentials
    Specifies the credentials to use for the RunAsUser parameter. This is mandatory when using RunAsUser.

.PARAMETER Terminal
    Specifies to launch the shell in Windows Terminal. Options are 'PowerShellTerminal' for Windows PowerShell and 'pwshTerminal' for PowerShell Core.

.PARAMETER TerminalRunAs
    Specifies to run Windows Terminal as an administrator with the specified profile. Options are 'PowerShellTerminalRunAs' for Windows PowerShell and 'pwshTerminalRunAs' for PowerShell Core.

.EXAMPLE
    PS C:\> New-Shell -User pwsh
    Launches a new PowerShell Core shell.

.EXAMPLE
    PS C:\> New-Shell -RunAs PowerShellRunAs
    Launches a new elevated Windows PowerShell shell.

.EXAMPLE
    PS C:\> New-Shell -RunAsUser pwshRunAsUser -Credentials (Get-Credential)
    Launches a new PowerShell Core shell as a specified user.

.EXAMPLE
    PS C:\> New-Shell -Terminal pwshTerminal
    Launches a new PowerShell Core shell in Windows Terminal.

.EXAMPLE
    PS C:\> New-Shell -TerminalRunAs pwshTerminalRunAs
    Launches a new elevated PowerShell Core shell in Windows Terminal.

.NOTES
    Author: Your Name
    Date: Today's Date
#>

function New-Shell {
    [CmdletBinding(DefaultParameterSetName = 'User')]
    param (
        [Parameter(ParameterSetName = 'User', Mandatory = $false, Position = 0, HelpMessage = 'Specifies the type of shell to start.')]
        [ValidateSet('PowerShell', 'pwsh')]
        [string]
        $User,

        [Parameter(ParameterSetName = 'RunAs', Mandatory = $false, Position = 0, HelpMessage = 'Specifies to run the shell as an administrator.')]
        [ValidateSet('PowerShellRunAs', 'pwshRunAs')]
        [string]
        $RunAs,

        [Parameter(ParameterSetName = 'RunAsUser', Mandatory = $false, Position = 0, HelpMessage = 'Specifies to run the shell as a different user.')]
        [ValidateSet('PowerShellRunAsUser', 'pwshRunAsUser')]
        [string]
        $RunAsUser,

        [Parameter(ParameterSetName = 'RunAsUser', Mandatory = $true, Position = 1, HelpMessage = 'Specifies the credentials to use for the RunAsUser parameter.')]
        [pscredential]
        $Credentials,

        [Parameter(ParameterSetName = 'Terminal', Mandatory = $false, Position = 0, HelpMessage = 'Specifies to launch the shell in Windows Terminal.')]
        [ValidateSet('PowerShellTerminal', 'pwshTerminal')]
        [string]
        $Terminal,

        [Parameter(ParameterSetName = 'TerminalRunAs', Mandatory = $false, Position = 0, HelpMessage = 'Specifies to run Windows Terminal as an administrator with the specified profile.')]
        [ValidateSet('PowerShellTerminalRunAs', 'pwshTerminalRunAs')]
        [string]
        $TerminalRunAs
    )

    begin {
        $parameters = @{}
        if ($PSBoundParameters.ContainsKey('User')) { $parameters['User'] = $User }
        if ($PSBoundParameters.ContainsKey('RunAs')) { $parameters['RunAs'] = $RunAs }
        if ($PSBoundParameters.ContainsKey('RunAsUser')) { $parameters['RunAsUser'] = $RunAsUser }
        if ($PSBoundParameters.ContainsKey('Terminal')) { $parameters['Terminal'] = $Terminal }
        if ($PSBoundParameters.ContainsKey('TerminalRunAs')) { $parameters['TerminalRunAs'] = $TerminalRunAs }

        Write-Verbose "Starting New-Shell function with parameters: $($parameters | Out-String)"
    }

    process {
        try {
            switch ($PSCmdlet.ParameterSetName) {
                'User' {
                    switch ($User) {
                        'PowerShell' {
                            try {
                                Start-Process -FilePath "PowerShell.exe" -PassThru
                                Write-Verbose "Launched PowerShell."
                            }
                            catch {
                                Write-Error "Failed to launch PowerShell: $_"
                            }
                        }
                        'pwsh' {
                            try {
                                Start-Process -FilePath "pwsh.exe" -PassThru
                                Write-Verbose "Launched PowerShell Core."
                            }
                            catch {
                                Write-Error "Failed to launch PowerShell Core: $_"
                            }
                        }
                    }
                }
                'RunAs' {
                    switch ($RunAs) {
                        'PowerShellRunAs' {
                            try {
                                Start-Process -FilePath "PowerShell.exe" -Verb RunAs -PassThru
                                Write-Verbose "Launched elevated PowerShell."
                            }
                            catch {
                                Write-Error "Failed to launch elevated PowerShell: $_"
                            }
                        }
                        'pwshRunAs' {
                            try {
                                Start-Process -FilePath "pwsh.exe" -Verb RunAs -PassThru
                                Write-Verbose "Launched elevated PowerShell Core."
                            }
                            catch {
                                Write-Error "Failed to launch elevated PowerShell Core: $_"
                            }
                        }
                    }
                }
                'RunAsUser' {
                    switch ($RunAsUser) {
                        'PowerShellRunAsUser' {
                            try {
                                Start-Process -Credential $Credentials -FilePath "PowerShell.exe" -LoadUserProfile -UseNewEnvironment -ArgumentList @("-Mta") -PassThru
                                Write-Verbose "Launched PowerShell as specified user."
                            }
                            catch {
                                Write-Error "Failed to launch PowerShell as specified user: $_"
                            }
                        }
                        'pwshRunAsUser' {
                            try {
                                Start-Process -Credential $Credentials -FilePath "pwsh.exe" -LoadUserProfile -UseNewEnvironment -ArgumentList @("-Mta") -PassThru
                                Write-Verbose "Launched PowerShell Core as specified user."
                            }
                            catch {
                                Write-Error "Failed to launch PowerShell Core as specified user: $_"
                            }
                        }
                    }
                }
                'Terminal' {
                    switch ($Terminal) {
                        'PowerShellTerminal' {
                            try {
                                Start-Process -FilePath "wt.exe" -ArgumentList "new-tab -p 'Windows PowerShell'" -PassThru
                                Write-Verbose "Launched Windows PowerShell in Windows Terminal."
                            }
                            catch {
                                Write-Error "Failed to launch Windows PowerShell in Windows Terminal: $_"
                            }
                        }
                        'pwshTerminal' {
                            try {
                                Start-Process -FilePath "wt.exe" -ArgumentList "new-tab -p 'PowerShell'" -PassThru
                                Write-Verbose "Launched PowerShell Core in Windows Terminal."
                            }
                            catch {
                                Write-Error "Failed to launch PowerShell Core in Windows Terminal: $_"
                            }
                        }
                    }
                }
                'TerminalRunAs' {
                    switch ($TerminalRunAs) {
                        'PowerShellTerminalRunAs' {
                            try {
                                Start-Process -FilePath "wt.exe" -ArgumentList "new-tab -p 'Windows PowerShell'" -Verb RunAs -PassThru
                                Write-Verbose "Launched elevated Windows PowerShell in Windows Terminal."
                            }
                            catch {
                                Write-Error "Failed to launch elevated Windows PowerShell in Windows Terminal: $_"
                            }
                        }
                        'pwshTerminalRunAs' {
                            try {
                                Start-Process -FilePath "wt.exe" -ArgumentList "new-tab -p 'PowerShell'" -Verb RunAs -PassThru
                                Write-Verbose "Launched elevated PowerShell Core in Windows Terminal."
                            }
                            catch {
                                Write-Error "Failed to launch elevated PowerShell Core in Windows Terminal: $_"
                            }
                        }
                    }
                }
            }
        }
        catch {
            Write-Error "An error occurred while processing the New-Shell function: $_"
        }
    }

    end {
        Write-Verbose "New-Shell function execution completed."
    }
}
