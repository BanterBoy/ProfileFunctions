function Get-RunOnceRegKeys {
    <#
    .SYNOPSIS
        Retrieves the names and values of all RunOnce registry keys.
    .DESCRIPTION
        Retrieves the names and values of all RunOnce registry keys on the computer "RemoteComputer01".
    .EXAMPLE
        Get-RunOnceRegKeys -ComputerName "RemoteComputer01" -Credential (Get-Credential)
        Retrieves the names and values of all RunOnce registry keys on the computer "RemoteComputer01" using the provided credentials.
    .EXAMPLE
        Get-RunOnceRegKeys
        Retrieves the names and values of all RunOnce registry keys on the local computer.
    .NOTES
        Author: Unknown
        Last Edit: Unknown
    #>
    param (
        [Parameter(Mandatory = $false)]
        [string]$ComputerName = $env:COMPUTERNAME,
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]$Credential = [System.Management.Automation.PSCredential]::Empty
    )
    if (-not (Test-Connection -ComputerName $ComputerName -Count 1 -Quiet)) {
        Write-Error "Cannot reach $ComputerName. Please check the computer name or network connection."
        return $false
    }
    try {
        $reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $ComputerName)
        $regKey = $reg.OpenSubKey("SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce", $true)
        if ($null -eq $regKey) {
            Write-Error "Cannot open registry key SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce on $ComputerName."
            return $false
        }
        $valueNames = $regKey.GetValueNames()
        $values = $valueNames | ForEach-Object { 
            [PSCustomObject]@{
                Name  = $_
                Value = $regKey.GetValue($_)
            }
        }
        return $values
    }
    catch {
        Write-Error $_.Exception.Message
        return $false
    }
}
