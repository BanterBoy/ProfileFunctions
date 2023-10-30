function Get-LoadedFunctions {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$Verb = "*",
        [Parameter(Mandatory = $false)]
        [string]$Noun = "*",
        [Parameter(Mandatory = $false)]
        [switch]$Wide
    )

    $funcs = Get-Command -CommandType Function | Where-Object -FilterScript { ( $_.Source -eq '' ) -and ( $_.Name -like '*-*' ) } | Select-Object -Property Name

    if ($Verb -ne "*") {
        $funcs = $funcs | Where-Object { $_.Name -like "$Verb-*" }
    }

    if ($Noun -ne "*") {
        $funcs = $funcs | Where-Object { $_.Name -like "*-$Noun" }
    }

    if ($Wide) {
        $funcs | Format-Wide -Autosize
    }
    else {
        return $funcs
    }
}