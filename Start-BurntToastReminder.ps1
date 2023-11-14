Function Start-PomodoroTimer {
    Param(
        [int]$Minutes = "25"
    )
    $seconds = (60 * $($Minutes))
    $sb = {
        Start-Sleep -Seconds $using:seconds
        New-BurntToastNotification -Text 'Timer complete. Take a break and get back to it' -SnoozeandDismiss -Sound SMS
    }
    Start-Job -Name 'Pomodoro Timer' -ScriptBlock $sb -Argumentlist $seconds
}