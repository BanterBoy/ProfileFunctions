#requires -RunAsAdministrator

function ScheduledTask-Create-FuckWithPsGalleryStats {
    $action = New-ScheduledTaskAction `
        -Execute 'powershell.exe' `
        -Argument '-ExecutionPolicy Bypass -File "C:\Users\Rob\OneDrive\Documents\PowerShell\Scripts\Fuck-WithPsGalleryStats.ps1"'

    $trigger = New-ScheduledTaskTrigger -Daily -At 1am

    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable

    Register-ScheduledTask `
        -TaskName "Fuck With Ps Gallery Stats" `
        -Action $action `
        -Trigger $trigger `
        -Settings $settings `
        -Description "Creates a docker container running Powershell and installs modules to up the install count in PSGallery"
}

function ScheduledTask-Delete-FuckWithPsGalleryStats {
    Unregister-ScheduledTask -TaskName "Fuck With Ps Gallery Stats" -Confirm:$false
}
