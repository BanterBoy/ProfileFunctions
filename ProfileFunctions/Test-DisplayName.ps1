function Test-DisplayName {
    param(
        [Parameter(Mandatory = $true)]
        [String] $DisplayName
    )
    $null -ne ([ADSISearcher] "(DisplayName=$DisplayName)").FindOne()
}
