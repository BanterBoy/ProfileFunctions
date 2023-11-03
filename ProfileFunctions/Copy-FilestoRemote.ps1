function Copy-FilestoRemote {

    <#

    .SYNOPSIS
    Copies files or directories to a remote computer using PowerShell remoting.

    .DESCRIPTION
    The Copy-FilestoRemote function copies files or directories to a remote computer using PowerShell remoting. 
    It can copy multiple files or directories to multiple remote computers at once. 
    The function checks if the file or directory already exists at the destination and prompts for confirmation before copying.

    .PARAMETER ComputerName
    Specifies the name of the remote computer(s) to copy the file(s) to. 
    You can enter multiple computer names separated by commas or pipe them from another command.

    .PARAMETER Credentials
    Specifies the credentials to use to authenticate the connection to the remote computer(s). 
    If you do not specify this parameter, the function uses the current user's credentials.

    .PARAMETER LocalFile
    Specifies the full path of the file or directory to be copied. 
    You can enter multiple file or directory paths separated by commas or pipe them from another command.

    .PARAMETER RemotePath
    Specifies the destination path on the remote computer(s) where the file(s) or directory(ies) will be copied to. 
    You can enter multiple destination paths separated by commas or pipe them from another command.

    .PARAMETER IsDirectory
    Indicates whether the local file is a directory. 
    If you set this parameter to $true, the function copies the entire directory and its contents to the remote computer(s).

    .PARAMETER ConfirmCopy
    Indicates whether to prompt for confirmation before copying each file or directory. 
    If you set this parameter to $true, the function prompts for confirmation before copying each file or directory.

    .INPUTS
    System.String
    You can pipe the file paths, computer names, and remote paths to the function.

    .OUTPUTS
    None
    The function does not return any output upon success. If the function fails, it throws an exception.

    .EXAMPLE
    Copy-FilesToRemote -LocalFile "C:\local\path\file.txt" -ComputerName "remote-computer" -RemotePath "C:\remote\path"

    Copy a single file to a remote computer.

    .EXAMPLE
    Copy-FilesToRemote -LocalFile "C:\local\path\directory" -ComputerName "remote-computer" -RemotePath "C:\remote\path" -IsDirectory $true

    Copy a directory to a remote computer.

    .EXAMPLE
    $computers = "computer1", "computer2", "computer3"
    Copy-FilesToRemote -LocalFile "C:\local\path\file.txt" -ComputerName $computers -RemotePath "C:\remote\path"

    Copy a file to multiple remote computers.

    .EXAMPLE
    Copy-FilesToRemote -LocalFile "C:\local\path\file.txt" -ComputerName "remote-computer" -RemotePath "C:\remote\path" -ConfirmCopy $true

    Copy a file to a remote computer with confirmation for each item.

    .EXAMPLE
    $credential = Get-Credential
    Copy-FilesToRemote -LocalFile "C:\local\path\file.txt" -ComputerName "remote-computer" -RemotePath "C:\remote\path" -Credentials $credential

    Copy a file to a remote computer using specific credentials

    .NOTES
    Author:     Luke Leigh
    Version:    1.0
    
    .LINK
    Website:    https://scripts.lukeleigh.com/
    LinkedIn:   https://www.linkedin.com/in/lukeleigh/
    GitHub:     https://github.com/BanterBoy/
    GitHubGist: https://gist.github.com/BanterBoy

    #>

    [CmdletBinding(DefaultParameterSetName = 'Default',
        ConfirmImpact = 'Medium',
        SupportsShouldProcess = $true,
        HelpUri = 'http://scripts.lukeleigh.com/',
        PositionalBinding = $true)]
    [OutputType([string], ParameterSetName = 'Default')]
    [Alias('cfr')]
    [OutputType([String])]
    param
    (
        [Parameter(ParameterSetName = 'Default',
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Enter computer name or pipe input'
        )]
        [Alias('cn')]
        [string[]]$ComputerName,

        [Parameter(ParameterSetName = 'Default',
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Enter your credentials or pipe input'
        )]
        [Alias('creds')]
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credentials,

        [Parameter(ParameterSetName = 'Default',
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Enter the full path of the file to be copied.'
        )]
        [string[]]$LocalFile,

        [Parameter(ParameterSetName = 'Default',
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Enter the destination path on the remote computer'
        )]
        [string[]]$RemotePath,

        [Parameter(ParameterSetName = 'Default',
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Indicate if the local file is a directory'
        )]
        [switch]$IsDirectory,

        [Parameter(ParameterSetName = 'Default',
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Confirm before copying each item'
        )]
        [switch]$ConfirmCopy

    )

    begin {
        $File = Split-Path $LocalFile -Leaf
        $previousComputer = $null
        $NewPSSession = $null
    }

    process {
        foreach ($Computer in $ComputerName) {
            if ($PSCmdlet.ShouldProcess($Computer, "Copying file $File to remote computer")) {
                try {
                    # Reuse the same session if the computer is the same
                    if ($previousComputer -ne $Computer) {
                        if ($NewPSSession) {
                            Remove-PSSession -Session $NewPSSession
                        }

                        if ($Credentials) {
                            $NewPSSession = New-PSSession -ComputerName $Computer -Credential $Credentials
                        }
                        else {
                            $NewPSSession = New-PSSession -ComputerName $Computer
                        }

                        $previousComputer = $Computer
                    }

                    # Redefine the $File variable in the process block
                    $File = Split-Path $LocalFile -Leaf

                    # Check if the file or directory already exists at the destination
                    $fileExists = Invoke-Command -Session $NewPSSession -ScriptBlock {
                        if ($using:IsDirectory) {
                            Test-Path -Path "${using:RemotePath}${using:File}" -PathType Container
                        }
                        else {
                            Test-Path -Path "${using:RemotePath}${using:File}" -PathType Leaf
                        }
                    }

                    if (-not $fileExists) {
                        # Copy the file or directory to the remote session.
                        Copy-Item -Path "$LocalFile" -Destination "$RemotePath" -ToSession $NewPSSession -Recurse -Confirm:$ConfirmCopy
                    }
                    else {
                        Write-Warning "File or directory $File already exists at the destination $RemotePath on $Computer"
                    }
                }
                catch {
                    Write-Error "Failed to copy file or directory: $_"
                }
            }
        }
    }
    end {
        if ($NewPSSession) {
            Remove-PSSession -Session $NewPSSession
        }
    }
}
