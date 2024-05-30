Import-Module GroupPolicy -SkipEditionCheck

function Search-GPOsForString {

    <#
    .SYNOPSIS
        Searches all Group Policy Objects (GPOs) in the current user's domain for a specified string.
    .DESCRIPTION
        This function searches all GPOs in the current user's domain for a specified string. It uses the Get-GPOReport cmdlet to retrieve the XML report for each GPO, and then searches the report for the specified string using regular expressions. If a match is found, the function outputs a custom object with the name of the matching GPO and the search string.
    .PARAMETER SearchText
        The string to search for in the GPOs.
    .EXAMPLE
        Search-GPOsForString -SearchText "password"
        This example searches all GPOs in the current user's domain for the string "password".
    #>

    # Bind the function parameters
    [CmdletBinding()]
    Param(
        [string]$SearchText  # The string to search for in the GPOs
    )

    # Get the domain name
    $DomainName = $env:USERDNSDOMAIN

    # Get all GPOs in the domain
    $allGposInDomain = Get-GPO -All -Domain $DomainName

    # Count the total number of GPOs
    $totalGpos = $allGposInDomain.Count

    # Initialize the current GPO counter
    $currentGpo = 0

    # Loop through each GPO
    foreach ($gpo in $allGposInDomain) {
        # Increment the current GPO counter
        $currentGpo++

        # Check if the GPO ID is not null
        if ($null -ne $gpo.Id) {
            # Get the GPO report in XML format
            $report = Get-GPOReport -Guid $gpo.Id -ReportType Xml

            # Check if the report matches the search text
            if ($report -match ([regex]::Escape("$SearchText")) ) {
                # Create a custom object with the GPO name and the match
                $result = [PSCustomObject]@{
                    'GPOName' = $gpo.DisplayName
                    'Match'   = $SearchText
                }

                # Output the result
                Write-Output $result
            }
        }

        # Update the progress bar
        Write-Progress -Activity "Searching GPOs" -Status "$currentGpo of $totalGpos GPOs searched" -PercentComplete (($currentGpo / $totalGpos) * 100)
    }
}
