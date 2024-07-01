function Get-WTFismyIP {
	<#
		.SYNOPSIS
			A brief description of the Get-WTFismyIP function.
		
		.DESCRIPTION
			A detailed description of the Get-WTFismyIP function.
		
		.EXAMPLE
			PS C:\> Get-WTFismyIP
		
		.NOTES
			Additional information about the function.
	#>
	
	[CmdletBinding()]
    param (
        
    )
    
    begin {
        $WTFismyIP = Invoke-RestMethod -Method Get -Uri "https://wtfismyip.com/json"
    }
    
    process {

        try {
            $properties = @{
                "YourFuckingIPAddress"   = $WTFismyIP.YourFuckingIPAddress
                "YourFuckingLocation"    = $WTFismyIP.YourFuckingLocation
                "YourFuckingHostname"    = $WTFismyIP.YourFuckingHostname
                "YourFuckingISP"         = $WTFismyIP.YourFuckingISP
                "YourFuckingTorExit"     = $WTFismyIP.YourFuckingTorExit
                "YourFuckingCountryCode" = $WTFismyIP.YourFuckingCountryCode
            }
            $obj = New-Object -TypeName psobject -Property $properties
            Write-Output -InputObject $obj
        }
        catch {
            Write-Error -Message "$_"
        }
        
    }
    
    end {
        
    }
}
