function Stop-NonRespondingProcesses {
    param(
        [int]$timeout = 3,
        [switch]$continuous
    )

    # use a hash table to keep track of processes
    $hash = @{ }

    do {
        Get-Process |
        Where-Object MainWindowTitle |
        ForEach-Object {
            $key = $_.id
            if ($_.Responding) {
                $hash[$key] = 0
            }
            else {
                $hash[$key]++
            }
        }

        $keys = @($hash.Keys).Clone()

        $keys |
        Where-Object { $hash[$_] -gt $timeout } |
        ForEach-Object {
            $hash[$_] = 0
            Get-Process -id $_
        } | 
        Where-Object { $_.HasExited -eq $false } |
        Select-Object -Property Id, Name, StartTime, HasExited |
        Out-GridView -Title "Select apps to kill that are hanging for more than $timeout seconds" -PassThru |
        ForEach-Object {
            try {
                $_ | Stop-Process -Force
                Write-Host "Stopped process $($_.Id) - $($_.Name)"
            }
            catch {
                Write-Error "Failed to stop process $($_.Id) - $($_.Name)"
            }
        }

        if (-not $continuous) {
            break
        }

        Start-Sleep -Seconds 1

    } while ($true) 
}