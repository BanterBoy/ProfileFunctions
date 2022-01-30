function Get-FeaturesInventory {

    [CmdletBinding()]
    param (
        [Parameter(
            Position = 0)]
        [string]
        $SearchBase = (Get-AdDomain -Current LocalComputer).DistinguishedName
    )
    
    begin {

    }

    process {

        $AdComputer = Get-ADComputer -Filter { OperatingSystem -like '*Server*' } -SearchBase $SearchBase -Properties *


        foreach ($Computer in $AdComputer) {

            $features = Get-WindowsFeature -ComputerName $Computer.DnsHostName | Where-Object -Property Installed -EQ $true

            foreach ($feature in $features) {

                try {
                    $properties = [ordered]@{
                        ComputerName    = $Computer.Name
                        OperatingSystem = $Computer.OperatingSystem
                        DnsHostName     = $Computer.DnsHostName
                        IPv4Address     = $Computer.IPv4Address
                        Date            = Get-Date
                        FeatureName     = $feature.Name
                        DisplayName     = $feature.DisplayName
                        Description     = $feature.Description
                        Installed       = $feature.Installed
                        InstallDate     = $feature.InstallDate
                        ADComputer      = $Computer.Name
                        
                    }
                    
                }

                catch {
                    Write-Error "Error getting feature properties"
                }

                finally {
                    $obj = New-Object -TypeName PSObject -Property $properties
                    Write-Output $obj
                }

            }

        }

    }

    end {

    }
    
}


<#
    DESCRIPTION
    This is a starter script to query AD for servers and
    then inventory the roles and features on each server.
    Save the inventory with Export-CliXml.  Add error
    handling and other polish to use in production.
    
    PARAMETER SearchBase
    Distinguished name of Active Directory container where search
    for computer accounts for servers should begin.  Defaults to
    the entire domain of which the local computer is a member.
#>
