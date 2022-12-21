class CompanyNumbers {
    [string] $VATREGNumber;
    [string] $CompanyNumber;
}


<#
    .SYNOPSIS
    Deserialize a supplied json string into an object of type [CompanyNumbers]

    .DESCRIPTION
    Uses ConvertFrom-Json to deserialize a json string into a [pscustomobject] object graph.
    Parses the [pscustomobject] graph into a strongly typed object graph based on the generated classes.

    .PARAMETER Json
    The json string to be deserialized.

    .EXAMPLE
    Get-CompanyNumbersClass -Json $json
#>
function Get-CompanyNumbersClass {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "String representation of json to be deserialized.")]
        [string] $Json
    )

    Begin {}

    Process {
        return [CompanyNumbers] (ConvertFrom-Json $Json)
    }

    End {}
}
