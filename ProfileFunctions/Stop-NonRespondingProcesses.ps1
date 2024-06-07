function Stop-NonRespondingProcesses {
    $timeout = 3
    # use a hash table to keep track of processes
    $hash = @{ }
    # use an endless loop and test processes
    do {
        Get-Process |
        # look at processes with a window only
        Where-Object MainWindowTitle |
        ForEach-Object {
            # use process ID as key to the hash table
            $key = $_.id
            # if the process is responding, reset the counter
            if ($_.Responding) {
                $hash[$key] = 0
            }
            # else, increment the counter by one
            else {
                $hash[$key]++
            }
        }
        # copy the hash table keys so that the collection can be 
        # modified
        $keys = @($hash.Keys).Clone()
   
        # emit all processes hanging for longer than $timeout seconds
        # look at all processes monitored
        $keys |
        # take the ones not responding for the time specified in $timeout
        Where-Object { $hash[$_] -gt $timeout } |
        ForEach-Object {
            # reset the counter (in case you choose not to kill them)
            $hash[$_] = 0
            # emit the process for the process ID on record
            Get-Process -id $_
        } | 
        # exclude those that already exited
        Where-Object { $_.HasExited -eq $false } |
        # show properties
        Select-Object -Property Id, Name, StartTime, HasExited |
        # show hanging processes. The process(es) selected by the user will be killed
        Out-GridView -Title "Select apps to kill that are hanging for more than $timeout seconds" -PassThru |
        # kill selected processes
        Stop-Process -Force
    
        # sleep for a second
        Start-Sleep -Seconds 1
    
    } while ($true) 

}