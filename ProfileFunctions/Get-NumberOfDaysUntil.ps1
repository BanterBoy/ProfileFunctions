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
