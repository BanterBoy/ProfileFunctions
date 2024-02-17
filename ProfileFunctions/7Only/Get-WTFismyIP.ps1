<#
.SYNOPSIS
    Retrieves IP address information from wtfismyip.com.

.DESCRIPTION
    The Get-WTFismyIP function retrieves IP address information from wtfismyip.com and returns it as a PowerShell object.

.PARAMETER Polite
    If specified, the function will not include profanity in the output.

.EXAMPLE
    Get-WTFismyIP

    Retrieves IP address information from wtfismyip.com and returns it as a PowerShell object.

.EXAMPLE
    Get-WTFismyIP -Polite

    Retrieves IP address information from wtfismyip.com and returns it as a PowerShell object, without including profanity in the output.

.NOTES
    Author: Unknown
    Last Edit: Unknown
#>

function Get-WTFismyIP {
    [CmdletBinding()]

    param (
        [switch] $Polite
    )
    
    begin { }
    
    process {
        try {
            $WTFismyIP = Invoke-RestMethod -Method Get -Uri "https://wtfismyip.com/json"

            $Fucking = $polite.IsPresent ? "" : "Fucking"

            $properties = [ordered]@{
                "Your$($Fucking)IPaddress"   = $WTFismyIP.YourFuckingIPAddress
                "Your$($Fucking)Location"    = $WTFismyIP.YourFuckingLocation
                "Your$($Fucking)Hostname"    = $WTFismyIP.YourFuckingHostname
                "Your$($Fucking)ISP"         = $WTFismyIP.YourFuckingISP
                "Your$($Fucking)TorExit"     = $WTFismyIP.YourFuckingTorExit
                "Your$($Fucking)CountryCode" = $WTFismyIP.YourFuckingCountryCode
            }
            
            $obj = New-Object -TypeName psobject -Property $properties

            Write-Output -InputObject $obj
        }
        catch {
            Write-Error -Message "$_"
        }
    }

    end { }
}
