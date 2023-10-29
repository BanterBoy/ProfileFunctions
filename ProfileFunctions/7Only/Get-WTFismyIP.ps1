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

            $fucking = $polite.IsPresent ? "" : " fucking"

            $properties = [ordered]@{
                "Your$($fucking) IP address"   = $WTFismyIP.YourFuckingIPAddress
                "Your$($fucking) location"     = $WTFismyIP.YourFuckingLocation
                "Your$($fucking) host name"    = $WTFismyIP.YourFuckingHostname
                "Your$($fucking) ISP"          = $WTFismyIP.YourFuckingISP
                "Your$($fucking) tor exit"     = $WTFismyIP.YourFuckingTorExit
                "Your$($fucking) country code" = $WTFismyIP.YourFuckingCountryCode
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
