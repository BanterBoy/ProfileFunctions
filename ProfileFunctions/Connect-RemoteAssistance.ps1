# Description: Connect to a remote computer using Remote Assistance
# $Computer = "skywalker"
# $ActiveUser = Get-RDPUserReport -ComputerName $Computer
# msra.exe /offerra $Computer ($env:USERDOMAIN + "\" + ($ActiveUser.Username + ":" + $ActiveUser.ID))

<#
.SYNOPSIS
Connects to a remote computer using Remote Assistance.

.DESCRIPTION
The Connect-RemoteAssistance function allows you to connect to a remote computer using Remote Assistance. It retrieves the active user on the specified computer using the Get-RDPUserReport function and then initiates a Remote Assistance session using the msra.exe command.

.PARAMETER Computer
The name of the remote computer to connect to.

.EXAMPLE
Connect-RemoteAssistance -Computer "skywalker"
Connects to the remote computer named "skywalker" using Remote Assistance.

#>

function Connect-RemoteAssistance {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$Computer
    )

    # Check if the computer is reachable before proceeding
    if (!(Test-Connection -ComputerName $Computer -Count 1 -Quiet)) {
        Write-Error "Cannot reach $Computer. Please check the computer name or network connection."
        return
    }

    # Get the active user on the remote computer
    $ActiveUser = Get-RDPUserReport -ComputerName $Computer

    # Check if the active user was found
    if ($null -eq $ActiveUser) {
        Write-Error "No active user found on $Computer. Please check the computer name or user session."
        return
    }

    # Construct the user string
    $UserString = "{0}\{1}:{2}" -f $env:USERDOMAIN, $ActiveUser.Username, $ActiveUser.ID

    # Start the remote assistance session
    msra.exe /offerra $Computer $UserString
}
