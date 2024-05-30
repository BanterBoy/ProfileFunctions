function Test-Surname {
    param(
        [Parameter(Mandatory = $true)]
        [String] $Surname
    )
    $null -ne ([ADSISearcher] "(sn=$Surname)").FindOne()
}
