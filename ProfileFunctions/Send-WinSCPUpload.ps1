function Send-WinSCPUpload {

    <#
        .SYNOPSIS
        Function automating the upload of files to an SFTP Server.

        .DESCRIPTION
        Function automating the upload of files to an SFTP Server.

        .OUTPUTS
        None. Returns no objects or output.

        .EXAMPLE
        PS C:\> Send-WinSCPUpload -HostName "ftp.example.com" -Username "USERNAME" -Password "PASSWORD" -SshHostKeyFingerprint "SSHFINGERPRINT" -LocalFile "DRIVE:\FILEPATH\FILENAME"
        
        Entering the required information into each parameter uploads the file to the SFTP Server.
        
        .EXAMPLE
        PS C:\> $SFTPoptions = @{
            HostName              = "ftp.example.com"
            UserName              = "USERNAME"
            Password              = "PASSWORD"
            SshHostKeyFingerprint = "SSHFINGERPRINT"
            LocalFile             = "DRIVE:\FILEPATH\FILENAME"
        }
        
        Send-WinSCPUpload -HostName $SFTPoptions.HostName -Username $SFTPoptions.UserName -Password $SFTPoptions.Password -SshHostKeyFingerprint $SFTPoptions.SshHostKeyFingerprint -LocalFile $SFTPoptions.LocalFile
        
        Splat the SFTP settings and pipe the variables into the function, will parse the variables and upload the file to the SFTP Server.
        
        .NOTES
        Author	: Luke Leigh
        Website	: https://blog.lukeleigh.com
        Twitter	: https://twitter.com/luke_leighs
        GitHub  : https://github.com/BanterBoy
        
        General notes
        
    #>

    [CmdletBinding(DefaultParameterSetName = 'default')]

    param(
        # Enter the FTP server Address - eg ftp.example.com
        [Parameter(ParameterSetName = 'Default',
            Mandatory = $True,
            ValueFromPipeline = $True,
            ValueFromPipelineByPropertyName = $True,
            HelpMessage = "Enter the FTP server Address - eg ftp.example.com")]
        [string]
        $HostName,

        # Enter the Username for the FTP Server
        [Parameter(ParameterSetName = 'Default',
            Mandatory = $True,
            ValueFromPipeline = $True,
            ValueFromPipelineByPropertyName = $True,
            HelpMessage = "Enter the Username for the FTP Server")]
        [string]
        $Username,

        [Parameter(ParameterSetName = 'Default',
            Mandatory = $True,
            ValueFromPipeline = $True,
            ValueFromPipelineByPropertyName = $True,
            HelpMessage = "Enter the Password for the FTP Server")]
        [string]
        $Password,

        # Enter the Password for the FTP Server
        [Parameter(ParameterSetName = 'Default',
            Mandatory = $True,
            ValueFromPipeline = $True,
            ValueFromPipelineByPropertyName = $True,
            HelpMessage = "Enter the SSH Fingerprint for the FTP Server")]
        [string]
        $SshHostKeyFingerprint,

        # Enter the filename including the file path - e.g. "DRIVE:\FILEPATH\FILENAME"
        [Parameter(ParameterSetName = 'Default',
            Mandatory = $True,
            ValueFromPipeline = $True,
            ValueFromPipelineByPropertyName = $True,
            HelpMessage = "Enter the filename including the file path - e.g. 'DRIVE:\FILEPATH\FILENAME' ")]
        [string[]]
        $LocalFile
        
    )
    process {
        # Load WinSCP .NET assembly
        Add-Type -Path "$PSScriptRoot\WinSCP\WinSCPnet.dll"

        # Set up session options
        $sessionOptions = New-Object WinSCP.SessionOptions -Property @{
            Protocol              = [WinSCP.Protocol]::Sftp
            HostName              = "$($HostName)"
            UserName              = "$($Username)"
            Password              = "$($Password)"
            SshHostKeyFingerprint = "$($SshHostKeyFingerprint)"
        }

        $session = New-Object WinSCP.Session

        try {
            # Connect
            $session.Open($sessionOptions)

            # Transfer files
            $session.PutFiles("$($LocalFile)", "/*").Check()
        }
        catch {
            Write-ErrorLog ",Failed,Authentication failed - Check Credentials."
        }
        finally {
            $session.Dispose()
        }

    }

}
