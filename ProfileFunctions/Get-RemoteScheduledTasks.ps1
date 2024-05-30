# Function to export a list of scheduled tasks from a remote computer and their properties
# Function will be called Get-RemoteScheduledTasks
# Function will have a single parameter called ComputerName

function Get-RemoteScheduledTasks {
    [CmdletBinding( DefaultParameterSetName = 'ComputerName', SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    Param(
        [Parameter( Mandatory = $true, Position = 0, ParameterSetName = 'ComputerName' )]
        [string]$ComputerName
    )
    Process {
        if ($PSCmdlet.ShouldProcess("Target", "Operation")) {
            foreach ($Computer in $ComputerName) {
                $ScheduledTasks = Get-ScheduledTask -CimSession $Computer -TaskName *
                foreach ($ScheduledTask in $ScheduledTasks) {
                    $ScheduledTaskInfo = Get-ScheduledTaskInfo -CimSession $Computer -TaskName $ScheduledTask.TaskName
                    $ScheduledTaskInfo | Select-Object -Property TaskName, LastRunTime, LastTaskResult, NextRunTime, NumberOfMissedRuns, TaskPath, TaskState, PSComputerName
                }
            }
        }
    }
}
