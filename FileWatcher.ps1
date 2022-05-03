# -------File Watcher-------
### SET FOLDER TO WATCH + FILES TO WATCH + SUBFOLDERS YES/NO
$filewatcher = New-Object System.IO.FileSystemWatcher
#Mention the folder to monitor
$filewatcher.Path = "C:\D_EMS Drive\Personal\LBLOG\"
$filewatcher.Filter = "*.*"
#include subdirectories $true/$false
$filewatcher.IncludeSubdirectories = $true
$filewatcher.EnableRaisingEvents = $true  
### DEFINE ACTIONS AFTER AN EVENT IS DETECTED
$writeaction = { $path = $Event.SourceEventArgs.FullPath
    $changeType = $Event.SourceEventArgs.ChangeType
    $logline = "$(Get-Date), $changeType, $path"
    Add-Content "C:\D_EMS Drive\Personal\LBLOG\FileWatcher_log.txt" -value $logline
}    
### DECIDE WHICH EVENTS SHOULD BE WATCHED 
#The Register-ObjectEvent cmdlet subscribes to events that are generated by .NET objects on the local computer or on a remote computer.
#When the subscribed event is raised, it is added to the event queue in your session. To get events in the event queue, use the Get-Event cmdlet.
Register-ObjectEvent $filewatcher "Created" -Action $writeaction
Register-ObjectEvent $filewatcher "Changed" -Action $writeaction
Register-ObjectEvent $filewatcher "Deleted" -Action $writeaction
Register-ObjectEvent $filewatcher "Renamed" -Action $writeaction
while ($true) { Start-Sleep 5 }