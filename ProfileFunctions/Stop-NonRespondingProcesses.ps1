<#
.SYNOPSIS
This function monitors a specific running process (or all processes if no process name is provided) and offers the user an option to forcibly stop any that have been unresponsive for more than a specified amount of time.

.DESCRIPTION
The function continuously checks the status of the specified process (or all processes if no process name is provided). If it's not responding, it increments its counter in a hash table. If the process has been unresponsive for longer than the timeout value, the function displays the process in a grid view and offers the user an option to stop it.

.PARAMETER Timeout
The amount of time (in seconds) a process can be unresponsive before the function offers the user an option to stop it. Default is 3 seconds.

.PARAMETER AutoStop
If this switch is provided, the function will automatically stop the non-responding process (or processes) without prompting the user.

.PARAMETER ProcessName
The name of the process to monitor. If not provided, the function will monitor all processes.

.EXAMPLE
Stop-NonRespondingProcesses -Timeout 5 -ProcessName "notepad"
#>

function Stop-NonRespondingProcesses {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [int]$Timeout = 3,
        [Parameter(Mandatory = $false)]
        [switch]$AutoStop,
        [Parameter(Mandatory = $false)]
        [string]$ProcessName
    )

    $ProcessCounters = @{ }

    do {
        if ($ProcessName) {
            $Processes = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue
        }
        else {
            $Processes = Get-Process
        }

        $totalProcesses = $Processes.Count
        $currentProcess = 0

        $Processes | ForEach-Object {
            $ProcessId = $_.id
            Write-Verbose "Checking process $currentProcess of $totalProcesses (ID: $ProcessId, Name: $($_.Name))"
            if ($_.Responding) {
                $ProcessCounters[$ProcessId] = 0
            }
            else {
                $ProcessCounters[$ProcessId]++
            }

            $currentProcess++
        }

        $ProcessIds = @($ProcessCounters.Keys).Clone()

        $NonRespondingProcesses = $ProcessIds | Where-Object { $ProcessCounters[$_] -gt $Timeout } | ForEach-Object {
            $ProcessCounters[$_] = 0
            Get-Process -id $_
        } | Where-Object { $_.HasExited -eq $false }

        if ($AutoStop) {
            $NonRespondingProcesses | Stop-Process -Force -ErrorAction SilentlyContinue
        }
        else {
            $NonRespondingProcesses | Select-Object -Property Id, Name, StartTime, HasExited |
            Out-GridView -Title "Select apps to kill that are hanging for more than $Timeout seconds" -PassThru |
            ForEach-Object {
                try {
                    $_ | Stop-Process -Force
                }
                catch {
                    Write-Error "Failed to stop process $($_.Id): $_"
                }
            }
        }

        Start-Sleep -Seconds 1

    } while ($true) 
}
