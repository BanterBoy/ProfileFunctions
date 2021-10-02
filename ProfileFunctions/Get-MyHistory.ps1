function Get-MyHistory {
    [CmdletBinding()]
    param (
        [Parameter()]
        [int]
        $Quantity
    )
    Get-History | Select-Object -Property CommandLine -Last $Quantity | Format-Table -AutoSize -Wrap

}
