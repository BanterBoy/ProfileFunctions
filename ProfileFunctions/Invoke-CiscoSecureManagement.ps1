<#
.SYNOPSIS
    Invokes Cisco Secure Management on a remote computer.

.DESCRIPTION
    The Invoke-CiscoSecureManagement function is used to enable, disable, copy files, and expand zip files on a remote computer with Cisco Secure Management enabled.

.PARAMETER ComputerName
    The name of the remote computer where Cisco Secure Management is installed.

.PARAMETER ZipFilePath
    The path to the zip file that needs to be copied and expanded on the remote computer.

.PARAMETER DestinationFolderPath
    The destination folder path on the remote computer where the zip file should be copied and expanded.

.PARAMETER Password
    The password for disabling and enabling Cisco Secure Management on the remote computer.

.PARAMETER Credential
    The credential object used to authenticate with the remote computer.

.OUTPUTS
    The function returns a PSObject with the following properties:
    - FileCopied: The path of the zip file that was copied to the remote computer.
    - ExpandedFiles: The list of files that were expanded from the zip file on the remote computer.
    - CiscoSecureState: The state of Cisco Secure Management on the remote computer (enabled or disabled).

.EXAMPLE
    $ZipFile = "C:\Path\to\ZipFile.zip"
    $Destination = "C:\RemoteFolder"
    $ComputerName = "RemoteComputer"
    $Password = ConvertTo-SecureString -String "PASSWORD" -AsPlainText
    $Credential = Get-Credential
    $result = Invoke-CiscoSecureManagement -ComputerName $ComputerName -ZipFilePath $ZipFile -DestinationFolderPath $Destination -Password $Password -Credential $credential
    $result.ExpandedFiles
    $result

    Description
    -----------
    This example invokes Cisco Secure Management on a remote computer, copies the zip file "ZipFile.zip" to the "C:\RemoteFolder" folder, expands the zip file, and returns the list of expanded files.

    .EXAMPLE
    $result = Invoke-CiscoSecureManagement -ComputerName "RemoteComputer" -ZipFilePath "C:\Files\archive.zip" -DestinationFolderPath "C:\Temp" -Password $securePassword -Credential $credential
    $result.ExpandedFiles

    Description
    -----------
    This example invokes Cisco Secure Management on a remote computer, copies the zip file "archive.zip" to the "C:\Temp" folder, expands the zip file, and returns the list of expanded files.

.NOTES
    Author: Your Name
    Date:   Current Date
#>
function Invoke-CiscoSecureManagement {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [string]$ComputerName,
        [string]$ZipFilePath,
        [string]$DestinationFolderPath,
        [SecureString]$Password,
        [PSCredential]$Credential
    )

    # Define a PSObject to store the results
    $result = New-Object PSObject

    # Check if Cisco Secure is enabled
    $isCiscoSecureEnabled = (Test-CiscoSecure -ComputerName $ComputerName).CiscoSecureServiceStatus

    if ($isCiscoSecureEnabled) {
        if ($PSCmdlet.ShouldProcess("$ComputerName", "Disable Cisco Secure")) {
            # Disable Cisco Secure
            Disable-CiscoSecure -ComputerName $ComputerName -Password $Password
        }

        if ($PSCmdlet.ShouldProcess("$ComputerName", "Copy zip file to remote computer")) {
            # Copy the zip file
            Copy-FilestoRemote -ComputerName $ComputerName -LocalFile $ZipFilePath -RemotePath $DestinationFolderPath -Credentials $Credential
        }

        if ($PSCmdlet.ShouldProcess("$ComputerName", "Expand zip file on remote computer")) {
            # Uncompress the zip file and get the list of expanded files
            $expandedFiles = Invoke-Command -ComputerName $ComputerName -Credential $Credential -ScriptBlock {
                param($ZipFilePath, $DestinationFolderPath)
                $RemoteZipFilePath = Join-Path -Path $DestinationFolderPath -ChildPath (Split-Path -Path $ZipFilePath -Leaf)
                if (Test-Path -Path $RemoteZipFilePath) {
                    Expand-Archive -Path $RemoteZipFilePath -DestinationPath $DestinationFolderPath -Force
                    return Get-ChildItem -Path $DestinationFolderPath -Recurse | Select-Object -ExpandProperty FullName
                } else {
                    Write-Error "The zip file $RemoteZipFilePath does not exist on the remote computer."
                }
            } -ArgumentList $ZipFilePath, $DestinationFolderPath
        }

        if ($PSCmdlet.ShouldProcess("$ComputerName", "Enable Cisco Secure")) {
            # Re-enable Cisco Secure
            Enable-CiscoSecure -ComputerName $ComputerName
        }

        # Test if Cisco Secure is re-enabled
        $isCiscoSecureEnabled = (Test-CiscoSecure -ComputerName $ComputerName).CiscoSecureServiceStatus
    }

    # Add the results to the PSObject
    $result | Add-Member -Type NoteProperty -Name "FileCopied" -Value $ZipFilePath
    $result | Add-Member -Type NoteProperty -Name "ExpandedFiles" -Value $expandedFiles
    $result | Add-Member -Type NoteProperty -Name "CiscoSecureState" -Value $isCiscoSecureEnabled

    # Return the result
    return $result
}