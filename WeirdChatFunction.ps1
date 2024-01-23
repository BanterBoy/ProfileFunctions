Function New-ToastMessage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text,
        [Parameter(Mandatory = $true)]
        [ValidateRange(1, [int]::MaxValue)]
        [int]$ShutdownInMinutes,
        [string]$IconPath
    )

    try {
        Import-Module -Name BurntToast -ErrorAction Stop

        $Button1 = New-BTButton -Content 'Shutdown Now' -Arguments 'shutdown /s /t 0'
        $Button2 = New-BTButton -Content 'Postpone Shutdown' -Arguments 'shutdown /a'

        $Action1 = New-BTAction -Buttons $Button1
        $Action2 = New-BTAction -Buttons $Button2

        $Notification = @{
            Text    = $Text
            Actions = $Action1, $Action2
            AppLogo = $IconPath
        }

        New-BurntToastNotification @Notification
    }
    catch {
        Write-Error "Failed to create toast notification: $_"
    }
}

Function New-ScheduledShutdown {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateRange(1, [int]::MaxValue)]
        [int]$ShutdownInHours,
        [Parameter(Mandatory = $true)]
        [ValidateRange(1, [int]::MaxValue)]
        [int]$ReminderIntervalInMinutes
    )

    try {
        $Reminders = $ShutdownInHours * 60 / $ReminderIntervalInMinutes

        for ($i = 0; $i -lt $Reminders; $i++) {
            $Time = (Get-Date).AddMinutes($ReminderIntervalInMinutes * ($i + 1))
            Register-ScheduledJob -Name "Reminder$i" -ScriptBlock {
                New-ToastMessage -Text "Shutdown in $(($Reminders - $i) * $ReminderIntervalInMinutes) minutes" -ShutdownInMinutes $(($Reminders - $i) * $ReminderIntervalInMinutes)
            } -Trigger (New-JobTrigger -Once -At $Time)
        }

        $Time = (Get-Date).AddHours($ShutdownInHours)
        Register-ScheduledJob -Name "Shutdown" -ScriptBlock {
            shutdown /s /t 0
        } -Trigger (New-JobTrigger -Once -At $Time)
    }
    catch {
        Write-Error "Failed to schedule shutdown: $_"
    }
}

Function Stop-ScheduledShutdown {
    try {
        Get-ScheduledJob -Name "Shutdown" | Unregister-ScheduledJob
        Get-ScheduledJob | Where-Object { $_.Name -like "Reminder*" } | Unregister-ScheduledJob
    }
    catch {
        Write-Error "Failed to stop scheduled shutdown: $_"
    }
}

# Test the New-ToastMessage function
# New-ToastMessage -Text "Test message" -ShutdownInMinutes 1

# Test the New-ScheduledShutdown function
# New-ScheduledShutdown -ShutdownInHours 1 -ReminderIntervalInMinutes 30

# Test the Stop-ScheduledShutdown function
# Stop-ScheduledShutdown
