<#
.SYNOPSIS
Updates the firmware of a QNAP device using the Posh-SSH module.

.DESCRIPTION
The Update-QNAPFirmware function copies a firmware file to a specified destination, establishes an SSH session with a QNAP device, and runs a series of commands to update the firmware and reboot the device.

.PARAMETER sourceFile
The path to the source firmware file. This path must exist.

.PARAMETER destinationPath
The path to the destination folder. This path must exist and the current user must have modify access to it.

.PARAMETER credential
The PSCredential object for SSH access.

.PARAMETER hostname
The hostname for SSH access.

.PARAMETER firmwareFileName
The name of the firmware file.

.EXAMPLE
$credential = Get-Credential -Message "Enter your SSH credentials"
Update-QNAPFirmware -sourceFile "C:\firmware.img" -destinationPath "C:\Public" -credential $credential -hostname "192.168.1.100" -firmwareFileName "firmware.img"

This example updates the firmware of the QNAP device at 192.168.1.100 using the firmware file at C:\firmware.img.
#>
function Update-QNAPFirmware {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, HelpMessage = "Path to the source firmware file.")]
        [ValidateScript({ Test-Path $_ })]
        [string]$sourceFile,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, HelpMessage = "Path to the destination folder.")]
        [ValidateScript({
                if (-not (Test-Path $_)) {
                    throw "Path '$_' does not exist."
                }

                $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
                $acl = Get-Acl $_

                if (-not ($acl.Access | Where-Object { $_.IdentityReference.Value -eq $currentUser -and $_.FileSystemRights -band [System.Security.AccessControl.FileSystemRights]::Modify })) {
                    throw "Current user '$currentUser' does not have modify access to path '$_'."
                }

                return $true
            })]
        [string]$destinationPath,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, HelpMessage = "PSCredential object for SSH access.")]
        [System.Management.Automation.PSCredential]$credential,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, HelpMessage = "Hostname for SSH access.")]
        [string]$hostname,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, HelpMessage = "Name of the firmware file.")]
        [string]$firmwareFileName
    )

    try {
        # 1. Upload the firmware img file to Public folder by File station.
        Write-Verbose "Copying firmware file to destination..."
        Write-Progress -Activity "Updating Firmware" -Status "Copying firmware file" -PercentComplete 0
        Copy-Item -Path $sourceFile -Destination $destinationPath -ErrorAction Stop
        Write-Verbose "Firmware file copied successfully."
    
        # 2. SSH access to the NAS
        Write-Verbose "Establishing SSH session..."
        Write-Progress -Activity "Updating Firmware" -Status "Establishing SSH session" -PercentComplete 20
        $session = New-SSHSession -ComputerName $hostname -Credential $credential -AcceptKey -ErrorAction Stop
    
        if ($null -eq $session) {
            throw "Failed to establish SSH session."
        }
    
        Write-Verbose "SSH session established successfully."
    
        # 3. Run
        Write-Verbose "Running command: ln -sf /mnt/HDA_ROOT/update /mnt/update"
        Write-Progress -Activity "Updating Firmware" -Status "Running command: ln -sf /mnt/HDA_ROOT/update /mnt/update" -PercentComplete 40
        Invoke-SSHCommand -SessionId $session.SessionId -Command 'ln -sf /mnt/HDA_ROOT/update /mnt/update'

        # 4.Run
        Write-Verbose "Running command: /etc/init.d/update.sh /share/Public/$firmwareFileName"
        Write-Progress -Activity "Updating Firmware" -Status "Running command: /etc/init.d/update.sh /share/Public/$firmwareFileName" -PercentComplete 60
        Invoke-SSHCommand -SessionId $session.SessionId -Command "/etc/init.d/update.sh /share/Public/$firmwareFileName"

        # 5.Run
        Write-Verbose "Running command: reboot -r"
        Write-Progress -Activity "Updating Firmware" -Status "Running command: reboot -r" -PercentComplete 80
        Invoke-SSHCommand -SessionId $session.SessionId -Command 'reboot -r'

        Write-Verbose "Firmware update process completed successfully."
        Write-Progress -Activity "Updating Firmware" -Status "Completed" -Completed
    }
    catch {
        Write-Error "An error occurred during the firmware update process: $_"
    }
    finally {
        # Close the SSH session
        if ($session) {
            Write-Verbose "Closing SSH session..."
            Remove-SSHSession -SessionId $session.SessionId
            Write-Verbose "SSH session closed."
        }
    }
}
