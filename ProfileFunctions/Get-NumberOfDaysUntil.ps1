<#
.SYNOPSIS
    Calculates the number of days until a specified date or a number of days from the current date.

.DESCRIPTION
    The Get-NumberOfDaysUntil function calculates the number of days until a specified date or a number of days from the current date. It accepts two parameters: MoveDay and DaysUntilMove.

.PARAMETER MoveDay
    Specifies the date you will be moving. This parameter is mandatory when using the 'MoveDate' parameter set. It accepts a DateTime object.

.PARAMETER DaysUntilMove
    Specifies the number of days until the move. This parameter is optional when using the 'DaysUntilMove' parameter set. It accepts an integer.

.OUTPUTS
    The function outputs a custom object with the following properties:
    - MoveDate: The specified move date in short date format.
    - MoveDay: The day of the week, day of the month, and month of the specified move date.
    - Countdown: The number of days until the move date.
    - Today: The current date in short date format.

.EXAMPLE
    Get-NumberOfDaysUntil -MoveDay '01/01/2023'
    Calculates the number of days until January 1, 2023.

.EXAMPLE
    Get-NumberOfDaysUntil -DaysUntilMove 30
    Calculates the number of days from the current date until 30 days later.

.NOTES
    Author: Your Name
    Date: Today's Date
    Version: 1.0
#>

function Get-NumberOfDaysUntil {
    [CmdletBinding(DefaultParameterSetName = 'Default',
        PositionalBinding = $true,
        SupportsShouldProcess = $false)]
    [OutputType([string], ParameterSetName = 'MoveDate')]
    Param
    (
        [Parameter(ParameterSetName = 'MoveDate',
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $true,
            Position = 0,
            HelpMessage = 'Enter the date you will be moving.')]
        [DateTime]
        $MoveDay,

        [Parameter(ParameterSetName = 'DaysUntilMove',
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $true,
            Position = 0,
            HelpMessage = 'Enter the date you will be moving.')]
        [int]$DaysUntilMove # 54
    )

    begin {}
    process {
        $ParseMoveDay = [DateTime]::ParseExact($MoveDay, "dd/MM/yyyy", $null)
        if ($DaysUntilMove) {
            $ParseMoveDay = (Get-Date).AddDays($DaysUntilMove)
        }
        $Today = (Get-Date).ToShortDateString()
        $TimeSpan = New-TimeSpan -Start $Today -End $ParseMoveDay
        $Countdown = Join-String -InputObject $TimeSpan.Days, " Days"
        $Day = Join-String -InputObject $ParseMoveDay.DayOfWeek, " ", $ParseMoveDay.Day, " ", $ParseMoveDay.ToString('MMMM')
        $properties = @{
            MoveDate  = $ParseMoveDay.ToShortDateString()
            MoveDay   = $Day
            Countdown = $Countdown
            Today     = $Today
        }
        $Output = New-Object -TypeName psobject -Property $properties
        Write-Output -InputObject $Output
    }

    end {}

}
