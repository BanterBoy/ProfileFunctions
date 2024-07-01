function Get-PatchTuesday {
    <#
    .SYNOPSIS
        Get the Patch Tuesday for a given month

    .DESCRIPTION
        This function can be used to find the date for Microsoft's Patch Tuesday in any given month. 
        The default command without parameters will return the Patch Tuesday date for the current month.

    .PARAMETER Month
        The month to check.

    .PARAMETER Year
        The year to check.

    .EXAMPLE
        PS C:\> Get-PatchTuesday
        This example will return the Patch Tuesday for the current month.

    .EXAMPLE
        PS C:\> Get-PatchTuesday -Month 12 -Year 2015
        This example will return the Patch Tuesday for December 2015.

    .EXAMPLE
        PS C:\> Get-PatchTuesday -Month 12
        This example will return the Patch Tuesday for December this year.

    .OUTPUTS
        [datetime]

    .NOTES
        Author:     Luke Leigh
        Website:    https://blog.lukeleigh.com/
        LinkedIn:   https://www.linkedin.com/in/lukeleigh/
        GitHub:     https://github.com/BanterBoy/
        GitHubGist: https://gist.github.com/BanterBoy

    .LINK
        https://github.com/BanterBoy
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, Position = 0)]
        [ValidateRange(1, 12)]
        [int]$Month = (Get-Date).Month,

        [Parameter(Mandatory = $false, Position = 1)]
        [ValidatePattern('^\d{4}$')]
        [int]$Year = (Get-Date).Year
    )

    if ($PSCmdlet.ShouldProcess("$Month-$Year", "Locating Patch Tuesday")) {
        $firstDayOfMonth = Get-Date -Year $Year -Month $Month -Day 1

        # Find the second Tuesday of the month
        $patchTuesday = 1..31 | ForEach-Object {
            $currentDate = $firstDayOfMonth.AddDays($_ - 1)
            if ($currentDate.Month -eq $Month -and $currentDate.DayOfWeek -eq [DayOfWeek]::Tuesday) {
                $currentDate
            }
        } | Select-Object -Index 1

        return $patchTuesday
    }
}
