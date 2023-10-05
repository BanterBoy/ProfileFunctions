function Get-WTFismyIP {
    [CmdletBinding()]
    param (
        [switch]$Rude
        
    )
    
    begin {
        $WTFismyIP = Invoke-RestMethod -Method Get -Uri "https://wtfismyip.com/json"
    }
    
    process {

        if ($Rude) {

            try {
                $properties = [ordered]@{
                    "YourFuckingIPAddress"   = $WTFismyIP.YourFuckingIPAddress
                    "YourFuckingLocation"    = $WTFismyIP.YourFuckingLocation
                    "YourFuckingHostname"    = $WTFismyIP.YourFuckingHostname
                    "YourFuckingISP"         = $WTFismyIP.YourFuckingISP
                    "YourFuckingTorExit"     = $WTFismyIP.YourFuckingTorExit
                    "YourFuckingCountryCode" = $WTFismyIP.YourFuckingCountryCode
                }
            }
            catch {
                Write-Error -Message "$_"
            }
            finally {
                $obj = New-Object -TypeName psobject -Property $properties
                Write-Output -InputObject $obj
            }

        }

        else {

            try {
                $properties = [ordered]@{
                    "YourIPAddress"   = $WTFismyIP.YourFuckingIPAddress
                    "YourLocation"    = $WTFismyIP.YourFuckingLocation
                    "YourHostname"    = $WTFismyIP.YourFuckingHostname
                    "YourISP"         = $WTFismyIP.YourFuckingISP
                    "YourTorExit"     = $WTFismyIP.YourFuckingTorExit
                    "YourCountryCode" = $WTFismyIP.YourFuckingCountryCode
                }
            }
            catch {
                Write-Error -Message "$_"
            }
            finally {
                $obj = New-Object -TypeName psobject -Property $properties
                Write-Output -InputObject $obj
            }
    
        }

    }

    end {
        
    }
}
