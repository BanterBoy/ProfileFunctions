# Description: Connect to a remote computer using Remote Assistance
# $Computer = "skywalker"
# $ActiveUser = Get-RDPUserReport -ComputerName $Computer
# msra.exe /offerra $Computer ($env:USERDOMAIN + "\" + ($ActiveUser.Username + ":" + $ActiveUser.ID))

function Connect-RemoteAssistance {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$Computer
    )
    $ActiveUser = Get-RDPUserReport -ComputerName $Computer
    msra.exe /offerra $Computer ($env:USERDOMAIN + "\" + ($ActiveUser.Username + ":" + $ActiveUser.ID))
}
