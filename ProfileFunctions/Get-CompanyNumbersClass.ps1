class CompanyNumbers {
    [string] $CountryCode;
    [string] $VATREGNumber;
    [string] $CompanyNumber;
}


<#
    .SYNOPSIS
    Deserialize a supplied json string into an object of type [CompanyNumbers].
    Response will be either an instance of the class or an array of the class, depending on the JSON input.

    .DESCRIPTION
    Uses ConvertFrom-Json to deserialize a json string into a [pscustomobject] object graph.
    Parses the [pscustomobject] graph into a strongly typed object graph based on the generated classes.

    .PARAMETER Json
    The json string to be deserialized.

    .EXAMPLE
    Get-CompanyNumbersClass -Json ([System.IO.File]::ReadAllText('C:\GitRepos\ProfileFunctions\CompanyNos.json'))
#>
function Get-CompanyNumbersClass {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "String representation of json to be deserialized.")]
        [string] $Json
    )

    Begin {}

    Process {
        $obj = ConvertFrom-Json $Json

        if ($obj -is [array]) {
            $outArr = @()

            foreach ($o in $obj) {
                $outArr + ([CompanyNumbers] $o)
            }

            return $outArr
        }

        return [CompanyNumbers] (ConvertFrom-Json $Json)
    }

    End {}
}
